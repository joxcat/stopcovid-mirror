package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

import javax.inject.Inject;

import org.bson.internal.Base64;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromStatusResponse;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.ApplicationConfigurationModel;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IApplicationConfigService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.config.WsServerConfiguration;
import fr.gouv.stopc.robertserver.ws.controller.IStatusController;
import fr.gouv.stopc.robertserver.ws.dto.ClientConfigDto;
import fr.gouv.stopc.robertserver.ws.dto.StatusResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.service.AuthRequestValidationService;
import fr.gouv.stopc.robertserver.ws.service.IRestApiService;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.StatusVo;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class StatusControllerImpl implements IStatusController {

	private final IServerConfigurationService serverConfigurationService;

	private final IRegistrationService registrationService;

	private final IApplicationConfigService applicationConfigService;

	private final AuthRequestValidationService authRequestValidationService;

	private final PropertyLoader propertyLoader;
	
	private final WsServerConfiguration wsServerConfiguration;

	private final IRestApiService restApiService;

	@Inject
	public StatusControllerImpl(
			final IServerConfigurationService serverConfigurationService,
			final IRegistrationService registrationService,
			final IApplicationConfigService applicationConfigService,
			final AuthRequestValidationService authRequestValidationService,
			final PropertyLoader propertyLoader,
			final IRestApiService restApiService,
			final WsServerConfiguration wsServerConfiguration) {
		this.serverConfigurationService = serverConfigurationService;
		this.registrationService = registrationService;
		this.applicationConfigService = applicationConfigService;
		this.authRequestValidationService = authRequestValidationService;
		this.propertyLoader = propertyLoader;
		this.restApiService = restApiService;
		this.wsServerConfiguration = wsServerConfiguration;
	}

	@Override
	public ResponseEntity<StatusResponseDto> getStatus(StatusVo statusVo) {

		AuthRequestValidationService.ValidationResult<GetIdFromStatusResponse> validationResult =
				this.authRequestValidationService.validateStatusRequest(statusVo);

		if (Objects.nonNull(validationResult.getError())) {
			log.info("Status request authentication failed");
			return ResponseEntity.badRequest().build();
		}

		GetIdFromStatusResponse response = validationResult.getResponse();

		if (response.hasError()) {
			// If there is an error but Id is provided, log error in DB
			if (Objects.nonNull(response.getIdA())) {
				Optional<Registration> record = this.registrationService.findById(response.getIdA().toByteArray());
				if (record.isPresent()) {
					int currentEpoch = TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart());
					Registration registration = record.get();
					registration.setLastFailedStatusRequestEpoch(currentEpoch);
					registration.setLastFailedStatusRequestMessage(response.getError().getDescription());
					this.registrationService.saveRegistration(registration);
				}
			}
			return ResponseEntity.badRequest().build();
		}

		Optional<Registration> record = this.registrationService.findById(response.getIdA().toByteArray());
		if (record.isPresent()) {
			try {
				Optional<ResponseEntity> responseEntity = validate(record.get(), response.getEpochId(), response.getTuples().toByteArray());

				if (responseEntity.isPresent()) {

				    Optional.ofNullable(statusVo.getPushInfo())
				    .filter(push -> Objects.nonNull(responseEntity.get().getStatusCode()))
				    .filter(push -> responseEntity.get().getStatusCode().equals(HttpStatus.OK))
				    .ifPresent(this.restApiService::registerPushNotif);

					return responseEntity.get();
				} else {
					log.info("Status request failed validation");
					return ResponseEntity.badRequest().build();
				}
			} catch (RobertServerException e) {
				return ResponseEntity.badRequest().build();
			}
		} else {
			log.info("Discarding status request because id unknown (fake or was deleted)");
			return ResponseEntity.notFound().build();
		}
	}


	public Optional<ResponseEntity> validate(Registration record, int epoch, byte[] tuples) throws RobertServerException {
		if (Objects.isNull(record)) {
			return Optional.empty();
		}

		// Step #6: Check if user was already notified
		// Not applicable anymore (spec update)

		// Step #7: Check that epochs are not too distant
		int currentEpoch = TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart());
		int epochDistance = currentEpoch - record.getLastStatusRequestEpoch();
		if(epochDistance < this.wsServerConfiguration.getStatusRequestMinimumEpochGap() 
		        && this.propertyLoader.getEsrLimit() != 0) {

            String message = "Discarding ESR request because epochs are too close:";
            String errorMessage = String.format("%s"
                    + " last ESR request epoch %d vs current epoch %d => %d < %d (tolerance)",
                    message,
                    record.getLastStatusRequestEpoch(),
                    currentEpoch,
                    epochDistance,
                    this.wsServerConfiguration.getStatusRequestMinimumEpochGap());

			log.info("{} {} < {} (tolerance)",
			        message,
					epochDistance,
					this.wsServerConfiguration.getStatusRequestMinimumEpochGap());

			record.setLastFailedStatusRequestEpoch(currentEpoch);
			record.setLastFailedStatusRequestMessage(errorMessage);
			this.registrationService.saveRegistration(record);
			return Optional.of(ResponseEntity.badRequest().build());
		}

		if (epochDistance < 0) {
		    log.warn("The ESR request epoch difference is negative {}, "
		            + "because the last ESR request epoch is {} and currentEpoch is {} ",
		            epochDistance,
		            record.getLastStatusRequestEpoch(),
		            currentEpoch);
		}
		// Request is valid
		// (now iterating through steps from section "If the ESR_REQUEST_A,i is valid, the server:", p11 of spec)
		// Step #1: Set SRE with current epoch number
		int previousLastStatusRequestEpoch = record.getLastStatusRequestEpoch();
		record.setLastStatusRequestEpoch(currentEpoch);
		log.info("The registration previous last status epoch request was {} and the next epoch, {}, will be the current epoch {}",
		        previousLastStatusRequestEpoch,
		        record.getLastStatusRequestEpoch(),
		        currentEpoch);

		// Step #2: Risk and score were processed during batch, simple lookup
		boolean atRisk = record.isAtRisk();

		// Step #3: Set UserNotified to true if at risk
		// If was never notified and batch flagged a risk, notify
		// and remember last exposed epoch as new starting point for subsequent risk notifications
		if (atRisk) {
			record.setAtRisk(false);
			record.setNotified(true);
		}

		// Include new EBIDs and ECCs for next M epochs
		StatusResponseDto statusResponse = StatusResponseDto.builder()
				.atRisk(atRisk)
				.config(getClientConfig())
				.tuples(Base64.encode(tuples))
				.build();

		// Save changes to the record
		this.registrationService.saveRegistration(record);

		return Optional.of(ResponseEntity.ok(statusResponse));
	}

	private List<ClientConfigDto> getClientConfig() {
		List<ApplicationConfigurationModel> serverConf = this.applicationConfigService.findAll();
		if (CollectionUtils.isEmpty(serverConf)) {
			return Collections.emptyList();
		} else {
			return serverConf
					.stream()
					.map(item -> ClientConfigDto.builder().name(item.getName()).value(item.getValue()).build())
					.collect(Collectors.toList());
		}
	}
}
