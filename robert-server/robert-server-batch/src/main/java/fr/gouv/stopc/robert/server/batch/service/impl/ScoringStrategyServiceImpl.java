package fr.gouv.stopc.robert.server.batch.service.impl;

import fr.gouv.stopc.robert.server.batch.exception.RobertScoringException;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.HelloMessageDetail;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.inject.Inject;
import java.util.List;


/**
 * Scoring strategy that implements the WP4 formula
 * risk = - SUM_i=1_to_I((5*delta_t(i, i - 1))/min((RSSI(i) + RSSI(i - 1)) / 2 + alpha, -5) * 60
 * where alpha = - RSSI_1m - 5
 * For contacts with a single message, cap estimated delta to 120 seconds
 */
@Service
@Slf4j
public class ScoringStrategyServiceImpl implements ScoringStrategyService {
    // Issue #TODO: update based on calibration tests.
    // This value must come from tests on a maximum number of devices, measuring the RSSI (in dB) at one meter
    private final static int RSSI_1M = -60;
    private final static int ALPHA = -RSSI_1M - 5;

    private final IServerConfigurationService serverConfigurationService;

    @Inject
    public ScoringStrategyServiceImpl(IServerConfigurationService serverConfigurationService) {
        this.serverConfigurationService = serverConfigurationService;
    }

    @Override
    public Double execute(Contact contact) throws RobertScoringException {
        List<HelloMessageDetail> messageDetails = contact.getMessageDetails();

        double acc = 0.0;
        int vectorSize = messageDetails.size();

        if (vectorSize > 1) {
            for (int i = 1; i < vectorSize; i++) {
                HelloMessageDetail messageDetail = messageDetails.get(i - 1);
                HelloMessageDetail nextMessage = messageDetails.get(i);
                long delta = nextMessage.getTimeCollectedOnDevice() - messageDetail.getTimeCollectedOnDevice();
                int averageRSSI = (messageDetail.getRssiCalibrated() + nextMessage.getRssiCalibrated()) / 2;
                acc += (double) (delta * 5) / (Math.min(averageRSSI + ALPHA, -5) * 60);
            }
        } else if (vectorSize == 1) {
            HelloMessageDetail message = messageDetails.get(0);
            long epochDuration = this.serverConfigurationService.getEpochDurationSecs();
            long remainder = (message.getTimeCollectedOnDevice() - this.serverConfigurationService.getServiceTimeStart()) % epochDuration;
            long delta = remainder > epochDuration / 2 ? epochDuration - remainder : remainder;

            // Cap delta to 120 seconds max
            long cappedDelta = delta > 120 ? 120 : delta;
            acc += (double) (cappedDelta * 5) / (Math.min(message.getRssiCalibrated() + ALPHA, -5) * 60);
        } else {
            String errorMessage = "Cannot score contact with no HELLO messages";
            log.error(errorMessage);
            throw new RobertScoringException(errorMessage);
        }

        return 0 - acc;
    }
}
