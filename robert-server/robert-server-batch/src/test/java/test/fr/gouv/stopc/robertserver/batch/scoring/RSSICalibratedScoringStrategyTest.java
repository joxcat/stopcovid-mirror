package test.fr.gouv.stopc.robertserver.batch.scoring;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import fr.gouv.stopc.robert.server.batch.service.impl.ScoringStrategyServiceImpl;
import fr.gouv.stopc.robert.server.common.service.impl.ServerConfigurationServiceImpl;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.annotation.DirtiesContext.ClassMode;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import fr.gouv.stopc.robert.server.batch.RobertServerBatchApplication;
import fr.gouv.stopc.robert.server.batch.exception.RobertScoringException;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.HelloMessageDetail;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@ExtendWith(SpringExtension.class)
public class RSSICalibratedScoringStrategyTest {

    private final static String FAIL_EXCEPTION = "Should not fail";

    private ScoringStrategyServiceImpl scoringStrategyService;

    private ServerConfigurationServiceImpl serverConfigurationService;

    private Long randomReferenceEpochStartTime;

    private Double riskThreshold;

    @BeforeEach
    public void beforeEach() {
        this.serverConfigurationService = new ServerConfigurationServiceImpl();
        this.scoringStrategyService = new ScoringStrategyServiceImpl(this.serverConfigurationService);
        this.randomReferenceEpochStartTime = this.serverConfigurationService.getServiceTimeStart() + new Random().nextInt(20) * this.serverConfigurationService.getEpochDurationSecs();
        this.riskThreshold = this.serverConfigurationService.getRiskThreshold();
    }

