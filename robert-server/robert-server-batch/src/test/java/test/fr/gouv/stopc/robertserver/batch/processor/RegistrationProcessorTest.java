package test.fr.gouv.stopc.robertserver.batch.processor;

import fr.gouv.stopc.robert.server.batch.RobertServerBatchApplication;
import fr.gouv.stopc.robert.server.batch.configuration.RobertServerBatchConfiguration;
import fr.gouv.stopc.robert.server.batch.processor.RegistrationProcessor;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import test.fr.gouv.stopc.robertserver.batch.utils.ProcessorTestUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@Slf4j
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = { RobertServerBatchApplication.class })
@TestPropertySource(locations = "classpath:application.properties",
        properties = {
                "robert.scoring.algo-version=2",
                "robert.scoring.batch-mode=FULL_REGISTRATION_SCAN_COMPUTE_RISK"
        })
public class RegistrationProcessorTest {

    private RegistrationProcessor registrationProcessor;

    @Autowired
    private IServerConfigurationService serverConfigurationService;

    @Autowired
    private IRegistrationService registrationService;

    @Autowired
    private ScoringStrategyService scoringStrategyService;

    @Autowired
    private PropertyLoader propertyLoader;

    private Optional<Registration> registration;

    @MockBean
    private RobertServerBatchConfiguration configuration;

    private int currentEpoch;
    private static int ARBITRARY_SCORE_EPOCH_START = 500;


    @BeforeEach
    public void beforeEach() {
        this.registrationProcessor = new RegistrationProcessor(
                serverConfigurationService,
                registrationService,
                scoringStrategyService,
                propertyLoader
        );
        this.currentEpoch = TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart());

