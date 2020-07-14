package fr.gouv.stopc.robert.server.batch.writer;

import fr.gouv.stopc.robert.server.batch.configuration.ContactsProcessingConfiguration;
import fr.gouv.stopc.robert.server.batch.utils.ItemProcessingCounterUtils;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.service.ContactService;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.core.StepExecution;
import org.springframework.batch.core.annotation.BeforeStep;
import org.springframework.batch.item.ItemWriter;
import org.springframework.util.CollectionUtils;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

@Slf4j
@AllArgsConstructor
public class ContactItemWriter implements ItemWriter<Contact> {

    private ContactService contactService;

    private Long totalContactCount;

    public ContactItemWriter(ContactService contactService){
        this.contactService = contactService;
    }

    @Override
    public void write(List<? extends Contact> items) {

        if (!CollectionUtils.isEmpty(items)) {
            log.info("== Start the delete of contact list ==");

            deleteContactList((List<Contact>)items);

            log.info("== End of the delete of contact list ==");
        } else {
            log.info("== There aren't any Contact to delete.");
        }
    }

    /**
     * Delete Contacts
     *
     * @param contactList
     */
    private void deleteContactList(List<Contact> contactList){
        Instant startTime = Instant.now();

        log.info("{} Contact(s) to remove.", contactList.size());
        contactService.deleteAll(contactList);

        long timeElapsed = Duration.between(startTime, Instant.now()).getSeconds();
        int processedContactCount = ItemProcessingCounterUtils.getInstance()
                .addNumberOfProcessedContacts(contactList.size());

        log.info("Execution duration of the update/delete of data : {} second(s).", timeElapsed);
        log.info("Total number of processed contacts/Total contact count : {}/{}", processedContactCount, totalContactCount);
    }

    @BeforeStep
    public void beforeStep(StepExecution stepExecution) {

            totalContactCount = stepExecution.getJobExecution().getExecutionContext().
                    getLong(ContactsProcessingConfiguration.TOTAL_CONTACT_COUNT_KEY);

    }
}
