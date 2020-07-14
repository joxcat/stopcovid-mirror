package test.fr.gouv.stopc.robertserver.batch.service;

import fr.gouv.stopc.robert.server.batch.RobertServerBatchApplication;
import fr.gouv.stopc.robert.server.batch.repository.ItemIdMappingRepository;
import fr.gouv.stopc.robert.server.batch.service.impl.ItemIdMappingServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;

import static org.mockito.Mockito.verify;

@Slf4j
@TestPropertySource("classpath:application.properties")
@ContextConfiguration(classes = RobertServerBatchApplication.class)
@SpringBootTest(properties = "robert.scoring.algo-version=0")
public class ItemIdMappingServiceTest {

    @InjectMocks
    private ItemIdMappingServiceImpl itemIdMappingService;

    @Mock
    ItemIdMappingRepository itemIdMappingRepository;


    @Test
    public void countNbUsersWithOldEpochExpositions() {

        // When
        this.itemIdMappingService.getItemIdMappingsBetweenIds(3, 10);

        // Then
        verify(this.itemIdMappingRepository).getItemIdMappingsBetweenIds(3, 10);
    }
}
