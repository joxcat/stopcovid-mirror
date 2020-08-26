package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.util.Objects;
import java.util.Optional;

import javax.inject.Inject;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.crypto.grpc.server.messaging.DeleteIdResponse;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.controller.IUnregisterController;
import fr.gouv.stopc.robertserver.ws.dto.UnregisterResponseDto;
import fr.gouv.stopc.robertserver.ws.service.AuthRequestValidationService;
import fr.gouv.stopc.robertserver.ws.service.IRestApiService;
import fr.gouv.stopc.robertserver.ws.vo.UnregisterRequestVo;
import io.micrometer.core.instrument.util.StringUtils;

@Service
public class UnregisterControllerImpl implements IUnregisterController {

    private final IRegistrationService registrationService;
    private final AuthRequestValidationService authRequestValidationService;
    private final IRestApiService restApiService;

    @Inject
    public UnregisterControllerImpl(final IRegistrationService registrationService,
                                    final AuthRequestValidationService authRequestValidationService,
                                    final IRestApiService restApiService) {

        this.registrationService = registrationService;
        this.authRequestValidationService = authRequestValidationService;
        this.restApiService = restApiService;;
    }

    @Override
    public ResponseEntity<UnregisterResponseDto> unregister(UnregisterRequestVo unregisterRequestVo) {
        AuthRequestValidationService.ValidationResult<DeleteIdResponse> validationResult =
                authRequestValidationService.validateRequestForUnregister(unregisterRequestVo);

        if (Objects.nonNull(validationResult.getError()) || validationResult.getResponse().hasError()) {
            return ResponseEntity.badRequest().build();
        }

        DeleteIdResponse authResponse = validationResult.getResponse();

        Optional<Registration> registrationRecord = this.registrationService.findById(authResponse.getIdA().toByteArray());

        if (registrationRecord.isPresent()) {
            Registration record = registrationRecord.get();

            // Unregister by deleting
            this.registrationService.delete(record);

            UnregisterResponseDto response = UnregisterResponseDto.builder().success(true).build();

            if(StringUtils.isNotBlank(unregisterRequestVo.getPushToken())) {
                this.restApiService.unregisterPushNotif(unregisterRequestVo.getPushToken());
            }

            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
