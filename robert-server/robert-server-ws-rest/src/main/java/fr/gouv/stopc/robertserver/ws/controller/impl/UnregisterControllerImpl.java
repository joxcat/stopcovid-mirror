package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.util.Objects;
import java.util.Optional;

import javax.inject.Inject;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.MacValidationForTypeRequest;
import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.controller.IUnregisterController;
import fr.gouv.stopc.robertserver.ws.dto.UnregisterResponseDto;
import fr.gouv.stopc.robertserver.ws.service.AuthRequestValidationService;
import fr.gouv.stopc.robertserver.ws.vo.UnregisterRequestVo;


@Service
public class UnregisterControllerImpl implements IUnregisterController {

    private final IRegistrationService registrationService;
    private final AuthRequestValidationService authRequestValidationService;
	private final ICryptoServerGrpcClient cryptoServerClient;

    @Inject
    public UnregisterControllerImpl(final ICryptoServerGrpcClient cryptoServerClient,
                                    final IRegistrationService registrationService,
                                    final AuthRequestValidationService authRequestValidationService) {

        this.cryptoServerClient = cryptoServerClient;
        this.registrationService = registrationService;
        this.authRequestValidationService = authRequestValidationService;
    }

    private class UnregisterMacValidator implements AuthRequestValidationService.IMacValidator {

        private final ICryptoServerGrpcClient cryptoServerClient;

        public UnregisterMacValidator(final ICryptoServerGrpcClient cryptoServerClient) {
            this.cryptoServerClient = cryptoServerClient;
        }

        @Override
        public boolean validate(byte[] key, byte[] toCheck, byte[] mac) {
            boolean res;
            try {
            	MacValidationForTypeRequest request = MacValidationForTypeRequest.newBuilder()
        				.setKa(ByteString.copyFrom(key))
        				.setDataToValidate(ByteString.copyFrom(toCheck))
        				.setMacToMatchWith(ByteString.copyFrom(mac))
        				.setPrefixe(ByteString.copyFrom(new byte[] { DigestSaltEnum.UNREGISTER.getValue() }))
        				.build();
                res = this.cryptoServerClient.validateMacForType(request);
            } catch (Exception e) {
                res = false;
            }
            return res;
        }
    }

    private class UnregisterAuthenticatedRequestHandler implements AuthRequestValidationService.IAuthenticatedRequestHandler {

        @Override
        public Optional<ResponseEntity> validate(Registration record, int epoch) {
            if (Objects.isNull(record)) {
                return Optional.of(ResponseEntity.notFound().build());
            }

            // Unregister by deleting
            registrationService.delete(record);

            UnregisterResponseDto statusResponse = UnregisterResponseDto.builder().success(true).build();

            return Optional.of(ResponseEntity.ok(statusResponse));
        }
    }

    @Override
    public ResponseEntity<UnregisterResponseDto> unregister(UnregisterRequestVo unregisterRequestVo) {
        Optional<ResponseEntity> entity = authRequestValidationService.validateRequestForAuth(unregisterRequestVo,
                new UnregisterMacValidator(this.cryptoServerClient),
                new UnregisterAuthenticatedRequestHandler());

        if (entity.isPresent()) {
            return entity.get();
        } else {
            return ResponseEntity.badRequest().build();
        }
    }
}
