package fr.gouv.stopc.robert.server.batch.listener;

import org.springframework.batch.core.ExitStatus;
import org.springframework.batch.core.StepExecution;
import org.springframework.batch.core.StepExecutionListener;

import fr.gouv.stopc.robert.server.batch.service.ItemIdMappingService;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@AllArgsConstructor
public class PopulateIdMappingListener implements StepExecutionListener {

    private ItemIdMappingService itemIdMappingService;
    
    @Override
    public void beforeStep(StepExecution stepExecution) {
        log.info("START : Reset the itemIdMapping collection.");
        itemIdMappingService.deleteAll();
        log.info("END : Reset the itemIdMapping collection.");
        
    }

    @Override
    public ExitStatus afterStep(StepExecution stepExecution) {
        return stepExecution.getExitStatus();
    }

}
