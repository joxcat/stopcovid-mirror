package fr.gouv.stopc.robertserver.ws.service.impl;

import java.nio.ByteBuffer;
import java.util.Date;
import java.util.Objects;
import java.util.Optional;

import javax.inject.Inject;

import org.bson.internal.Base64;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.request.DecryptEBIDRequest;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.impl.RegistrationService;
import fr.gouv.stopc.robertserver.ws.service.AuthRequestValidationService;
import fr.gouv.stopc.robertserver.ws.vo.AuthRequestVo;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class AuthRequestValidationServiceImpl implements AuthRequestValidationService {

    private final IServerConfigurationService serverConfigurationService;

    private final RegistrationService registrationService;

    private final ICryptoServerGrpcClient cryptoServerClient;


    @Inject
    public AuthRequestValidationServiceImpl(
                                            final IServerConfigurationService serverConfigurationService,
                                            final RegistrationService registrationService,
                                            final ICryptoServerGrpcClient cryptoServerClient) {
        this.serverConfigurationService = serverConfigurationService;
        this.registrationService = registrationService;
        this.cryptoServerClient = cryptoServerClient;
    }

    @Override
    public Optional<ResponseEntity> validateRequestForAuth(AuthRequestVo authRequestVo, IMacValidator macValidator, IAuthenticatedRequestHandler otherValidator) {
        // Step #1: Parameter check
        if (Objects.isNull(authRequestVo)) {
            log.info("Discarding authenticated request because of empty request body");
            return Optional.of(ResponseEntity.badRequest().build());
        }

        byte[] ebid = Base64.decode(authRequestVo.getEbid());
        if (ByteUtils.isEmpty(ebid) || ebid.length != 8) {
            log.info("Discarding authenticated request because of invalid EBID field size");
            return Optional.of(ResponseEntity.badRequest().build());
        }

        byte[] time = Base64.decode(authRequestVo.getTime());
        if (ByteUtils.isEmpty(time) || time.length != 4) {
            log.info("Discarding authenticated request because of invalid Time field size");
            return Optional.of(ResponseEntity.badRequest().build());
        }

        byte[] mac = Base64.decode(authRequestVo.getMac());
        if (ByteUtils.isEmpty(mac) || mac.length != 32) {
            log.info("Discarding authenticated request because of invalid MAC field size");
            return Optional.of(ResponseEntity.badRequest().build());
        }

        final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());

        // Step #2: check if time is close to current time
        if (!checkTime(time, currentTime)) {
            log.info("Discarding authenticated request because provided time is too far from current server time");
            return Optional.of(ResponseEntity.badRequest().build());
        }

        try {
            // Step #3: retrieve id_A and epoch from EBID
            DecryptEBIDRequest request = DecryptEBIDRequest.newBuilder().setEbid(ByteString.copyFrom(ebid)).build();
            byte[] decrytedEbid = this.cryptoServerClient.decryptEBID(request);

            byte[] epochId = new byte[4];
            byte[] idA = new byte[5];
            System.arraycopy(decrytedEbid, 0, epochId, 1, epochId.length - 1);
            System.arraycopy(decrytedEbid, epochId.length - 1, idA, 0, idA.length);
            ByteBuffer wrapped = ByteBuffer.wrap(epochId);
            int epoch = wrapped.getInt();

            // Step #4: Get record from database
            Optional<Registration> record = this.registrationService.findById(idA);

            if (record.isPresent()) {
                byte[] ka = record.get().getSharedKey();

                // Step #5: Verify MAC
                byte[] toCheck = new byte[12];
                System.arraycopy(ebid, 0, toCheck, 0, 8);
                System.arraycopy(time, 0, toCheck, 8, 4);

                boolean isMacValid = macValidator.validate(ka, toCheck, mac);

                if (!isMacValid) {
                    log.info("Discarding authenticated request because MAC is invalid");
                    return Optional.of(ResponseEntity.badRequest().build());
                }

                Optional<ResponseEntity> response = otherValidator.validate(record.get(), epoch);

                if (response.isPresent()) {
                    return response;
                }

                System.arraycopy(record.get().getSharedKey(), 0, ka, 0, 32);
            } else {
                log.info("Discarding authenticated request because id unknown (fake or was deleted)");
                return Optional.of(ResponseEntity.notFound().build());
            }
        } catch (Exception e1) {
            log.info("Technical issue managing authenticated request");
            return Optional.of(ResponseEntity.badRequest().build());
        }

        return Optional.empty();
    }

    private boolean checkTime(byte[] timeA, long timeCurrent) {
        byte[] timeAIn64bits = ByteUtils.addAll(new byte[] { 0, 0, 0, 0 }, timeA);
        long timeASeconds = ByteUtils.bytesToLong(timeAIn64bits);
        return Math.abs(timeASeconds - timeCurrent) < this.serverConfigurationService.getRequestTimeDeltaTolerance();
    }
}
