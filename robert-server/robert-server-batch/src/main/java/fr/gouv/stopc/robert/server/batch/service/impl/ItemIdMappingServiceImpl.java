package fr.gouv.stopc.robert.server.batch.service.impl;

import fr.gouv.stopc.robert.server.batch.repository.ItemIdMappingRepository;
import fr.gouv.stopc.robert.server.batch.service.ItemIdMappingService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.inject.Inject;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
public class ItemIdMappingServiceImpl<T> implements ItemIdMappingService {

    private ItemIdMappingRepository itemIdMappingRepository;

    @Inject
    public ItemIdMappingServiceImpl(ItemIdMappingRepository itemIdMappingRepository) {
        this.itemIdMappingRepository = itemIdMappingRepository;
    }


    @Override
    public void deleteAll() {
        itemIdMappingRepository.deleteAll();
    }

    @Override
    public List<T> getItemIdMappingsBetweenIds(long startId, long endId) {

        return itemIdMappingRepository.getItemIdMappingsBetweenIds(startId, endId).stream()
                .map(item -> (T)item.getItemId())
                .collect(Collectors.toList());
    }
}
