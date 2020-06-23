package test.fr.gouv.stopc.robertserver.batch.scoring;

import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import fr.gouv.stopc.robert.server.batch.RobertServerBatchApplication;
import fr.gouv.stopc.robert.server.batch.exception.RobertScoringException;
import fr.gouv.stopc.robert.server.batch.service.impl.ScoringStrategyServiceImpl;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.HelloMessageDetail;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@TestPropertySource("classpath:application.properties")
@ContextConfiguration(classes = RobertServerBatchApplication.class)
@SpringBootTest(properties = "robert.scoring.algo-version=0")
public class RSSICalibratedScoringStrategyTest {

	private final static String FAIL_EXCEPTION = "Should not fail";

	@InjectMocks
	private ScoringStrategyServiceImpl scoringStrategyService;

	@Mock
	private IServerConfigurationService serverConfigurationService;

	@Mock
	private PropertyLoader propertyLoader;

	@Value("${robert.protocol.epoch-duration}")
	private Integer epochDuration;

	@Value("${robert.protocol.scoring-algo-rssi}")
	private Integer rssiScoringAlgorithm;

	private Long randomReferenceEpochStartTime;

	@Value("${robert.protocol.risk-threshold}")
	private Double riskThreshold;

	@BeforeEach
	public void beforeEach() {
		when(this.serverConfigurationService.getEpochDurationSecs()).thenReturn(this.epochDuration);
		when(this.propertyLoader.getRssiScoringAlgorithm()).thenReturn(this.rssiScoringAlgorithm);

		this.randomReferenceEpochStartTime = this.serverConfigurationService.getServiceTimeStart()
				+ new Random().nextInt(20) * this.serverConfigurationService.getEpochDurationSecs();
	}

	@Test
	public void testDateDiff() {
		final LocalDateTime ldt = LocalDateTime.of(2020, 6, 1, 00, 00);
		final ZonedDateTime zdt = ldt.atZone(ZoneId.of("Europe/Paris"));
		log.info("{}", TimeUtils.convertUnixMillistoNtpSeconds(zdt.toInstant().toEpochMilli()));

		final LocalDateTime ldt2 = LocalDateTime.of(2020, 6, 1, 00, 00);
		final ZonedDateTime zdt2 = ldt2.atZone(ZoneId.of("UTC"));
		log.info("{}", TimeUtils.convertUnixMillistoNtpSeconds(zdt2.toInstant().toEpochMilli()));
	}

