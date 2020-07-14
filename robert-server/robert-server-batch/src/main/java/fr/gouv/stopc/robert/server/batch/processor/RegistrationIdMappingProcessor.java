package fr.gouv.stopc.robert.server.batch.processor;

import fr.gouv.stopc.robert.server.batch.model.ItemIdMapping;
import fr.gouv.stopc.robert.server.batch.utils.ItemProcessingCounterUtils;
import fr.gouv.stopc.robertserver.database.model.Registration;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.batch.item.ItemProcessor;

@Slf4j
@AllArgsConstructor
public class RegistrationIdMappingProcessor implements ItemProcessor<Registration, ItemIdMapping<byte[]>> {

    @Override
    public ItemIdMapping process(Registration registration) {
        Long id = ItemProcessingCounterUtils.getInstance().incrementCurrentIdOfItemIdMapping();

        return ItemIdMapping.builder()
                .id(id).itemId(registration.getPermanentIdentifier()).build();
    }
}
