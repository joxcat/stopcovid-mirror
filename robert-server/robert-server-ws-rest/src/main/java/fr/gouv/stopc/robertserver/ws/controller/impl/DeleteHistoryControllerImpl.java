package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.util.Objects;
import java.util.Optional;

import javax.inject.Inject;

import fr.gouv.stopc.robert.crypto.grpc.server.messaging.DeleteIdResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromAuthResponse;
import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.controller.IDeleteHistoryController;
import fr.gouv.stopc.robertserver.ws.dto.DeleteHistoryResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.service.AuthRequestValidationService;
import fr.gouv.stopc.robertserver.ws.vo.DeleteHistoryRequestVo;
import org.springframework.util.CollectionUtils;

@Slf4j
@Service
public class DeleteHistoryControllerImpl implements IDeleteHistoryController {

	private final IRegistrationService registrationService;
	private final AuthRequestValidationService authRequestValidationService;

	@Inject
	public DeleteHistoryControllerImpl(final IRegistrationService registrationService,
									   final AuthRequestValidationService authRequestValidationService) {
		this.registrationService = registrationService;
		this.authRequestValidationService = authRequestValidationService;
	}

	@Override
	public ResponseEntity<DeleteHistoryResponseDto> deleteHistory(DeleteHistoryRequestVo deleteHistoryRequestVo)
			throws RobertServerException {
		log.info("Receiving delete exposure history request");

		AuthRequestValidationService.ValidationResult<GetIdFromAuthResponse> validationResult =
				this.authRequestValidationService.validateRequestForAuth(deleteHistoryRequestVo, DigestSaltEnum.DELETE_HISTORY);

		if (Objects.nonNull(validationResult.getError()) || validationResult.getResponse().hasError()) {
			log.info("Delete exposure history request authentication failed");
			return ResponseEntity.badRequest().build();
		}
		log.info("Delete exposure history request authentication passed");

		GetIdFromAuthResponse authResponse = validationResult.getResponse();
		Optional<Registration> registrationRecord = this.registrationService.findById(authResponse.getIdA().toByteArray());

		if (registrationRecord.isPresent()) {
			Registration record = registrationRecord.get();

			// Clear ExposedEpoch list then save the updated registration
			if (!CollectionUtils.isEmpty(record.getExposedEpochs())) {
				record.getExposedEpochs().clear();
				registrationService.saveRegistration(record);
			}

			log.info("Delete exposure history request successful");
			return ResponseEntity.ok(DeleteHistoryResponseDto.builder().success(true).build());
		} else {
			log.info("Discarding delete exposure history request because id unknown (fake or was deleted)");
			return ResponseEntity.notFound().build();
		}
	}
}