	@Test
	public void testScoreRisk1minEncounterNotAtRisk() {
		List<HelloMessageDetail> messages = new ArrayList<>();
		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 178L)
				.rssiCalibrated(-78).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 180L)
				.rssiCalibrated(-50).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 214L)
				.rssiCalibrated(-35).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 225L)
				.rssiCalibrated(-42).build());

		Contact contact = Contact.builder().messageDetails(messages).build();

		Double score = null;
		try {
			score = this.scoringStrategyService.execute(contact).getRssiScore();
		} catch (RobertScoringException e) {
			fail(FAIL_EXCEPTION);
		}

		log.info(String.format("1-minute encounter (4 messages over 1 minute): %f", score));
		assertTrue(score < 1.0 && score > 0.75);
	}

	@Test
	public void testScoreRisk10minEncounterAtRisk() {
		List<HelloMessageDetail> messages = new ArrayList<>();
		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 178L)
				.rssiCalibrated(-78).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 180L)
				.rssiCalibrated(-50).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 214L)
				.rssiCalibrated(-35).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 225L)
				.rssiCalibrated(-42).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 278L)
				.rssiCalibrated(-78).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 301L)
				.rssiCalibrated(-50).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 450L)
				.rssiCalibrated(-35).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 489L)
				.rssiCalibrated(-42).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 543L)
				.rssiCalibrated(-35).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 576L)
				.rssiCalibrated(-42).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 602L)
				.rssiCalibrated(-35).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 741L)
				.rssiCalibrated(-42).build());

		Contact contact = Contact.builder().messageDetails(messages).build();

		Double score = null;
		try {
			score = this.scoringStrategyService.execute(contact).getRssiScore();
		} catch (RobertScoringException e) {
			fail(FAIL_EXCEPTION);
		}

		log.info(String.format("10-minute encounter (12 messages over 10 minutes): %f", score));
		assertTrue(score > 9.0 && score < 10.0);
	}

	@Test
	public void testScoreRisk5secEncounterNotAtRisk() {
		List<HelloMessageDetail> messages = new ArrayList<>();
		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 178L)
				.rssiCalibrated(-78).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 180L)
				.rssiCalibrated(-50).build());

		Contact contact = Contact.builder().messageDetails(messages).build();

		Double score = null;
		try {
			score = this.scoringStrategyService.execute(contact).getRssiScore();
		} catch (RobertScoringException e) {
			fail(FAIL_EXCEPTION);
		}

		log.info(String.format("Short encounter (2 messages over 5 seconds): %f", score));
		assertTrue(score < this.riskThreshold);
	}

	@Test
	public void testScoreRiskSpottyEncounterAtRisk() {
		List<HelloMessageDetail> messages = new ArrayList<>();
		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 15L)
				.rssiCalibrated(-78).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 180L)
				.rssiCalibrated(-30).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 500L)
				.rssiCalibrated(-100).build());

		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 719L)
				.rssiCalibrated(-60).build());

		Contact contact = Contact.builder().messageDetails(messages).build();

		Double score = null;
		try {
			score = this.scoringStrategyService.execute(contact).getRssiScore();
		} catch (RobertScoringException e) {
			fail(FAIL_EXCEPTION);
		}

		log.info(String.format("Spotty encounter (4 messages over 10+ minutes): %f", score));
		assertTrue(score > 6.0 && score < 7.0);
	}

	@Test
	public void testScoreRiskOneEarlyOneLateNotAtRisk() {
		List<HelloMessageDetail> messages = new ArrayList<>();
		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 5L)
				.rssiCalibrated(-70).build());

		messages.add(HelloMessageDetail.builder()
				.timeCollectedOnDevice(this.randomReferenceEpochStartTime + (900L - 5L)).rssiCalibrated(-78).build());

		Contact contact = Contact.builder().messageDetails(messages).build();

		Double score = null;
		try {
			score = this.scoringStrategyService.execute(contact).getRssiScore();
		} catch (RobertScoringException e) {
			fail(FAIL_EXCEPTION);
		}

		log.info(String.format("One early, one late: %f", score));
		assertTrue(score < 4.0 && score > 3.9);
	}

	@Test
	public void testScoreRiskOneMessageEarlyNotAtRisk() {
		List<HelloMessageDetail> messages = new ArrayList<>();
		messages.add(HelloMessageDetail.builder().timeCollectedOnDevice(this.randomReferenceEpochStartTime + 5L)
				.rssiCalibrated(-15).build());

		Contact contact = Contact.builder().messageDetails(messages).build();

		Double score = null;
		try {
			score = this.scoringStrategyService.execute(contact).getRssiScore();
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
				.timeCollectedOnDevice(this.randomReferenceEpochStartTime + (900L - 5L)).rssiCalibrated(-78).build());

		Contact contact = Contact.builder().messageDetails(messages).build();

		Double score = null;
		try {
			score = this.scoringStrategyService.execute(contact).getRssiScore();
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
				.timeCollectedOnDevice(this.randomReferenceEpochStartTime + (900 / 2 + 5)).rssiCalibrated(-78).build());

		Contact contact = Contact.builder().messageDetails(messages).build();

		Double score = null;
		try {
			score = this.scoringStrategyService.execute(contact).getRssiScore();
		} catch (RobertScoringException e) {
			fail(FAIL_EXCEPTION);
		}

		log.info(String.format("Just after half way of epoch: %f", score));
		assertTrue(score < 0.5);
	}

	@Test
	public void testScoreRiskOneMessageJustBeforeHalfNotAtRisk() {
		List<HelloMessageDetail> messages = new ArrayList<>();
		messages.add(HelloMessageDetail.builder()
				.timeCollectedOnDevice(this.randomReferenceEpochStartTime + (900 / 2 + 5)).rssiCalibrated(-78).build());

		Contact contact = Contact.builder().messageDetails(messages).build();

		Double score = null;
		try {
			score = this.scoringStrategyService.execute(contact).getRssiScore();
		} catch (RobertScoringException e) {
			fail(FAIL_EXCEPTION);
		}

		log.info(String.format("Just before half way of epoch: %f", score));
		assertTrue(score < 0.5);
	}

	@Test
	public void testScoreRiskNoMessagesFail() {
		Contact contact = Contact.builder().messageDetails(new ArrayList<>()).build();

		RobertScoringException thrown = assertThrows(RobertScoringException.class,
				() -> this.scoringStrategyService.execute(contact),
				"Expected scoring function to throw, but it didn't");

		assertNotEquals(null, thrown);
	}
}
