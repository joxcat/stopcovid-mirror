package fr.gouv.stopc.robert.server.batch.listener;

import fr.gouv.stopc.robert.server.batch.configuration.ContactsProcessingConfiguration;
import fr.gouv.stopc.robert.server.batch.service.ItemIdMappingService;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.service.ContactService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.core.JobExecution;
import org.springframework.batch.core.JobExecutionListener;

/**
 * This JobExecutionListener computes the chunk size according to the contact total count.
 */
@Slf4j
@AllArgsConstructor
public class ProcessingJobExecutionListener implements JobExecutionListener {

    private String totalItemCountKey;
    private IRegistrationService registrationService;
    private ContactService contactService;
    private IServerConfigurationService serverConfigurationService;
    private PropertyLoader propertyLoader;
    private ItemIdMappingService itemIdMappingService;


    @Override
    public void beforeJob(JobExecution jobExecution) {
        jobExecution.getExecutionContext().putLong(totalItemCountKey, getTotalItemCount());

        //reset the itemIdMapping collections
        log.info("START : Reset the itemIdMapping collection.");
        itemIdMappingService.deleteAll();
        log.info("END : Reset the itemIdMapping collection.");
    }

    private int getTotalItemCount(){
        int totalItemCount = 0;

        if (ContactsProcessingConfiguration.TOTAL_REGISTRATION_COUNT_KEY.equals(totalItemCountKey)){
            totalItemCount = registrationService.count().intValue();
        } else if(ContactsProcessingConfiguration.TOTAL_CONTACT_COUNT_KEY.equals(totalItemCountKey)){
            totalItemCount = contactService.count().intValue();
        } else if(ContactsProcessingConfiguration.TOTAL_REGISTRATION_FOR_PURGE_COUNT_KEY.equals(totalItemCountKey)){
            totalItemCount = registrationService.countNbUsersWithOldEpochExpositions(computeMinOldEpochId()).intValue();
        }

        return totalItemCount;
    }

    private int computeMinOldEpochId(){
        int currentEpochId = TimeUtils.getCurrentEpochFrom(serverConfigurationService.getServiceTimeStart());
        int contagiousPeriod = this.propertyLoader.getContagiousPeriod();
        int minEpochId = currentEpochId - contagiousPeriod * 96;

        log.debug("Min EpochId for the purge of old epoch expositions : {}", minEpochId);

        return minEpochId;
    }

    @Override
    public void afterJob(JobExecution jobExecution) {
        //reset the itemIdMapping collections
        log.info("START : Reset the itemIdMapping collection.");
        itemIdMappingService.deleteAll();
        log.info("END : Reset the itemIdMapping collection.");
    }
}
