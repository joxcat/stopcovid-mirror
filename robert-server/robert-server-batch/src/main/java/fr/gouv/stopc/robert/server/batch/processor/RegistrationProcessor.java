package fr.gouv.stopc.robert.server.batch.processor;

import java.util.List;

import org.springframework.batch.item.ItemProcessor;

import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.batch.utils.ScoringUtils;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.Registration;
import lombok.AllArgsConstructor;

@AllArgsConstructor
public class RegistrationProcessor implements ItemProcessor<Registration, Registration> {

    private IServerConfigurationService serverConfigurationService;

    private ScoringStrategyService scoringStrategy;

    private PropertyLoader propertyLoader;

    @Override
    public Registration process(Registration registration) {

        int currentEpochId = TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart());
        List<EpochExposition> epochsToKeep = ScoringUtils.getExposedEpochsWithoutEpochsOlderThanContagiousPeriod(
                registration.getExposedEpochs(),
                currentEpochId,
                this.propertyLoader.getContagiousPeriod(),
                this.serverConfigurationService.getEpochDurationSecs());

        boolean isRegistrationAtRisk = ScoringUtils.updateRegistrationIfRisk(
                registration,
                epochsToKeep,
                this.serverConfigurationService.getServiceTimeStart(),
                this.propertyLoader.getRiskThreshold(),
                this.scoringStrategy
                );

        if(isRegistrationAtRisk){
            return registration;
        }

        return null;
    }
}