    @Test
    public void testScoreRisk1minEncounterNotAtRisk() {
        List<HelloMessageDetail> messages = new ArrayList<>();
        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 178L)
                .rssiCalibrated(-78)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 180L)
                .rssiCalibrated(-50)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 214L)
                .rssiCalibrated(-35)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 225L)
                .rssiCalibrated(-42)
                .build());

        Contact contact = Contact.builder()
                .messageDetails(messages)
                .build();

        Double score = null;
        try {
            score = scoringStrategyService.execute(contact);
        } catch (RobertScoringException e) {
            fail(FAIL_EXCEPTION);
        }

        log.info(String.format("1-minute encounter (4 messages over 1 minute): %f", score));
        assertTrue(score < this.riskThreshold);
    }

    @Test
    public void testScoreRisk10minEncounterAtRisk() {
        List<HelloMessageDetail> messages = new ArrayList<>();
        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 178L)
                .rssiCalibrated(-78)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 180L)
                .rssiCalibrated(-50)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 214L)
                .rssiCalibrated(-35)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 225L)
                .rssiCalibrated(-42)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 278L)
                .rssiCalibrated(-78)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 301L)
                .rssiCalibrated(-50)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 450L)
                .rssiCalibrated(-35)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 489L)
                .rssiCalibrated(-42)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 543L)
                .rssiCalibrated(-35)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 576L)
                .rssiCalibrated(-42)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 602L)
                .rssiCalibrated(-35)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 741L)
                .rssiCalibrated(-42)
                .build());

        Contact contact = Contact.builder()
                .messageDetails(messages)
                .build();

        Double score = null;
        try {
            score = scoringStrategyService.execute(contact);
        } catch (RobertScoringException e) {
            fail(FAIL_EXCEPTION);
        }

        log.info(String.format("10-minute encounter (12 messages over 10 minutes): %f", score));
        assertTrue(score > this.riskThreshold);
    }

    @Test
    public void testScoreRisk5secEncounterNotAtRisk() {
        List<HelloMessageDetail> messages = new ArrayList<>();
        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 178L)
                .rssiCalibrated(-78)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 180L)
                .rssiCalibrated(-50)
                .build());

        Contact contact = Contact.builder()
                .messageDetails(messages)
                .build();

        Double score = null;
        try {
            score = scoringStrategyService.execute(contact);
        } catch (RobertScoringException e) {
            fail(FAIL_EXCEPTION);
        }

        log.info(String.format("Short encounter (2 messages over 5 seconds): %f", score));
        assertTrue(score < this.riskThreshold);
    }

    @Test
    public void testScoreRiskSpottyEncounterAtRisk() {
        List<HelloMessageDetail> messages = new ArrayList<>();
        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 15L)
                .rssiCalibrated(-78)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 180L)
                .rssiCalibrated(-30)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 500L)
                .rssiCalibrated(-100)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 719L)
                .rssiCalibrated(-60)
                .build());

        Contact contact = Contact.builder()
                .messageDetails(messages)
                .build();

        Double score = null;
        try {
            score = scoringStrategyService.execute(contact);
        } catch (RobertScoringException e) {
            fail(FAIL_EXCEPTION);
        }

        log.info(String.format("Spotty encounter (4 messages over 10+ minutes): %f", score));
        assertTrue(score > this.riskThreshold);
    }

    @Test
    public void testScoreRiskOneEarlyOneLateNotAtRisk() {
        List<HelloMessageDetail> messages = new ArrayList<>();
        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 5L)
                .rssiCalibrated(-70)
                .build());

        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + (900L - 5L))
                .rssiCalibrated(-78)
                .build());

        Contact contact = Contact.builder()
                .messageDetails(messages)
                .build();

        Double score = null;
        try {
            score = scoringStrategyService.execute(contact);
        } catch (RobertScoringException e) {
            fail(FAIL_EXCEPTION);
        }

        log.info(String.format("One early, one late: %f", score));
        assertTrue(score < this.riskThreshold);
    }

    @Test
    public void testScoreRiskOneMessageEarlyNotAtRisk() {
        List<HelloMessageDetail> messages = new ArrayList<>();
        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + 5L)
                .rssiCalibrated(-15)
                .build());

        Contact contact = Contact.builder()
                .messageDetails(messages)
                .build();

        Double score = null;
        try {
            score = scoringStrategyService.execute(contact);
        } catch (RobertScoringException e) {
            fail(FAIL_EXCEPTION);
        }

        log.info(String.format("One message, early: %f", score));
        assertTrue(score < this.riskThreshold);
    }

    @Test
    public void testScoreRiskOneMessageLateNotAtRisk() {
        List<HelloMessageDetail> messages = new ArrayList<>();
        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + (900L - 5L))
                .rssiCalibrated(-78)
                .build());

        Contact contact = Contact.builder()
                .messageDetails(messages)
                .build();

        Double score = null;
        try {
            score = scoringStrategyService.execute(contact);
        } catch (RobertScoringException e) {
            fail(FAIL_EXCEPTION);
        }

        log.info(String.format("One message, late: %f", score));
        assertTrue(score < this.riskThreshold);
    }

    @Test
    public void testScoreRiskOneMessageJustAfterHalfNotAtRisk() {
        List<HelloMessageDetail> messages = new ArrayList<>();
        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + (900 / 2 + 5))
                .rssiCalibrated(-78)
                .build());

        Contact contact = Contact.builder()
                .messageDetails(messages)
                .build();

        Double score = null;
        try {
            score = scoringStrategyService.execute(contact);
        } catch (RobertScoringException e) {
            fail(FAIL_EXCEPTION);
        }

        log.info(String.format("Just after half way of epoch: %f", score));
        assertTrue(score < this.riskThreshold);
    }

    @Test
    public void testScoreRiskOneMessageJustBeforeHalfNotAtRisk() {
        List<HelloMessageDetail> messages = new ArrayList<>();
        messages.add(HelloMessageDetail.builder()
                .timeCollectedOnDevice(this.randomReferenceEpochStartTime + (900 / 2 + 5))
                .rssiCalibrated(-78)
                .build());

        Contact contact = Contact.builder()
                .messageDetails(messages)
                .build();

        Double score = null;
        try {
            score = scoringStrategyService.execute(contact);
        } catch (RobertScoringException e) {
            fail(FAIL_EXCEPTION);
        }

        log.info(String.format("Just before half way of epoch: %f", score));
        assertTrue(score < this.riskThreshold);
    }

    @Test
    public void testScoreRiskNoMessagesFail() {
        Contact contact = Contact.builder()
                .messageDetails(new ArrayList<>())
                .build();

        RobertScoringException thrown = assertThrows(
                RobertScoringException.class,
                () -> scoringStrategyService.execute(contact),
                "Expected doThing() to throw, but it didn't"
        );

        assertNotEquals(null, thrown);
    }
}
