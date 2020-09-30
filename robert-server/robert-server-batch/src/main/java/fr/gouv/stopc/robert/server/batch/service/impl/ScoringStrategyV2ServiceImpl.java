package fr.gouv.stopc.robert.server.batch.service.impl;

import java.util.ArrayList;
import java.util.List;

import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.server.batch.configuration.ScoringAlgorithmConfiguration;
import fr.gouv.stopc.robert.server.batch.exception.RobertScoringException;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.batch.model.ScoringResult;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.HelloMessageDetail;
import lombok.extern.slf4j.Slf4j;

/**
 * Scoring strategy that implements the algorithm version 2
 * 
 */
@Slf4j
@Service
@ConditionalOnProperty(name = "robert.scoring.algo-version", havingValue = "2")
public class ScoringStrategyV2ServiceImpl implements ScoringStrategyService {

	private final IServerConfigurationService serverConfigurationService;

	private final ScoringAlgorithmConfiguration configuration;

	private final PropertyLoader propertyLoader;


	/**
	 * Spring injection constructor
	 * 
	 * @param serverConfigurationService the
	 *                                   <code>IServerConfigurationService</code>
	 *                                   bean to inject
	 * @param configuration              the
	 *                                   <code>ScoringAlgorithmConfiguration</code>
	 *                                   bean to inject
	 */
	public ScoringStrategyV2ServiceImpl(IServerConfigurationService serverConfigurationService,
										ScoringAlgorithmConfiguration configuration,
										PropertyLoader propertyLoader) {
		this.serverConfigurationService = serverConfigurationService;
		this.configuration = configuration;
		this.propertyLoader = propertyLoader;
	}

	@Override
	public int getScoringStrategyVersion() {
		return 2;
	}

	@Override
	public int getNbEpochsScoredAtRiskThreshold() {
		return NB_EPOCHS_SCORED_AT_RISK;
	}

	// IF INCREASED TO VALUE > 1, remove the break; in the loop
	// for (EpochExposition epochExposition : scoresSinceLastNotif) {
	public final static int NB_EPOCHS_SCORED_AT_RISK = 1;
	// https://hal.inria.fr/hal-02641630/document (Table 4)

	// Aggregate (formula n56) taken from https://hal.inria.fr/hal-02641630/document
	public double aggregate(List<Double> scores) {
		//double scoreSum = scores.stream().mapToDouble(Double::doubleValue).sum();

		double scoreSum = 0.0;
		// https://hal.inria.fr/hal-02641630/document (56)

		// These are not actual rssi scores, they are rssiScore * duration in order to be formula 57
		for (Double score : scores) {
			scoreSum += score;
		}

		return (1 - Math.exp(-this.propertyLoader.getR0ScoringAlgorithm() * scoreSum));
	}

	/**c
	 * {@inheritDoc}
	 */
	@Override
	public ScoringResult execute(Contact contact) throws RobertScoringException {

		final int epochDurationInMinutes = this.serverConfigurationService.getEpochDurationSecs() / 60;

		// Variables
		final List<Number>[] listRSSI = new ArrayList[epochDurationInMinutes];
		double[] qm = new double[epochDurationInMinutes];
		int[] np = new int[epochDurationInMinutes];
		for (int k = 0; k < epochDurationInMinutes; k++) {
			listRSSI[k] = new ArrayList<>();
		}

		// Verification
		List<HelloMessageDetail> messageDetails = contact.getMessageDetails();
		if (messageDetails.size() == 0) {
			String errorMessage = "Cannot score contact with no HELLO messages";
			log.error(errorMessage);
			throw new RobertScoringException(errorMessage);
		}

		// Phase 1 : fading compensation
		// First index corresponds to the first minute of the first EBID emission
		double t0 = messageDetails.get(0).getTimeCollectedOnDevice();

		int vectorSize = messageDetails.size();

		double tf = messageDetails.get(vectorSize - 1).getTimeCollectedOnDevice();

		/* Over run verification */
		if ( (tf - t0) > (epochDurationInMinutes * 60 + configuration.getEpochTolerance()) )
		{
			String errorMessage = String.format(
					"Skip contact because some hello messages are coming too late: %s sec after first message",
					tf - t0);
			log.error(errorMessage);

			// Initializing values to 0.0 will ignore this problematic contact in the overall summation
			return ScoringResult.builder()
					.rssiScore(0.0)
					.duration(0)
					.nbContacts(0)
					.build();
		}

		for (int k = 0; k < vectorSize; k++) {
			HelloMessageDetail messageDetail = messageDetails.get(k);
			double timestampDelta = messageDetail.getTimeCollectedOnDevice() - t0;
			int index = (int) Math.floor(timestampDelta / 60.0);
			index = index > epochDurationInMinutes ? epochDurationInMinutes - 1 : index;
			if ((index >= 0) && (index < epochDurationInMinutes)) {
				// Drop error Hello messages with too big RSSI (corresponding to errors in iOS
				// and Android)

				if (messageDetail.getRssiCalibrated() <= -5) {
					// Cutting peaks
					int rssi = Math.min(messageDetail.getRssiCalibrated(), configuration.getRssiMax());
					listRSSI[index].add(rssi);
				}
			}
		}

		// Phase 2: Average RSSI
		for (int k = 0; k < epochDurationInMinutes - 1; k++) {
			ArrayList<Number> listRssi2 = new ArrayList<>(listRSSI[k]);
			listRssi2.addAll(listRSSI[k + 1]);
			qm[k] = softMax(listRssi2, configuration.getSoftMaxA());
			np[k] = listRSSI[k].size() + listRSSI[k + 1].size();
		}
		// Only one window for the last sample
		qm[epochDurationInMinutes - 1] = softMax(listRSSI[epochDurationInMinutes - 1], configuration.getSoftMaxA());
		np[epochDurationInMinutes - 1] = listRSSI[epochDurationInMinutes - 1].size();

		// Phase 3: Risk scoring
		// https://hal.inria.fr/hal-02641630/document - eq (52)

		int kmax = 0;
		int nbcontacts = 0;
		List<Number> risk = new ArrayList<>();

		for (int k = 0; k < epochDurationInMinutes; k++) {
			if (np[k] > 0) {
				kmax = k;
				int dd = Math.min(np[k], configuration.getDeltas().length - 1);
				double gamma = (qm[k] - configuration.getP0()) / Double.parseDouble(configuration.getDeltas()[dd]);
				double vrisk = (gamma <= 0.0) ? 0.0 : (gamma >= 1) ? 1.0 : gamma;
				if (vrisk > 0) {
					nbcontacts++;
				}
				risk.add(vrisk);
			}
		}

		return ScoringResult.builder()
				.rssiScore(Math.min(softMax(risk, configuration.getSoftMaxB()) * 1.2, 1.0) * kmax) // multiplying by duration because we do not store it yet in list of exposed epochs
				.duration(kmax)
				.nbContacts(nbcontacts)
				.build();

	}

	/**
	 * 
	 * @param listValues
	 * @param softmaxCoef
	 * @return
	 */
	private Double softMax(List<Number> listValues, double softmaxCoef) {
		int ll = listValues.size();
		double vm = 0.0;

		if (ll > 0) {
			double vlog = 0.0;
			for (int i = 0; i < ll; i++) {
				vlog += Math.exp(listValues.get(i).doubleValue() / softmaxCoef);
			}
			vm = softmaxCoef * Math.log(vlog / ll);
		}
		return vm;
	}
}
