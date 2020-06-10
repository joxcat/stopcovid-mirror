package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.util.*;
import java.util.stream.Collectors;

import javax.inject.Inject;

import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromStatusResponse;
import fr.gouv.stopc.robertserver.database.model.ApplicationConfigurationModel;
import fr.gouv.stopc.robertserver.ws.dto.ClientConfigDto;
import org.bson.internal.Base64;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IApplicationConfigService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.controller.IStatusController;
import fr.gouv.stopc.robertserver.ws.dto.StatusResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.service.AuthRequestValidationService;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.StatusVo;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class StatusControllerImpl implements IStatusController {

	private final IServerConfigurationService serverConfigurationService;

	private final IRegistrationService registrationService;

	private final IApplicationConfigService applicationConfigService;

	private final AuthRequestValidationService authRequestValidationService;

	private final PropertyLoader propertyLoader;

	@Inject
	public StatusControllerImpl(
			final IServerConfigurationService serverConfigurationService,
			final IRegistrationService registrationService,
			final IApplicationConfigService applicationConfigService,
			final AuthRequestValidationService authRequestValidationService,
			final PropertyLoader propertyLoader) {
		this.serverConfigurationService = serverConfigurationService;
		this.registrationService = registrationService;
		this.applicationConfigService = applicationConfigService;
		this.authRequestValidationService = authRequestValidationService;
		this.propertyLoader = propertyLoader;
	}

	@Override
	public ResponseEntity<StatusResponseDto> getStatus(StatusVo statusVo) {
		log.info("Receiving status request");

		AuthRequestValidationService.ValidationResult<GetIdFromStatusResponse> validationResult =
				this.authRequestValidationService.validateStatusRequest(statusVo);

		if (Objects.nonNull(validationResult.getError())) {
			log.info("Status request authentication failed");
			return ResponseEntity.badRequest().build();
		}
		log.info("Status request authentication passed");

		GetIdFromStatusResponse response = validationResult.getResponse();

		log.info("Finding record for status request");
		Optional<Registration> record = this.registrationService.findById(response.getIdA().toByteArray());
		if (record.isPresent()) {
			try {
				Optional<ResponseEntity> responseEntity = validate(record.get(), response.getEpochId(), response.getTuples().toByteArray());

				if (responseEntity.isPresent()) {
					log.info("Status request successful");
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

	/**
	 * Sort list of epochs and get last
	 * @param exposedEpochs
	 * @return
	 */
	private int findLastExposedEpoch(List<EpochExposition> exposedEpochs) {
		if (CollectionUtils.isEmpty(exposedEpochs)) {
			return 0;
		}

		List<EpochExposition> sortedEpochs = exposedEpochs.stream()
				.sorted((a, b) -> new Integer(a.getEpochId()).compareTo(b.getEpochId()))
				.collect(Collectors.toList());
		return sortedEpochs.get(sortedEpochs.size() - 1).getEpochId();
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
		if(epochDistance < this.propertyLoader.getStatusRequestMinimumEpochGap() 
		        && this.propertyLoader.getEsrLimit() != 0) {
			log.info("Discarding ESR request because epochs are too close: {} > {} (tolerance)",
					epochDistance,
					this.propertyLoader.getStatusRequestMinimumEpochGap());
			return Optional.of(ResponseEntity.badRequest().build());
		}

		// Request is valid
		// (now iterating through steps from section "If the ESR_REQUEST_A,i is valid, the server:", p11 of spec)
		// Step #1: Set SRE with current epoch number
		record.setLastStatusRequestEpoch(epoch);

		// Step #2: Risk and score were processed during batch, simple lookup
		boolean atRisk = record.isAtRisk();
		boolean newRiskDetected = false;

		if (!record.isNotified()) {
			// Step #3: Set UserNotified to true if at risk
			// If was never notified and batch flagged a risk, notify
			// and remember last exposed epoch as new starting point for subsequent risk notifications
			if (atRisk) {
				newRiskDetected = true;
				record.setAtRisk(false);
				record.setNotified(true);
				int lastExposedEpoch = findLastExposedEpoch(record.getExposedEpochs());
				record.setLatestRiskEpoch(lastExposedEpoch);
			}
		} else {
			// Has already been notified he was at risk

			// Batch marked a new risk since latestRiskEpoch
			// Update latestRiskEpoch to latest exposed epoch
			if (atRisk) {
				newRiskDetected = true;
				record.setAtRisk(false);
				int lastExposedEpoch = findLastExposedEpoch(record.getExposedEpochs());
				record.setLatestRiskEpoch(lastExposedEpoch);
			}
		}

		// Include new EBIDs and ECCs for next M epochs
		StatusResponseDto statusResponse = StatusResponseDto.builder()
				.atRisk(newRiskDetected)
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

	// TODO: delete commented code
//	private void includeEphemeralTuplesForNextMEpochs(final StatusResponseDto statusResponse,
//													  final Registration user,
//													  final int numberOfDays) throws RobertServerException {
//
//		if (statusResponse != null && user != null) {
//			List<ApplicationConfigurationModel> serverConf = this.applicationConfigService.findAll();
//			if (CollectionUtils.isEmpty(serverConf)) {
//				statusResponse.setConfig(Collections.emptyList());
//			} else {
//				statusResponse.setConfig(
//						serverConf.stream().map(item -> ClientConfigDto.builder().name(item.getName()).value(item.getValue()).build()).collect(Collectors.toList()));
//			}
//
//			final byte countryCode = this.serverConfigurationService.getServerCountryCode();
//
//			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
//			final int numberOfEpochs = 4 * 24 * numberOfDays;
//
//			final int currentEpochId = TimeUtils.getCurrentEpochFrom(tpstStart);
//
//
//			EncryptedEphemeralTupleBundleRequest request = EncryptedEphemeralTupleBundleRequest.newBuilder()
//					.setCountryCode(ByteString.copyFrom(new byte[] { countryCode }))
//					.setFromEpoch(currentEpochId)
//					.setIdA(ByteString.copyFrom(user.getPermanentIdentifier()))
//					.setNumberOfEpochsToGenerate(numberOfEpochs)
//					.build();
//
//			Optional<EncryptedEphemeralTupleBundleResponse> encryptedTuples = this.cryptoServerClient.generateEncryptedEphemeralTuple(request);
//
//			if(!encryptedTuples.isPresent()) {
//				log.error("Could not generate encrypted (EBID, ECC) tuples");
//				throw new RobertServerException(MessageConstants.ERROR_OCCURED);
//			}
//
//			statusResponse.setTuples(Base64.encode(encryptedTuples.get().getEncryptedTuples().toByteArray()));
//		}
//	}
}
