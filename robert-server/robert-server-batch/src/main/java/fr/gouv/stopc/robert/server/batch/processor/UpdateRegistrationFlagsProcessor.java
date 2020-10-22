package fr.gouv.stopc.robert.server.batch.processor;

import org.springframework.batch.item.ItemProcessor;

import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.database.model.Registration;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@AllArgsConstructor
public class UpdateRegistrationFlagsProcessor implements ItemProcessor<Registration, Registration> {

    private PropertyLoader propertyLoader;

    @Override
    public Registration process(Registration registration) throws Exception {

        if(registration.isAtRisk() && registration.isNotified()) {

            if(registration.getLastStatusRequestEpoch() - registration.getLatestRiskEpoch() >= this.propertyLoader.getAtRiskNotificationEpochGap()) {
                registration.setAtRisk(false);
                return registration;
            }
        }
        return null;
    }

}
