package fr.gouv.stopc.robertserver.ws.service.impl;

import java.util.Date;
import java.util.Objects;
import java.util.Optional;

import javax.inject.Inject;

import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import org.bson.internal.Base64;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.*;
import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.ws.service.AuthRequestValidationService;
import fr.gouv.stopc.robertserver.ws.vo.AuthRequestVo;
import fr.gouv.stopc.robertserver.ws.vo.StatusVo;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class AuthRequestValidationServiceImpl implements AuthRequestValidationService {

    @Value("${robert.server.request-time-delta-tolerance:60}")
    private Integer timeDeltaTolerance;

    private final IServerConfigurationService serverConfigurationService;

    private final ICryptoServerGrpcClient cryptoServerClient;

    private final IRegistrationService registrationService;

    @Inject
    public AuthRequestValidationServiceImpl(final IServerConfigurationService serverConfigurationService,
                                            final ICryptoServerGrpcClient cryptoServerClient,
                                            final IRegistrationService registrationService) {
        this.serverConfigurationService = serverConfigurationService;
        this.cryptoServerClient = cryptoServerClient;
        this.registrationService = registrationService;
    }

    private ResponseEntity createErrorValidationFailed() {
        log.info("Discarding authenticated request because validation failed");
        return ResponseEntity.badRequest().build();
    }

    private ResponseEntity createErrorTechnicalIssue() {
        log.info("Technical issue managing authenticated request");
        return ResponseEntity.badRequest().build();
    }

    private Optional<ResponseEntity> createErrorBadRequestCustom(String customErrorMessage) {
        log.info(customErrorMessage);
        return Optional.of(ResponseEntity.badRequest().build());
    }

    private Optional<ResponseEntity> validateCommonAuth(AuthRequestVo authRequestVo) {
        // Step #1: Parameter check
        if (Objects.isNull(authRequestVo)) {
            return createErrorBadRequestCustom("Discarding authenticated request because of empty request body");
        }

        byte[] ebid = Base64.decode(authRequestVo.getEbid());
        if (ByteUtils.isEmpty(ebid) || ebid.length != 8) {
            return createErrorBadRequestCustom("Discarding authenticated request because of invalid EBID field size");
        }

        byte[] time = Base64.decode(authRequestVo.getTime());
        if (ByteUtils.isEmpty(time) || time.length != 4) {
            return createErrorBadRequestCustom("Discarding authenticated request because of invalid Time field size");
        }

        byte[] mac = Base64.decode(authRequestVo.getMac());
        if (ByteUtils.isEmpty(mac) || mac.length != 32) {
            return createErrorBadRequestCustom("Discarding authenticated request because of invalid MAC field size");
        }

        // Moved timestamp difference check to after request sent to cryptoserver to be able to store drift in db

        return Optional.empty();
    }

    @Override
    public ValidationResult<GetIdFromAuthResponse> validateRequestForAuth(AuthRequestVo authRequestVo, DigestSaltEnum requestType) {
        Optional<ResponseEntity> validationError = validateCommonAuth(authRequestVo);

        if (validationError.isPresent()) {
            return ValidationResult.<GetIdFromAuthResponse>builder().error(validationError.get()).build();
        }

        try {
            GetIdFromAuthRequest request = GetIdFromAuthRequest.newBuilder()
                        .setEbid(ByteString.copyFrom(Base64.decode(authRequestVo.getEbid())))
                        .setEpochId(authRequestVo.getEpochId())
                        .setTime(Integer.toUnsignedLong(ByteUtils.bytesToInt(Base64.decode(authRequestVo.getTime()))))
                        .setMac(ByteString.copyFrom(Base64.decode(authRequestVo.getMac())))
                        .setRequestType(requestType.getValue())
                    .build();

            Optional<GetIdFromAuthResponse> response = this.cryptoServerClient.getIdFromAuth(request);

            if (response.isPresent()) {
                if (Objects.nonNull(response.get().getIdA())) {
                    Optional<ValidationResult> timeValidationResult = this.checkTime(
                            Base64.decode(authRequestVo.getTime()),
                            response.get().getIdA().toByteArray());
                    if (timeValidationResult.isPresent()) {
                        return timeValidationResult.get();
                    }
                }
                return ValidationResult.<GetIdFromAuthResponse>builder().response(response.get()).build();
            } else {
                return ValidationResult.<GetIdFromAuthResponse>builder().error(createErrorValidationFailed()).build();
            }
        } catch (Exception e1) {
            return ValidationResult.<GetIdFromAuthResponse>builder().error(createErrorTechnicalIssue()).build();
        }
    }

    @Override
    public ValidationResult<DeleteIdResponse> validateRequestForUnregister(AuthRequestVo authRequestVo) {
        Optional<ResponseEntity> validationError = validateCommonAuth(authRequestVo);

        if (validationError.isPresent()) {
            return ValidationResult.<DeleteIdResponse>builder().error(validationError.get()).build();
        }

        try {
            DeleteIdRequest request = DeleteIdRequest.newBuilder()
                    .setEbid(ByteString.copyFrom(Base64.decode(authRequestVo.getEbid())))
                    .setEpochId(authRequestVo.getEpochId())
                    .setTime(Integer.toUnsignedLong(ByteUtils.bytesToInt(Base64.decode(authRequestVo.getTime()))))
                    .setMac(ByteString.copyFrom(Base64.decode(authRequestVo.getMac())))
                    .build();

            Optional<DeleteIdResponse> response = this.cryptoServerClient.deleteId(request);

            if (response.isPresent()) {
                if (Objects.nonNull(response.get().getIdA())) {
                    Optional<ValidationResult> timeValidationResult = this.checkTime(
                            Base64.decode(authRequestVo.getTime()),
                            response.get().getIdA().toByteArray());
                    if (timeValidationResult.isPresent()) {
                        return timeValidationResult.get();
                    }
                }
                return ValidationResult.<DeleteIdResponse>builder().response(response.get()).build();
            } else {
                return ValidationResult.<DeleteIdResponse>builder().error(createErrorValidationFailed()).build();
            }
        } catch (Exception e1) {
            return ValidationResult.<DeleteIdResponse>builder().error(createErrorTechnicalIssue()).build();
        }
    }

    @Override
    public ValidationResult<GetIdFromStatusResponse> validateStatusRequest(StatusVo statusVo) {
        Optional<ResponseEntity> validationError = validateCommonAuth(statusVo);

        if (validationError.isPresent()) {
            return ValidationResult.<GetIdFromStatusResponse>builder().error(validationError.get()).build();
        }

        try {
            GetIdFromStatusRequest request = GetIdFromStatusRequest.newBuilder()
                        .setEbid(ByteString.copyFrom(Base64.decode(statusVo.getEbid())))
                        .setEpochId(statusVo.getEpochId())
                        .setTime(Integer.toUnsignedLong(ByteUtils.bytesToInt(Base64.decode(statusVo.getTime()))))
                        .setMac(ByteString.copyFrom(Base64.decode(statusVo.getMac())))
                        .setFromEpochId(TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart()))
                        .setNumberOfDaysForEpochBundles(this.serverConfigurationService.getEpochBundleDurationInDays())
                        .setServerCountryCode(ByteString.copyFrom(new byte[] { this.serverConfigurationService.getServerCountryCode() }))
                    .build();

            Optional<GetIdFromStatusResponse> response = this.cryptoServerClient.getIdFromStatus(request);

            if (response.isPresent()) {
                if (Objects.nonNull(response.get().getIdA())) {
                    Optional<ValidationResult> timeValidationResult = this.checkTime(
                            Base64.decode(statusVo.getTime()),
                            response.get().getIdA().toByteArray());
                    if (timeValidationResult.isPresent()) {
                        return timeValidationResult.get();
                    }
                }
                return ValidationResult.<GetIdFromStatusResponse>builder().response(response.get()).build();
            } else {
                return ValidationResult.<GetIdFromStatusResponse>builder().error(createErrorValidationFailed()).build();
            }
        } catch (Exception e1) {
            return ValidationResult.<GetIdFromStatusResponse>builder().error(createErrorTechnicalIssue()).build();
        }
    }

    private long convertTimeByteArrayToLong(byte[] timeA) {
        byte[] timeAIn64bits = ByteUtils.addAll(new byte[] { 0, 0, 0, 0 }, timeA);
        return ByteUtils.bytesToLong(timeAIn64bits);
    }

    private Optional<ValidationResult> checkTime(byte[] time, byte[] idA) {
        final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());
        final long timeA = convertTimeByteArrayToLong(time);
        final long delta = currentTime - timeA;

        // Store drift (timestamp delta) if we have the user id
        if (Objects.nonNull(idA)) {
            Optional<Registration> registration = this.registrationService.findById(idA);
            if (registration.isPresent()) {
                registration.get().setLastTimestampDrift(delta);
                this.registrationService.saveRegistration(registration.get());
            }
        }

        // Step #2: check if time is close to current time
        if (Math.abs(delta) > this.timeDeltaTolerance) {
            log.warn("Witnessing abnormal time difference {} between client: {} and server: {}",
                    delta,
                    timeA,
                    currentTime);
            return Optional.of(ValidationResult.<GetIdFromAuthResponse>builder()
                    .error(createErrorBadRequestCustom(
                            "Discarding authenticated request because provided time is too far from current server time")
                            .get())
                    .build());
        }
        return Optional.empty();
    }

}
