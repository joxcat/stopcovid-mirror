package fr.gouv.stopc.robert.server.batch.processor;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import org.springframework.batch.item.ItemProcessor;

import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.batch.utils.ScoringUtils;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.Registration;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;


@Slf4j
@AllArgsConstructor
public class PurgeOldEpochExpositionsProcessor implements ItemProcessor<Registration, Registration> {

    private IServerConfigurationService serverConfigurationService;
    private PropertyLoader propertyLoader;

    @Override
    public Registration process(Registration registration) {
        log.debug("Purge Old Epoch Expositions started.");
        List<EpochExposition> exposedEpochs = registration.getExposedEpochs();

        // Exposed epochs should be empty, never null
        if (Objects.isNull(exposedEpochs)) {
            exposedEpochs = new ArrayList<>();
        }

        int currentEpochId = TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart());
        List<EpochExposition> epochsToKeep = ScoringUtils.getExposedEpochsWithoutEpochsOlderThanContagiousPeriod(
                exposedEpochs,
                currentEpochId,
                this.propertyLoader.getContagiousPeriod(),
                this.serverConfigurationService.getEpochDurationSecs());

        registration.setExposedEpochs(epochsToKeep);

        return registration;
    }
}
