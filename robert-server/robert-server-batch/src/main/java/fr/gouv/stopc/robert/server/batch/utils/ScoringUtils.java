package fr.gouv.stopc.robert.server.batch.utils;

import fr.gouv.stopc.robert.server.batch.model.ScoringResult;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.Registration;
import lombok.extern.slf4j.Slf4j;
import org.springframework.util.CollectionUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
public final class ScoringUtils {

    private ScoringUtils() {
        throw new AssertionError();
    }

    /**
     * Keep epochs within the contagious period
     * @param exposedEpochs
     * @return
     */
    public static List<EpochExposition> getExposedEpochsWithoutEpochsOlderThanContagiousPeriod(
            List<EpochExposition> exposedEpochs,
            int currentEpochId,
            int contagiousPeriod,
            int epochDuration) {

        // Purge exposed epochs list from epochs older than contagious period (C_T)
        return CollectionUtils.isEmpty(exposedEpochs) ?
                new ArrayList<>()
                : exposedEpochs.stream().filter(epoch -> {
            int nbOfEpochsToKeep = (contagiousPeriod * 24 * 3600) / epochDuration;
            return (currentEpochId - epoch.getEpochId()) <= nbOfEpochsToKeep;
        }).collect(Collectors.toList());
    }

    public static void updateRegistrationIfRisk(Registration registration,
                                                List<EpochExposition> epochExpositions,
                                                long timeStart,
                                                double riskThreshold,
                                                ScoringStrategyService scoringStrategy) {

        int latestRiskEpoch = registration.getLatestRiskEpoch();

        // Only consider epochs that are after the last notification for scoring
        List<EpochExposition> scoresSinceLastNotif = CollectionUtils.isEmpty(epochExpositions) ?
                new ArrayList<>()
                : epochExpositions.stream()
                .filter(ep -> ep.getEpochId() > latestRiskEpoch)
                .collect(Collectors.toList());

        // Create a single list with all contact scores from all epochs
        List<Double> allScoresFromAllEpochs = scoresSinceLastNotif.stream()
                .map(EpochExposition::getExpositionScores)
                .map(item -> item.stream().mapToDouble(Double::doubleValue).sum())
                .collect(Collectors.toList());

        Double totalRisk = scoringStrategy.aggregate(allScoresFromAllEpochs);

        if (totalRisk >= riskThreshold) {
            log.info("Risk detected. Aggregated risk since {}: {} greater than threshold {}",
                    latestRiskEpoch,
                    totalRisk,
                    riskThreshold);

            // A risk has been detected, move time marker to now so that further risks are only posterior to this one
            int newLatestRiskEpoch = TimeUtils.getCurrentEpochFrom(timeStart);
            registration.setLatestRiskEpoch(newLatestRiskEpoch);
            log.info("Updating latest risk epoch {}", newLatestRiskEpoch);
            registration.setAtRisk(true);
        }
    }
}
