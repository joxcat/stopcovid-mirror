package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

import javax.inject.Inject;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.EphemeralTupleRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.EphemeralTupleResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.MacEsrValidationRequest;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.ApplicationConfigurationModel;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IApplicationConfigService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.controller.IStatusController;
import fr.gouv.stopc.robertserver.ws.dto.AlgoConfigDto;
import fr.gouv.stopc.robertserver.ws.dto.StatusResponseDto;
import fr.gouv.stopc.robertserver.ws.dto.mapper.EpochKeyBundleDtoMapper;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.service.AuthRequestValidationService;
import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import fr.gouv.stopc.robertserver.ws.vo.StatusVo;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class StatusControllerImpl implements IStatusController {

	private final IServerConfigurationService serverConfigurationService;

	private final IRegistrationService registrationService;

	private final IApplicationConfigService applicationConfigService;

	private final AuthRequestValidationService authRequestValidationService;

	private final ICryptoServerGrpcClient cryptoServerClient;

	private EpochKeyBundleDtoMapper epochKeyBundleDtoMapper;
	
	@Inject
	public StatusControllerImpl(
			final IServerConfigurationService serverConfigurationService,
			final IRegistrationService registrationService,
			final IApplicationConfigService applicationConfigService,
			final AuthRequestValidationService authRequestValidationService,
			final EpochKeyBundleDtoMapper epochKeyBundleDtoMapper,
			final ICryptoServerGrpcClient cryptoServerClient
	) {
		this.serverConfigurationService = serverConfigurationService;
		this.registrationService = registrationService;
		this.applicationConfigService = applicationConfigService;
		this.authRequestValidationService = authRequestValidationService;
		this.cryptoServerClient = cryptoServerClient;
		this.epochKeyBundleDtoMapper = epochKeyBundleDtoMapper;
	}

	@Override
	public ResponseEntity<StatusResponseDto> getStatus(StatusVo statusVo) {
	    
		Optional<ResponseEntity> entity = authRequestValidationService.validateRequestForAuth(
				statusVo,
				new StatusMacValidator(this.cryptoServerClient),
				new AuthenticatedRequestHandler());

		if (entity.isPresent()) {
			return entity.get();
		} else {
			return ResponseEntity.badRequest().build();
		}
		 
	}

	private class StatusMacValidator implements AuthRequestValidationService.IMacValidator {

		private final ICryptoServerGrpcClient cryptoServerClient;

		public StatusMacValidator(ICryptoServerGrpcClient cryptoServerClient) {
			this.cryptoServerClient = cryptoServerClient;
		}

		@Override
		public boolean validate(byte[] key, byte[] toCheck, byte[] mac) {
			boolean res;

			try {
				MacEsrValidationRequest request = MacEsrValidationRequest.newBuilder()
						.setKa(ByteString.copyFrom(key))
						.setDataToValidate(ByteString.copyFrom(toCheck))
						.setMacToMatchWith(ByteString.copyFrom(mac))
						.build();

				res = this.cryptoServerClient.validateMacEsr(request);
			} catch (Exception e) {
				res = false;
			}
			return res;
		}
	}

	private class AuthenticatedRequestHandler implements AuthRequestValidationService.IAuthenticatedRequestHandler {

		@Override
		public Optional<ResponseEntity> validate(Registration record, int epoch) throws RobertServerException {
			if (Objects.isNull(record)) {
				return Optional.empty();
			}

			// Step #6: Check if user was already notified
			// Not applicable anymore (spec update)

			// Step #7: Check that epochs are not too distant
			int currentEpoch = TimeUtils.getCurrentEpochFrom(serverConfigurationService.getServiceTimeStart());
			int epochDistance = currentEpoch - record.getLastStatusRequestEpoch();
			if(epochDistance < serverConfigurationService.getStatusRequestMinimumEpochGap()) {
				log.info("Discarding ESR request because epochs are too close: {} > {} (tolerance)",
						epochDistance,
						serverConfigurationService.getStatusRequestMinimumEpochGap());
				return Optional.of(ResponseEntity.badRequest().build());
			}

			// Request is valid
			// (now iterating through steps from section "If the ESR_REQUEST_A,i is valid, the server:", p11 of spec)
			// Step #1: Set SRE with current epoch number
			int latestNotifEpoch = record.getLastNotificationEpoch();
			setLastEpochReqRegistration(record, epoch);

			// Step #2: "Score" was already processed during batch, simple lookup
			boolean atRisk = record.isAtRisk();

			if (!record.isNotified()) {
				// Step #3: Set UserNotified to true if at risk
				if (atRisk) {
					record.setNotified(true);
					record.setLastNotificationEpoch(currentEpoch);
				}
			} else {
				// Has already been notified he was at risk
				// Reassess new risk since latestEpochOfESR

				// Filter epoch exposition list to match latest ESR epoch
				List<EpochExposition> exposedEpochs = record.getExposedEpochs();
				List<EpochExposition> epochsToKeep = CollectionUtils.isEmpty(exposedEpochs) ?
						new ArrayList<>()
						: exposedEpochs.stream()
						.filter(ep -> ep.getEpochId() > latestNotifEpoch)
						.collect(Collectors.toList());

				// Sum all risk scores for all the remaining epochs
				Double totalRisk = epochsToKeep.stream()
						.map(item -> item.getExpositionScores())
						.map(item -> item.stream().mapToDouble(Double::doubleValue).sum())
						.reduce(0.0, (a,b) -> a + b);

				atRisk = totalRisk > serverConfigurationService.getRiskThreshold();
			}

			// Include new EBIDs and ECCs for next M epochs
			StatusResponseDto statusResponse = StatusResponseDto.builder().atRisk(atRisk).build();
			includeEphemeralTuplesForNextMEpochs(statusResponse, record, 4);

			return Optional.of(ResponseEntity.ok(statusResponse));
		}
	}

	private void includeEphemeralTuplesForNextMEpochs(final StatusResponseDto statusResponse,
													  final Registration user,
													  final int numberOfDays) throws RobertServerException {

		if (statusResponse != null && user != null) {
			List<ApplicationConfigurationModel> serverConf = this.applicationConfigService.findAll();
			if (CollectionUtils.isEmpty(serverConf)) {
				statusResponse.setFilteringAlgoConfig(Collections.emptyList());
			} else {
				statusResponse.setFilteringAlgoConfig(
						serverConf.stream().map(item -> AlgoConfigDto.builder().name(item.getName()).value(item.getValue()).build()).collect(Collectors.toList()));
			}

			final byte countryCode = this.serverConfigurationService.getServerCountryCode();

			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final int numberOfEpochs = 4 * 24 * numberOfDays;

			final int currentEpochId = TimeUtils.getCurrentEpochFrom(tpstStart);

			EphemeralTupleRequest request = EphemeralTupleRequest.newBuilder()
					.setCountryCode(ByteString.copyFrom(new byte[] { countryCode }))
					.setCurrentEpochID(currentEpochId)
					.setIdA(ByteString.copyFrom(user.getPermanentIdentifier()))
					.setNumberOfEpochsToGenerate(numberOfEpochs)
					.build();

			Optional<EphemeralTupleResponse> tupleResponse = this.cryptoServerClient.generateEphemeralTuple(request);

			if(!tupleResponse.isPresent() || CollectionUtils.isEmpty(tupleResponse.get().getTupleList())) {
				log.error("Could not generate (EBID, ECC) tuples");
				throw new RobertServerException(MessageConstants.ERROR_OCCURED);
			}

			statusResponse.setIdsForEpochs(
					epochKeyBundleDtoMapper.convert(tupleResponse.get().getTupleList()));

		}
	}

	private void setLastEpochReqRegistration(Registration user, int epoch) {
		user.setLastStatusRequestEpoch(epoch);
		registrationService.saveRegistration(user);
	}
}
