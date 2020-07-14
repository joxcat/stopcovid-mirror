package test.fr.gouv.stopc.robertserver.batch.processor;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import fr.gouv.stopc.robert.server.batch.RobertServerBatchApplication;
import fr.gouv.stopc.robert.server.batch.configuration.ContactsProcessingConfiguration;
import fr.gouv.stopc.robert.server.batch.processor.PurgeOldEpochExpositionsProcessor;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.batch.writer.RegistrationItemWriter;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import test.fr.gouv.stopc.robertserver.batch.utils.ProcessorTestUtils;

@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = { RobertServerBatchApplication.class })
@TestPropertySource("classpath:application.properties")
@TestPropertySource(locations = "classpath:application.properties",
        properties = {
                "robert.scoring.algo-version=2"
        })
public class PurgeOldEpochExpositionsProcessorTest {

    private PurgeOldEpochExpositionsProcessor purgeOldEpochExpositionsProcessor;

    private RegistrationItemWriter registrationItemWriter;

    @Autowired
    private IServerConfigurationService serverConfigurationService;

    @Autowired
    private IRegistrationService registrationService;

    @Autowired
    private PropertyLoader propertyLoader;

    private Optional<Registration> registration;

    private int currentEpoch;

    @BeforeEach
    public void beforeEach() {
        this.purgeOldEpochExpositionsProcessor = new PurgeOldEpochExpositionsProcessor(this.serverConfigurationService,
                this.propertyLoader);
        this.registrationItemWriter =  new RegistrationItemWriter(registrationService,
                ContactsProcessingConfiguration.TOTAL_REGISTRATION_FOR_PURGE_COUNT_KEY);
        
        this.currentEpoch = TimeUtils.getCurrentEpochFrom(serverConfigurationService.getServiceTimeStart());
    }

    @Test
    public void testRegistrationWithExposedEpochsNull() {
        // Given
        this.registration = this.registrationService.createRegistration(ProcessorTestUtils.generateIdA());
        assertTrue(this.registration.isPresent());

        // When
        this.purgeOldEpochExpositionsProcessor.process(this.registration.get());
        this.registrationItemWriter.write(Collections.singletonList(this.registration.get()));

        // Then
        Optional<Registration> reg = this.registrationService.findById(this.registration.get().getPermanentIdentifier());
        assertNotNull(reg.get().getExposedEpochs());
        assertTrue(reg.get().getExposedEpochs().isEmpty());
    }

    @Test
    public void testRegistrationWithOnlyRecentExposedEpochs() {
        // Given
        this.registration = this.registrationService.createRegistration(ProcessorTestUtils.generateIdA());
        assertTrue(this.registration.isPresent());

        int epochId = this.currentEpoch - (14 * 96) + new SecureRandom().nextInt(100) + 1;
        Double[] expositionsForFirstEpoch = new Double[] { 1.0 };
        Double[] expositionsForSecondEpoch = new Double[] { 12.5 };
        ArrayList<EpochExposition> expositions = new ArrayList<>();
        expositions.add(EpochExposition.builder()
                .epochId(epochId)
                .expositionScores(Arrays.asList(expositionsForFirstEpoch))
                .build());
        expositions.add(EpochExposition.builder()
                .epochId(epochId + 7)
                .expositionScores(Arrays.asList(expositionsForSecondEpoch))
                .build());

        this.registration.get().setExposedEpochs(expositions);

        // WHen
        this.purgeOldEpochExpositionsProcessor.process(this.registration.get());
        this.registrationItemWriter.write(Collections.singletonList(this.registration.get()));

        // Then
        Optional<Registration> reg = this.registrationService.findById(this.registration.get().getPermanentIdentifier());
        assertNotNull(reg.get().getExposedEpochs());
        assertEquals(2, reg.get().getExposedEpochs().size());
    }

    @Test
    public void testRegistrationWithOneOldExposedEpochs() {
        // Given
        this.registration = this.registrationService.createRegistration(ProcessorTestUtils.generateIdA());
        assertTrue(this.registration.isPresent());

        int epochId = this.currentEpoch - (14 * 96) + new SecureRandom().nextInt(100) + 1;
        Double[] expositionsForFirstEpoch = new Double[] { 1.0 };
        Double[] expositionsForSecondEpoch = new Double[] { 12.5 };
        ArrayList<EpochExposition> expositions = new ArrayList<>();
        expositions.add(EpochExposition.builder()
                .epochId(epochId)
                .expositionScores(Arrays.asList(expositionsForFirstEpoch))
                .build());
        expositions.add(EpochExposition.builder()
                .epochId(epochId - (30 * 96))
                .expositionScores(Arrays.asList(expositionsForSecondEpoch))
                .build());

        this.registration.get().setExposedEpochs(expositions);

        // WHen
        this.purgeOldEpochExpositionsProcessor.process(this.registration.get());
        this.registrationItemWriter.write(Collections.singletonList(this.registration.get()));

        // Then
        Optional<Registration> reg = this.registrationService.findById(this.registration.get().getPermanentIdentifier());
        assertNotNull(reg.get().getExposedEpochs());
        assertEquals(1, reg.get().getExposedEpochs().size());
    }
}