        // TODO: Mock configuration service to simulate overall service having been started since 14 days in order to test purge
    }

    @Test
    public void testNoScoresNoRiskSucceeds() {
        this.registration = this.registrationService.createRegistration(ProcessorTestUtils.generateIdA());

        assertTrue(this.registration.isPresent());
        this.registrationProcessor.process(this.registration.get());

        Optional<Registration> reg = this.registrationService.findById(this.registration.get().getPermanentIdentifier());
        assertTrue(reg.isPresent() && !reg.get().isAtRisk());
        assertEquals(reg.get().getLatestRiskEpoch(), 0);
    }

    @Test
    public void testScoresAtRiskNotSetNoRiskDetectedSucceeds() {
        this.registration = this.registrationService.createRegistration(ProcessorTestUtils.generateIdA());
        assertTrue(this.registration.isPresent());

        Double[] expositionsForFirstEpoch = new Double[] { 1.0 };
        Double[] expositionsForSecondEpoch = new Double[] { 12.5 };
        ArrayList<EpochExposition> expositions = new ArrayList<>();
        expositions.add(EpochExposition.builder()
                .epochId(ARBITRARY_SCORE_EPOCH_START)
                .expositionScores(Arrays.asList(expositionsForFirstEpoch))
                .build());
        expositions.add(EpochExposition.builder()
                .epochId(ARBITRARY_SCORE_EPOCH_START + 7)
                .expositionScores(Arrays.asList(expositionsForSecondEpoch))
                .build());

        this.registration.get().setExposedEpochs(expositions);

        this.registrationProcessor.process(this.registration.get());

        Optional<Registration> reg = this.registrationService.findById(this.registration.get().getPermanentIdentifier());
        assertTrue(reg.isPresent() && !reg.get().isAtRisk());
        assertEquals(reg.get().getLatestRiskEpoch(), 0);
        assertTrue(Arrays.equals(reg.get().getExposedEpochs().get(0).getExpositionScores().toArray(),
                expositionsForFirstEpoch));
        assertTrue(Arrays.equals(reg.get().getExposedEpochs().get(1).getExpositionScores().toArray(),
                expositionsForSecondEpoch));
    }

    @Test
    public void testScoresAtRiskNotSetButRiskDetectedSucceeds() {
        this.registration = this.registrationService.createRegistration(ProcessorTestUtils.generateIdA());
        assertTrue(this.registration.isPresent());

        Double[] expositionsForFirstEpoch = new Double[] { 1.0 };
        Double[] expositionsForSecondEpoch = new Double[] { 14.5 };
        ArrayList<EpochExposition> expositions = new ArrayList<>();
        expositions.add(EpochExposition.builder()
                .epochId(this.currentEpoch - ARBITRARY_SCORE_EPOCH_START)
                .expositionScores(Arrays.asList(expositionsForFirstEpoch))
                .build());
        expositions.add(EpochExposition.builder()
                .epochId(this.currentEpoch - ARBITRARY_SCORE_EPOCH_START + 7)
                .expositionScores(Arrays.asList(expositionsForSecondEpoch))
                .build());

        this.registration.get().setExposedEpochs(expositions);

        this.registrationProcessor.process(this.registration.get());

        Optional<Registration> reg = this.registrationService.findById(this.registration.get().getPermanentIdentifier());
        assertTrue(reg.isPresent() && reg.get().isAtRisk());
        assertEquals(reg.get().getLatestRiskEpoch(), this.currentEpoch);
        assertTrue(Arrays.equals(reg.get().getExposedEpochs().get(0).getExpositionScores().toArray(),
                expositionsForFirstEpoch));
        assertTrue(Arrays.equals(reg.get().getExposedEpochs().get(1).getExpositionScores().toArray(),
                expositionsForSecondEpoch));
    }

    @Test
    public void testScoresAtRiskNotSetButRiskDetectedSingleEpochSucceeds() {
        this.registration = this.registrationService.createRegistration(ProcessorTestUtils.generateIdA());
        assertTrue(this.registration.isPresent());

        Double[] expositionsForFirstEpoch = new Double[] { 10.0, 2.0, 1.0, 4.3 };
        Double[] expositionsForSecondEpoch = new Double[] { };
        ArrayList<EpochExposition> expositions = new ArrayList<>();
        expositions.add(EpochExposition.builder()
                .epochId(this.currentEpoch - ARBITRARY_SCORE_EPOCH_START)
                .expositionScores(Arrays.asList(expositionsForFirstEpoch))
                .build());
        expositions.add(EpochExposition.builder()
                .epochId(this.currentEpoch - ARBITRARY_SCORE_EPOCH_START + 7)
                .expositionScores(Arrays.asList(expositionsForSecondEpoch))
                .build());

        this.registration.get().setExposedEpochs(expositions);

        this.registrationProcessor.process(this.registration.get());

        Optional<Registration> reg = this.registrationService.findById(this.registration.get().getPermanentIdentifier());
        assertTrue(reg.isPresent() && reg.get().isAtRisk());
        assertEquals(reg.get().getLatestRiskEpoch(), this.currentEpoch);
        assertTrue(Arrays.equals(reg.get().getExposedEpochs().get(0).getExpositionScores().toArray(),
                expositionsForFirstEpoch));
        assertTrue(Arrays.equals(reg.get().getExposedEpochs().get(1).getExpositionScores().toArray(),
                expositionsForSecondEpoch));
    }

    @Test
    public void testNotifiedRemainsTrueIfRiskDetectedSucceeds() {
        Double[] expositionsForFirstEpoch = new Double[] { 10.0, 2.0, 1.0, 4.3 };
        Double[] expositionsForSecondEpoch = new Double[] { };
        ArrayList<EpochExposition> expositions = new ArrayList<>();
        expositions.add(EpochExposition.builder()
                .epochId(this.currentEpoch - ARBITRARY_SCORE_EPOCH_START)
                .expositionScores(Arrays.asList(expositionsForFirstEpoch))
                .build());
        expositions.add(EpochExposition.builder()
                .epochId(this.currentEpoch - ARBITRARY_SCORE_EPOCH_START + 7)
                .expositionScores(Arrays.asList(expositionsForSecondEpoch))
                .build());

        testNotifiedNotModified(true, expositions, true);
    }

    @Test
    public void testNotifiedRemainsFalseIfRiskDetectedSucceeds() {
        Double[] expositionsForFirstEpoch = new Double[] { 10.0, 2.0, 1.0, 4.3 };
        Double[] expositionsForSecondEpoch = new Double[] { };
        ArrayList<EpochExposition> expositions = new ArrayList<>();
        expositions.add(EpochExposition.builder()
                .epochId(this.currentEpoch - ARBITRARY_SCORE_EPOCH_START)
                .expositionScores(Arrays.asList(expositionsForFirstEpoch))
                .build());
        expositions.add(EpochExposition.builder()
                .epochId(this.currentEpoch - ARBITRARY_SCORE_EPOCH_START + 7)
                .expositionScores(Arrays.asList(expositionsForSecondEpoch))
                .build());

        testNotifiedNotModified(false, expositions, true);
    }

    @Test
    public void testNotifiedRemainsTrueIfRiskNotDetectedSucceeds() {
        Double[] expositionsForFirstEpoch = new Double[] { 10.0 };
        Double[] expositionsForSecondEpoch = new Double[] { };
        ArrayList<EpochExposition> expositions = new ArrayList<>();
        expositions.add(EpochExposition.builder()
                .epochId(ARBITRARY_SCORE_EPOCH_START)
                .expositionScores(Arrays.asList(expositionsForFirstEpoch))
                .build());
        expositions.add(EpochExposition.builder()
                .epochId(ARBITRARY_SCORE_EPOCH_START + 7)
                .expositionScores(Arrays.asList(expositionsForSecondEpoch))
                .build());

        testNotifiedNotModified(true, expositions, false);
    }

    @Test
    public void testNotifiedRemainsFalseIfRiskNotDetectedSucceeds() {
        Double[] expositionsForFirstEpoch = new Double[] { 10.0 };
        Double[] expositionsForSecondEpoch = new Double[] { };
        ArrayList<EpochExposition> expositions = new ArrayList<>();
        expositions.add(EpochExposition.builder()
                .epochId(ARBITRARY_SCORE_EPOCH_START)
                .expositionScores(Arrays.asList(expositionsForFirstEpoch))
                .build());
        expositions.add(EpochExposition.builder()
                .epochId(ARBITRARY_SCORE_EPOCH_START + 7)
                .expositionScores(Arrays.asList(expositionsForSecondEpoch))
                .build());

        testNotifiedNotModified(false, expositions, false);
    }

    private void testNotifiedNotModified(boolean initialValue, List<EpochExposition> expositions, boolean riskDetected) {
        this.registration = this.registrationService.createRegistration(ProcessorTestUtils.generateIdA());
        assertTrue(this.registration.isPresent());
        this.registration.get().setNotified(initialValue);

        this.registration.get().setExposedEpochs(expositions);

        this.registrationProcessor.process(this.registration.get());

        Optional<Registration> reg = this.registrationService.findById(this.registration.get().getPermanentIdentifier());
        assertTrue(reg.isPresent() && riskDetected == reg.get().isAtRisk());
        assertEquals(reg.get().getLatestRiskEpoch(), riskDetected ? this.currentEpoch : 0);
        assertTrue(Arrays.equals(reg.get().getExposedEpochs().get(0).getExpositionScores().toArray(),
                expositions.get(0).getExpositionScores().toArray()));
        assertTrue(Arrays.equals(reg.get().getExposedEpochs().get(1).getExpositionScores().toArray(),
                expositions.get(1).getExpositionScores().toArray()));
        assertEquals(initialValue, reg.get().isNotified());
    }
}
