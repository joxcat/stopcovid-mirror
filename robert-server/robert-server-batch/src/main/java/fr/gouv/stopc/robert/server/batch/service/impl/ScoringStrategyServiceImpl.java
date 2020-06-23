package fr.gouv.stopc.robert.server.batch.service.impl;

import java.util.List;

import javax.inject.Inject;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.server.batch.exception.RobertScoringException;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.batch.model.ScoringResult;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.HelloMessageDetail;
import lombok.extern.slf4j.Slf4j;

/**
 * Scoring strategy that implements the WP4 formula
 * risk = - SUM_i=1_to_I((5*delta_t(i, i - 1))/min((RSSI(i) + RSSI(i - 1)) / 2 + alpha, -5) * 60
 * where alpha = - RSSI_1m - 5
 * For contacts with a single message, cap estimated delta to 120 seconds
 */
@Service
@Slf4j
@ConditionalOnProperty(name = "robert.scoring.algo-version", havingValue = "0")
public class ScoringStrategyServiceImpl implements ScoringStrategyService {

    private final IServerConfigurationService serverConfigurationService;

    private final PropertyLoader propertyLoader;

    @Inject
    public ScoringStrategyServiceImpl(IServerConfigurationService serverConfigurationService, PropertyLoader propertyLoader) {

        this.serverConfigurationService = serverConfigurationService;
        this.propertyLoader = propertyLoader;
    }

    @Override
    public int getScoringStrategyVersion() {
        return 1;
    }

    @Override
    public double aggregate(List<Double> scores) {
        return scores.stream().mapToDouble(Double::doubleValue).sum();

    }

    @Override
    public int getNbEpochsScoredAtRiskThreshold() {
        return 1;
    }

    @Override
    public ScoringResult execute(Contact contact) throws RobertScoringException {
        List<HelloMessageDetail> messageDetails = contact.getMessageDetails();

        final int alpha = initAlpha();
        double acc = 0.0;
        int vectorSize = messageDetails.size();

        if (vectorSize > 1) {
            for (int i = 1; i < vectorSize; i++) {
                HelloMessageDetail messageDetail = messageDetails.get(i - 1);
                HelloMessageDetail nextMessage = messageDetails.get(i);
                long delta = nextMessage.getTimeCollectedOnDevice() - messageDetail.getTimeCollectedOnDevice();
                int averageRSSI = (messageDetail.getRssiCalibrated() + nextMessage.getRssiCalibrated()) / 2;
                acc += (double) (delta * 5) / (Math.min(averageRSSI + alpha, -5) * 60);
            }
        } else if (vectorSize == 1) {
            HelloMessageDetail message = messageDetails.get(0);
            long epochDuration = this.serverConfigurationService.getEpochDurationSecs();
            long remainder = (message.getTimeCollectedOnDevice() - this.serverConfigurationService.getServiceTimeStart()) % epochDuration;
            long delta = remainder > epochDuration / 2 ? epochDuration - remainder : remainder;

            // Cap delta to 120 seconds max
            long cappedDelta = delta > 120 ? 120 : delta;
            acc += (double) (cappedDelta * 5) / (Math.min(message.getRssiCalibrated() + alpha, -5) * 60);
        } else {
            String errorMessage = "Cannot score contact with no HELLO messages";
            log.error(errorMessage);
            throw new RobertScoringException(errorMessage);
        }

        return ScoringResult.builder().rssiScore(0 - acc).build();
    }

    private int initAlpha() {

        return -this.propertyLoader.getRssiScoringAlgorithm() - 5;
    }

}
