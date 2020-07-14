package fr.gouv.stopc.robert.server.batch.processor;

import fr.gouv.stopc.robert.server.batch.model.ItemIdMapping;
import fr.gouv.stopc.robert.server.batch.utils.ItemProcessingCounterUtils;
import fr.gouv.stopc.robertserver.database.model.Contact;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.item.ItemProcessor;

@Slf4j
@AllArgsConstructor
public class ContactIdMappingProcessor implements ItemProcessor<Contact, ItemIdMapping<String>> {

    @Override
    public ItemIdMapping process(Contact contact) {
        Long id = ItemProcessingCounterUtils.getInstance().incrementCurrentIdOfItemIdMapping();

        return ItemIdMapping.builder()
                .id(id).itemId(contact.getId()).build();
    }
}
