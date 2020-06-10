package test.fr.gouv.stopc.robertserver.batch.processor;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.security.Key;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.Random;

import com.google.protobuf.ByteString;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetInfoFromHelloMessageResponse;
import fr.gouv.stopc.robert.server.crypto.structure.CryptoAES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESECB;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoSkinny64;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.annotation.DirtiesContext.ClassMode;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetInfoFromHelloMessageResponse;
import fr.gouv.stopc.robert.server.batch.RobertServerBatchApplication;
import fr.gouv.stopc.robert.server.batch.processor.ContactProcessor;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESOFB;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoSkinny64;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.HelloMessageDetail;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.ContactService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import lombok.extern.slf4j.Slf4j;

import javax.crypto.spec.SecretKeySpec;

@Slf4j
@DirtiesContext(classMode = ClassMode.AFTER_EACH_TEST_METHOD)
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = { RobertServerBatchApplication.class })
@TestPropertySource("classpath:application.properties")
public class ContactProcessorTest {

	@Autowired
	private ContactService contactService;

	@Autowired
	private CryptoService cryptoService;

	@Autowired
	private IServerConfigurationService serverConfigurationService;

	@Autowired
	private IRegistrationService registrationService;

	@MockBean
	private ICryptoServerGrpcClient cryptoServerClient;

	private final static String SHOULD_NOT_FAIL = "It should not fail";

	private ContactProcessor contactProcessor;

	private Optional<Registration> registration;

	@Autowired
	private ScoringStrategyService scoringStrategyService;

	@Autowired
    private PropertyLoader propertyLoader;

	private byte[] serverKey;
	private Key federationKey;
	private byte countryCode;

	private long epochDuration;
	private long serviceTimeStart;

	private byte[] generateKey(int sizeInBytes) {
		byte[] data = new byte[sizeInBytes];
		new SecureRandom().nextBytes(data);
		return data;
	}

	@BeforeEach
	public void before() {
		this.serverKey = this.generateKey(24);
		this.federationKey = new SecretKeySpec(this.generateKey(32), CryptoAES.AES_ENCRYPTION_KEY_SCHEME);
		this.countryCode = this.serverConfigurationService.getServerCountryCode();

		this.contactProcessor = new ContactProcessor(
				serverConfigurationService,
				registrationService,
				contactService,
				cryptoServerClient,
				scoringStrategyService,
				propertyLoader
				);

		this.epochDuration = this.serverConfigurationService.getEpochDurationSecs();
		this.serviceTimeStart = this.serverConfigurationService.getServiceTimeStart();
	}

	@Test
	public void testProcessContactWithABadEncryptedCountryCodeFails() {
		this.registration = this.registrationService.createRegistration(generateIdA());
		assertTrue(this.registration.isPresent());

		try {
			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());
			final int currentEpochId = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime);
			byte[] ebid = this.cryptoService.generateEBID(new CryptoSkinny64(serverKey), currentEpochId, this.generateIdA());

			// Create a fake Encrypted Country Code (ECC)
			byte[] encryptedCountryCode = new byte[] { (byte) 0xff };
			Contact contact = Contact.builder()
					.ebid(new byte[8])
					.ecc(encryptedCountryCode)
					.messageDetails(generateHelloMessagesFor(ebid, encryptedCountryCode, currentEpochId))
					.build();

			this.contactService.saveContacts(Arrays.asList(contact));

			assertFalse(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertEquals(1, this.contactService.findAll().size());
			// When
			Contact processedContact = this.contactProcessor.process(contact);

			// Then
			assertNull(processedContact);
			assertTrue(CollectionUtils.isEmpty(this.contactService.findAll()));

		} catch (Exception e) {
			log.error(e.getMessage());
			fail(SHOULD_NOT_FAIL);
		}
	}

	@Test
	public void testProcessContactWitNoMessagesFails() {
		this.registration = this.registrationService.createRegistration(generateIdA());
		assertTrue(this.registration.isPresent());

		try {
			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());
			final int currentEpochId = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime);
			byte[] ebid = this.cryptoService.generateEBID(new CryptoSkinny64(serverKey), currentEpochId, this.generateIdA());
			byte[] encryptedCountryCode = this.cryptoService.encryptCountryCode(new CryptoAESECB(federationKey), ebid, countryCode);
			Contact contact = Contact.builder()
					.ebid(new byte[8])
					.ecc(encryptedCountryCode)
					.messageDetails(new ArrayList<>())
					.build();

			this.contactService.saveContacts(Arrays.asList(contact));

			assertFalse(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertEquals(1, this.contactService.findAll().size());
			// When
			Contact processedContact = this.contactProcessor.process(contact);

			// Then
			assertNull(processedContact);
			assertTrue(CollectionUtils.isEmpty(this.contactService.findAll()));
			verify(this.cryptoServerClient, never()).getInfoFromHelloMessage(any()); // must be called once only
		} catch (Exception e) {
			log.error(e.getMessage());
			fail(SHOULD_NOT_FAIL);
		}
	}

	@Test
	public void testProcessContactWhenRegistrationDoesNotExistFails() {
		this.registration = this.registrationService.createRegistration(generateIdA());
		assertTrue(this.registration.isPresent());

		try {
			// Given
			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());

			final int currentEpochId = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime);

			byte[] ebid = this.cryptoService.generateEBID(new CryptoSkinny64(serverKey), currentEpochId, this.generateIdA());
			byte[] encryptedCountryCode = this.cryptoService.encryptCountryCode(new CryptoAESECB(federationKey), ebid, countryCode);

			byte[] time = new byte[2];

			byte[] timeOfDevice = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(currentTime + 1), 4, timeOfDevice, 0, 4);

			byte[] timeHelloB = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(currentTime), 4, timeHelloB, 0, 4);

			byte[] helloMessage = new byte[16];
			System.arraycopy(encryptedCountryCode, 0, helloMessage, 0, encryptedCountryCode.length);
			System.arraycopy(ebid, 0, helloMessage, encryptedCountryCode.length, ebid.length);
			System.arraycopy(time, 0, helloMessage, encryptedCountryCode.length + ebid.length, time.length);

			byte[] decryptedEbid = this.cryptoService.decryptEBID(new CryptoSkinny64(serverKey), ebid);
			when(this.cryptoServerClient.getInfoFromHelloMessage(any())).thenReturn(Optional.empty());

			Contact contact = Contact.builder()
					.ebid(ebid)
					.ecc(encryptedCountryCode)
					.messageDetails(generateHelloMessagesFor(ebid, encryptedCountryCode, currentEpochId))
					.build();

			this.contactService.saveContacts(Arrays.asList(contact));

			assertFalse(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertEquals(1, this.contactService.findAll().size());

			this.registrationService.delete(this.registration.get());

			// When
			Contact processedContact = this.contactProcessor.process(contact);

			// Then
			assertNull(processedContact);
			assertTrue(CollectionUtils.isEmpty(this.contactService.findAll()));
			verify(this.cryptoServerClient).getInfoFromHelloMessage(any()); // must be called once only

		} catch (Exception e) {
			fail(SHOULD_NOT_FAIL);
		}
	}

	@Test
	public void testProcessTwoContactsWithAggregatedScoreAboveThresholdYieldsRiskSucceeds() {
		try {
			// Given
			this.registration = this.registrationService.createRegistration(generateIdA());
			assertTrue(this.registration.isPresent());

			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());

			final int currentEpochId = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime);

			final int previousEpoch = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime - 900);

			// Setup id with an existing score below threshold
			Registration registrationWithEE = this.registration.get();
			registrationWithEE.setExposedEpochs(Arrays.asList(
					EpochExposition.builder()
					.epochId(previousEpoch)
					.expositionScores(Arrays.asList(3.0))
					.build(), 
					EpochExposition.builder()
					.epochId(currentEpochId)
					.expositionScores(Arrays.asList(4.3))
					.build()));

			this.registrationService.saveRegistration(registrationWithEE);

			byte[] ebid = this.cryptoService.generateEBID(new CryptoSkinny64(serverKey), currentEpochId,
					this.registration.get().getPermanentIdentifier());

			byte[] encryptedCountryCode = this.cryptoService.encryptCountryCode(new CryptoAESECB(federationKey), ebid, countryCode);

			byte[] decryptedEbid = this.cryptoService.decryptEBID(new CryptoSkinny64(serverKey), ebid);

			when(this.cryptoServerClient.getInfoFromHelloMessage(any())).thenReturn(Optional.of(
					GetInfoFromHelloMessageResponse.newBuilder()
							.setIdA(ByteString.copyFrom(this.registration.get().getPermanentIdentifier()))
							.setCountryCode(ByteString.copyFrom(new byte[] { this.serverConfigurationService.getServerCountryCode() }))
							.setEpochId(currentEpochId)
							.build()));

			// Create HELLO message that will make total score exceed threshold
			long t = currentEpochId * this.epochDuration + this.serviceTimeStart + 15L;
			List<HelloMessageDetail> messages = new ArrayList<>();
			messages.add(generateHelloMessageFor(ebid, encryptedCountryCode, t, -78));
			messages.add(generateHelloMessageFor(ebid, encryptedCountryCode, t + 165L, -50));
			messages.add(generateHelloMessageFor(ebid, encryptedCountryCode, t + 300L, -35));

			Contact contact = Contact.builder()
					.ebid(ebid)
					.ecc(encryptedCountryCode)
					.messageDetails(messages)
					.build();

			this.contactService.saveContacts(Arrays.asList(contact));

			assertFalse(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertEquals(1, this.contactService.findAll().size());

			// When
			Contact processedContact = this.contactProcessor.process(contact);

			// Then
			assertNull(processedContact);
			assertTrue(CollectionUtils.isEmpty(this.contactService.findAll()));
			Optional<Registration> expectedRegistration = this.registrationService
					.findById(registrationWithEE.getPermanentIdentifier());
			assertTrue(expectedRegistration.isPresent());
			assertFalse(CollectionUtils.isEmpty(expectedRegistration.get().getExposedEpochs()));
			assertTrue(expectedRegistration.get().getExposedEpochs().size() == 2);
			assertRiskThresholdExceededBasedOnConfiguration(expectedRegistration.get());
			verify(this.cryptoServerClient, times(messages.size())).getInfoFromHelloMessage(any());

		} catch (Exception e) {
			fail(SHOULD_NOT_FAIL);
		}
	}

	@Test
	public void testProcessTwoContactsWithAggregatedScoreBelowThresholdDoesNotYieldRiskSucceeds() {
		try {
			// Given
			this.registration = this.registrationService.createRegistration(generateIdA());
			assertTrue(this.registration.isPresent());

			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());

			final int currentEpochId = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime);

			final int previousEpoch = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime - 900);

			// Setup id with an existing score below threshold
			Registration registrationWithEE = this.registration.get();
			registrationWithEE.setExposedEpochs(Arrays.asList(EpochExposition.builder()
					.epochId(previousEpoch)
					.expositionScores(Arrays.asList(1.0))
					.build(),
					EpochExposition.builder()
					.epochId(currentEpochId)
					.expositionScores(Arrays.asList(2.3))
					.build()));

			this.registrationService.saveRegistration(registrationWithEE);

			byte[] ebid = this.cryptoService.generateEBID(new CryptoSkinny64(serverKey), currentEpochId,
					this.registration.get().getPermanentIdentifier());
			byte[] encryptedCountryCode = this.cryptoService.encryptCountryCode(new CryptoAESECB(federationKey), ebid, countryCode);
			byte[] decryptedEbid = this.cryptoService.decryptEBID(new CryptoSkinny64(serverKey), ebid);

			when(this.cryptoServerClient.getInfoFromHelloMessage(any())).thenReturn(Optional.of(
					GetInfoFromHelloMessageResponse.newBuilder()
							.setIdA(ByteString.copyFrom(this.registration.get().getPermanentIdentifier()))
							.setCountryCode(ByteString.copyFrom(new byte[] { this.serverConfigurationService.getServerCountryCode() }))
							.setEpochId(currentEpochId)
							.build()));

			// Create HELLO message that will not make total score exceed threshold
			long t = currentEpochId * this.epochDuration + this.serviceTimeStart + 15L;
			List<HelloMessageDetail> messages = new ArrayList<>();
			messages.add(generateHelloMessageFor(ebid, encryptedCountryCode, t, -78));
			messages.add(generateHelloMessageFor(ebid, encryptedCountryCode, t + 165L, -50));

			Contact contact = Contact.builder()
					.ebid(ebid)
					.ecc(encryptedCountryCode)
					.messageDetails(messages)
					.build();

			this.contactService.saveContacts(Arrays.asList(contact));

			assertFalse(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertEquals(1, this.contactService.findAll().size());

			// When
			Contact processedContact = this.contactProcessor.process(contact);

			// Then
			assertNull(processedContact);
			assertTrue(CollectionUtils.isEmpty(this.contactService.findAll()));
			Optional<Registration> expectedRegistration = this.registrationService
					.findById(registrationWithEE.getPermanentIdentifier());
			assertTrue(expectedRegistration.isPresent());
			assertFalse(CollectionUtils.isEmpty(expectedRegistration.get().getExposedEpochs()));
			assertTrue(expectedRegistration.get().getExposedEpochs().size() == 2);

			assertRiskThresholdExceededBasedOnConfiguration(expectedRegistration.get());

			verify(this.cryptoServerClient, times(messages.size())).getInfoFromHelloMessage(any());

		} catch (Exception e) {
			fail(SHOULD_NOT_FAIL);
		}
	}

	@Test
	public void testProcessContactWhenHelloMessageTimestampIsExceededFails() {

		try {

			// Given
			this.registration = this.registrationService.createRegistration(generateIdA());
			assertTrue(this.registration.isPresent());

			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());

			final int currentEpochId = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime);

			byte[] ebid = this.cryptoService.generateEBID(new CryptoSkinny64(serverKey), currentEpochId,
					this.registration.get().getPermanentIdentifier());

			byte[] encryptedCountryCode = this.cryptoService.encryptCountryCode(new CryptoAESECB(federationKey), ebid, countryCode);
			byte[] time = new byte[2];

			byte[] timeOfDevice = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(currentTime + this.propertyLoader.getHelloMessageTimeStampTolerance() + 1), 4, timeOfDevice, 0, 4);

			byte[] timeHelloB = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(currentTime), 4, timeHelloB, 0, 4);

			timeHelloB[0] = (byte) (timeHelloB[0] & 0x00);
			timeHelloB[1] = (byte) (timeHelloB[1] & 0x00);

			int timeReceived = ByteUtils.bytesToInt(timeOfDevice);
			int timeHello = ByteUtils.bytesToInt(timeHelloB);

			byte[] helloMessage = new byte[16];
			System.arraycopy(encryptedCountryCode, 0, helloMessage, 0, encryptedCountryCode.length);
			System.arraycopy(ebid, 0, helloMessage, encryptedCountryCode.length, ebid.length);
			System.arraycopy(time, 0, helloMessage, encryptedCountryCode.length + ebid.length, time.length);

			byte[] decryptedEbid = this.cryptoService.decryptEBID(new CryptoSkinny64(serverKey), ebid);

			when(this.cryptoServerClient.getInfoFromHelloMessage(any())).thenReturn(Optional.of(
					GetInfoFromHelloMessageResponse.newBuilder()
							.setIdA(ByteString.copyFrom(this.registration.get().getPermanentIdentifier()))
							.setCountryCode(ByteString.copyFrom(new byte[] { this.serverConfigurationService.getServerCountryCode() }))
							.setEpochId(currentEpochId)
							.build()));

			byte[] mac = this.cryptoService
					.generateMACHello(new CryptoHMACSHA256(getKeyMacFor(this.registration.get().getPermanentIdentifier())), helloMessage);

			HelloMessageDetail helloMessageDetail = HelloMessageDetail.builder()
					.mac(mac)
					.timeFromHelloMessage(timeHello)
					.timeCollectedOnDevice(Integer.toUnsignedLong(timeReceived))
					.rssiCalibrated(-70)
					.build();

			Contact contact = Contact.builder()
					.ebid(ebid)
					.ecc(encryptedCountryCode)
					.messageDetails(Arrays.asList(helloMessageDetail))
					.build();

			this.contactService.saveContacts(Arrays.asList(contact));

			assertFalse(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertEquals(1, this.contactService.findAll().size());

			// When
			Contact processedContact = this.contactProcessor.process(contact);

			// Then
			assertNull(processedContact);
			assertTrue(CollectionUtils.isEmpty(this.contactService.findAll()));

			verify(this.cryptoServerClient, times(contact.getMessageDetails().size())).getInfoFromHelloMessage(any());

			assertFalse(helloMessageDetail.toString().contains(Arrays.toString(mac)));
			assertFalse(helloMessageDetail.toString().contains(Integer.toString(timeHello)));
			assertFalse(helloMessageDetail.toString().contains(Long.toString(Integer.toUnsignedLong(timeReceived))));
		} catch (Exception e) {
			log.error(e.getMessage());
			fail(SHOULD_NOT_FAIL);
		}
	}

	/*
	 * Reject HELLO messages if the epoch embedded in the EBID does not match the
	 * one accompanying the HELLO message (timestamp when received on device)
	 */
	@Test
	public void testProcessContactWhenTheEpochsAreDifferentFails() {

		try {

			// Given
			this.registration = this.registrationService.createRegistration(generateIdA());
			assertTrue(this.registration.isPresent());

			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());

			final int currentEpochId = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime);

			byte[] ebid = this.cryptoService.generateEBID(new CryptoSkinny64(serverKey), currentEpochId,
					this.registration.get().getPermanentIdentifier());
			byte[] encryptedCountryCode = this.cryptoService.encryptCountryCode(new CryptoAESECB(federationKey), ebid, countryCode);
			byte[] time = new byte[2];

			// Get timestamp on 16 bits
			System.arraycopy(ByteUtils.longToBytes(currentTime), 6, time, 0, 2);

			// The timestamps are coherent between each other but not with the epoch embedded in the EBID
			byte[] timeOfDevice = new byte[4];
			long tsDevice = currentTime + this.serverConfigurationService.getEpochDurationSecs() * 2 + 2;
			System.arraycopy(ByteUtils.longToBytes(tsDevice), 4, timeOfDevice, 0, 4);

			byte[] timeHelloB = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(tsDevice - 1), 4, timeHelloB, 0, 4);

			timeHelloB[0] = (byte) (timeHelloB[0] & 0x00);
			timeHelloB[1] = (byte) (timeHelloB[1] & 0x00);

			int timeReceived = ByteUtils.bytesToInt(timeOfDevice);
			int timeHello = ByteUtils.bytesToInt(timeHelloB);

			byte[] helloMessage = new byte[16];
			System.arraycopy(encryptedCountryCode, 0, helloMessage, 0, encryptedCountryCode.length);
			System.arraycopy(ebid, 0, helloMessage, encryptedCountryCode.length, ebid.length);
			System.arraycopy(time, 0, helloMessage, encryptedCountryCode.length + ebid.length, time.length);

			byte[] decryptedEbid = this.cryptoService.decryptEBID(new CryptoSkinny64(serverKey), ebid);

			when(this.cryptoServerClient.getInfoFromHelloMessage(any())).thenReturn(Optional.of(
					GetInfoFromHelloMessageResponse.newBuilder()
							.setIdA(ByteString.copyFrom(this.registration.get().getPermanentIdentifier()))
							.setCountryCode(ByteString.copyFrom(new byte[] { this.serverConfigurationService.getServerCountryCode() }))
							.setEpochId(currentEpochId)
							.build()));

			byte[] mac = this.cryptoService
					.generateMACHello(new CryptoHMACSHA256(getKeyMacFor(this.registration.get().getPermanentIdentifier())), helloMessage);

			HelloMessageDetail helloMessageDetail = HelloMessageDetail.builder()
					.mac(mac)
					.timeFromHelloMessage(timeHello)
					.timeCollectedOnDevice(Integer.toUnsignedLong(timeReceived))
					.rssiCalibrated(-70)
					.build();

			Contact contact = Contact.builder()
					.ebid(ebid)
					.ecc(encryptedCountryCode)
					.messageDetails(Arrays.asList(helloMessageDetail))
					.build();

			this.contactService.saveContacts(Arrays.asList(contact));

			assertFalse(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertEquals(1, this.contactService.findAll().size());

			// When
			Contact processedContact = this.contactProcessor.process(contact);

			// Then
			assertNull(processedContact);
			assertTrue(CollectionUtils.isEmpty(this.contactService.findAll()));

			verify(this.cryptoServerClient).getInfoFromHelloMessage(any());

		} catch (Exception e) {
			fail(SHOULD_NOT_FAIL);
		}
	}

	@Test
	public void testProcessContactWhenTheMacIsInvalidFails() {

		try {
			// Given
			this.registration = this.registrationService.createRegistration(generateIdA());
			assertTrue(this.registration.isPresent());

			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());

			final int currentEpochId = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime);

			byte[] ebid = this.cryptoService.generateEBID(
					new CryptoSkinny64(serverKey),
					currentEpochId,
					this.registration.get().getPermanentIdentifier());
			byte[] encryptedCountryCode = this.cryptoService.encryptCountryCode(
					new CryptoAESECB(federationKey),
					ebid,
					countryCode);
			byte[] time = new byte[2];

			// Get timestamp on sixteen bits
			System.arraycopy(ByteUtils.longToBytes(currentTime + 902), 6, time, 0, 2);

			byte[] timeOfDevice = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(currentTime), 4, timeOfDevice, 0, 4);

			byte[] timeHelloB = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(currentTime), 4, timeHelloB, 0, 4);

			timeHelloB[0] = (byte) (timeHelloB[0] & 0x00);
			timeHelloB[1] = (byte) (timeHelloB[1] & 0x00);

			int timeReceived = ByteUtils.bytesToInt(timeOfDevice);
			int timeHello = ByteUtils.bytesToInt(timeHelloB);

			byte[] helloMessage = new byte[16];
			System.arraycopy(encryptedCountryCode, 0, helloMessage, 0, encryptedCountryCode.length);
			System.arraycopy(ebid, 0, helloMessage, encryptedCountryCode.length, ebid.length);
			System.arraycopy(time, 0, helloMessage, encryptedCountryCode.length + ebid.length, time.length);

			byte[] decryptedEbid = this.cryptoService.decryptEBID(new CryptoSkinny64(serverKey), ebid);

			when(this.cryptoServerClient.getInfoFromHelloMessage(any())).thenReturn(Optional.empty());

			byte[] mac = this.cryptoService
					.generateMACHello(new CryptoHMACSHA256(getKeyMacFor(this.registration.get().getPermanentIdentifier())), helloMessage);

			HelloMessageDetail helloMessageDetail = HelloMessageDetail.builder()
					.mac(mac)
					.timeFromHelloMessage(timeHello)
					.timeCollectedOnDevice(Integer.toUnsignedLong(timeReceived))
					.rssiCalibrated(-70)
					.build();

			Contact contact = Contact.builder()
					.ebid(ebid)
					.ecc(encryptedCountryCode)
					.messageDetails(Arrays.asList(helloMessageDetail))
					.build();

			this.contactService.saveContacts(Arrays.asList(contact));

			assertFalse(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertEquals(1, this.contactService.findAll().size());

			// When
			Contact processedContact = this.contactProcessor.process(contact);

			// Then
			assertNull(processedContact);
			assertTrue(CollectionUtils.isEmpty(this.contactService.findAll()));

			verify(this.cryptoServerClient).getInfoFromHelloMessage(any());

		} catch (Exception e) {
			fail(SHOULD_NOT_FAIL);
		}
	}

	@Test
	public void testProcessContactWhenTheContactIsValidSucceeds() {
		try {
			// Given
			this.registration = this.registrationService.createRegistration(generateIdA());
			assertTrue(this.registration.isPresent());

			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());

			final int currentEpochId = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime);

			final int previousEpoch = TimeUtils.getNumberOfEpochsBetween(
					tpstStart,
					currentTime - this.serverConfigurationService.getEpochDurationSecs());

			Registration registrationWithEE = this.registration.get();
			registrationWithEE.setExposedEpochs(Arrays.asList(EpochExposition.builder()
					.epochId(previousEpoch)
					.expositionScores(Arrays.asList(0.0))
					.build(),
					EpochExposition.builder()
					.epochId(currentEpochId)
					.expositionScores(Arrays.asList(0.0))
					.build()));

			int nbOfExposedEpochs = registrationWithEE.getExposedEpochs().size();

			this.registrationService.saveRegistration(registrationWithEE);

			byte[] ebid = this.cryptoService.generateEBID(
					new CryptoSkinny64(serverKey),
					currentEpochId,
					this.registration.get().getPermanentIdentifier());
			byte[] encryptedCountryCode = this.cryptoService.encryptCountryCode(
					new CryptoAESECB(federationKey),
					ebid,
					countryCode);
			byte[] time = new byte[2];

			byte[] decryptedEbid = this.cryptoService.decryptEBID(new CryptoSkinny64(serverKey), ebid);

			// Get timestamp on sixteen bits
			System.arraycopy(ByteUtils.longToBytes(currentTime), 6, time, 0, 2);

			byte[] timeOfDevice = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(currentTime + 1), 4, timeOfDevice, 0, 4);

			byte[] timeHelloB = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(currentTime), 4, timeHelloB, 0, 4);

			timeHelloB[0] = (byte) (timeHelloB[0] & 0x00);
			timeHelloB[1] = (byte) (timeHelloB[1] & 0x00);

			int timeReceived = ByteUtils.bytesToInt(timeOfDevice);
			int timeHello = ByteUtils.bytesToInt(timeHelloB);

			byte[] helloMessage = new byte[16];
			System.arraycopy(encryptedCountryCode, 0, helloMessage, 0, encryptedCountryCode.length);
			System.arraycopy(ebid, 0, helloMessage, encryptedCountryCode.length, ebid.length);
			System.arraycopy(time, 0, helloMessage, encryptedCountryCode.length + ebid.length, time.length);

			byte[] mac = this.cryptoService
					.generateMACHello(new CryptoHMACSHA256(getKeyMacFor(this.registration.get().getPermanentIdentifier())), helloMessage);

			HelloMessageDetail helloMessageDetail = HelloMessageDetail.builder()
					.mac(mac)
					.timeFromHelloMessage(timeHello)
					.timeCollectedOnDevice(Integer.toUnsignedLong(timeReceived))
					.rssiCalibrated(-70)
					.build();

			Contact contact = Contact.builder()
					.ebid(ebid)
					.ecc(encryptedCountryCode)
					.messageDetails(Arrays.asList(helloMessageDetail))
					.build();

			this.contactService.saveContacts(Arrays.asList(contact));

			when(this.cryptoServerClient.getInfoFromHelloMessage(any())).thenReturn(Optional.of(
					GetInfoFromHelloMessageResponse.newBuilder()
							.setIdA(ByteString.copyFrom(this.registration.get().getPermanentIdentifier()))
							.setCountryCode(ByteString.copyFrom(new byte[] { this.serverConfigurationService.getServerCountryCode() }))
							.setEpochId(currentEpochId)
							.build()));

			assertFalse(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertEquals(1, this.contactService.findAll().size());

			// When
			Contact processedContact = this.contactProcessor.process(contact);

			// Then
			assertNull(processedContact);
			assertTrue(CollectionUtils.isEmpty(this.contactService.findAll()));
			Optional<Registration> expectedRegistration = this.registrationService
					.findById(registrationWithEE.getPermanentIdentifier());
			assertTrue(expectedRegistration.isPresent());

			assertFalse(CollectionUtils.isEmpty(expectedRegistration.get().getExposedEpochs()));
			assertEquals(nbOfExposedEpochs, expectedRegistration.get().getExposedEpochs().size());

			assertRiskThresholdExceededBasedOnConfiguration(expectedRegistration.get());

			verify(this.cryptoServerClient, times(contact.getMessageDetails().size())).getInfoFromHelloMessage(any());

		} catch (Exception e) {
			fail(SHOULD_NOT_FAIL);
		}
	}

	@Test
	public void testProcessContactWhenTheRegistrationHasTooOldExposedEpochsFails() {

		try {
			// Given
			this.registration = this.registrationService.createRegistration(generateIdA());
			assertTrue(this.registration.isPresent());

			final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
			final long currentTime = TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime());

			final int currentEpochId = TimeUtils.getNumberOfEpochsBetween(tpstStart, currentTime);
			int val = (this.propertyLoader.getContagiousPeriod() * 24 * 3600)
					/ this.serverConfigurationService.getEpochDurationSecs();
			val++;
			int tooOldEpochId = currentEpochId - val;
			Registration registrationWithEE = this.registration.get();
			registrationWithEE.setExposedEpochs(Arrays.asList(EpochExposition
					.builder()
					.epochId(tooOldEpochId)
					.expositionScores(Arrays.asList(0.0))
					.build()));

			int nbOfExposedEpochsBefore = registrationWithEE.getExposedEpochs().size();

			this.registrationService.saveRegistration(registrationWithEE);

			byte[] ebid = this.cryptoService.generateEBID(new CryptoSkinny64(serverKey), currentEpochId,
					this.registration.get().getPermanentIdentifier());
			byte[] encryptedCountryCode = this.cryptoService.encryptCountryCode(new CryptoAESECB(federationKey), ebid, countryCode);
			byte[] time = new byte[2];

			// Get timestamp on 16 bits
			System.arraycopy(ByteUtils.longToBytes(currentTime), 6, time, 0, 2);

			byte[] timeOfDevice = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(currentTime + 1), 4, timeOfDevice, 0, 4);

			byte[] timeHelloB = new byte[4];
			System.arraycopy(ByteUtils.longToBytes(currentTime), 4, timeHelloB, 0, 4);

			timeHelloB[0] = (byte) (timeHelloB[0] & 0x00);
			timeHelloB[1] = (byte) (timeHelloB[1] & 0x00);

			int timeReceived = ByteUtils.bytesToInt(timeOfDevice);
			int timeHello = ByteUtils.bytesToInt(timeHelloB);

			byte[] helloMessage = new byte[16];
			System.arraycopy(encryptedCountryCode, 0, helloMessage, 0, encryptedCountryCode.length);
			System.arraycopy(ebid, 0, helloMessage, encryptedCountryCode.length, ebid.length);
			System.arraycopy(time, 0, helloMessage, encryptedCountryCode.length + ebid.length, time.length);

			byte[] decryptedEbid = this.cryptoService.decryptEBID(new CryptoSkinny64(serverKey), ebid);

			when(this.cryptoServerClient.getInfoFromHelloMessage(any())).thenReturn(Optional.of(
					GetInfoFromHelloMessageResponse.newBuilder()
							.setIdA(ByteString.copyFrom(this.registration.get().getPermanentIdentifier()))
							.setCountryCode(ByteString.copyFrom(new byte[] { this.serverConfigurationService.getServerCountryCode() }))
							.setEpochId(currentEpochId)
							.build()));

			byte[] mac = this.cryptoService
					.generateMACHello(new CryptoHMACSHA256(getKeyMacFor(this.registration.get().getPermanentIdentifier())), helloMessage);

			HelloMessageDetail helloMessageDetail = HelloMessageDetail.builder()
					.mac(mac)
					.timeFromHelloMessage(timeHello)
					.timeCollectedOnDevice(Integer.toUnsignedLong(timeReceived))
					.rssiCalibrated(-70)
					.build();

			Contact contact = Contact.builder()
					.ebid(ebid)
					.ecc(encryptedCountryCode)
					.messageDetails(Arrays.asList(helloMessageDetail))
					.build();

			this.contactService.saveContacts(Arrays.asList(contact));

			assertFalse(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertEquals(1, this.contactService.findAll().size());

			// When
			Contact processedContact = this.contactProcessor.process(contact);

			// Then
			Optional<Registration> expectedRegistration = this.registrationService
					.findById(registrationWithEE.getPermanentIdentifier());
			assertNull(processedContact);
			assertTrue(CollectionUtils.isEmpty(this.contactService.findAll()));
			assertTrue(expectedRegistration.isPresent());
			assertFalse(CollectionUtils.isEmpty(expectedRegistration.get().getExposedEpochs()));
			assertEquals(expectedRegistration.get().getExposedEpochs().size(), nbOfExposedEpochsBefore - 1 + 1);

			assertRiskThresholdExceededBasedOnConfiguration(expectedRegistration.get());

			verify(this.cryptoServerClient, times(contact.getMessageDetails().size())).getInfoFromHelloMessage(any());

		} catch (Exception e) {
			fail(SHOULD_NOT_FAIL);
		}
	}

	@AfterEach
	public void afterAll() {
		this.contactService.deleteAll();
		this.registrationService.deleteAll();
	}

	private byte[] generateIdA() {
		return generateRandomByteArrayOfSize(5);
	}

	private byte[] generateRandomByteArrayOfSize(int size) {
		byte[] rndBytes = new byte[size];
		SecureRandom sr = new SecureRandom();
		sr.nextBytes(rndBytes);

		return rndBytes;
	}

	private HelloMessageDetail generateHelloMessageFor(byte[] ebid, byte[] encryptedCountryCode, long t, int rssi) throws Exception {
		byte[] time = new byte[2];

		// Get timestamp on sixteen bits
		System.arraycopy(ByteUtils.longToBytes(t), 6, time, 0, 2);

		byte[] timeOfDevice = new byte[4];
		System.arraycopy(ByteUtils.longToBytes(t + 1), 4, timeOfDevice, 0, 4);

		byte[] timeHelloB = new byte[4];
		System.arraycopy(ByteUtils.longToBytes(t), 4, timeHelloB, 0, 4);

		// Clear out the first two bytes
		timeHelloB[0] = (byte) (timeHelloB[0] & 0x00);
		timeHelloB[1] = (byte) (timeHelloB[1] & 0x00);

		int timeReceived = ByteUtils.bytesToInt(timeOfDevice);
		int timeHello = ByteUtils.bytesToInt(timeHelloB);

		byte[] helloMessage = new byte[16];
		System.arraycopy(encryptedCountryCode, 0, helloMessage, 0, encryptedCountryCode.length);
		System.arraycopy(ebid, 0, helloMessage, encryptedCountryCode.length, ebid.length);
		System.arraycopy(time, 0, helloMessage, encryptedCountryCode.length + ebid.length, time.length);

		byte[] mac = this.cryptoService
				.generateMACHello(new CryptoHMACSHA256(getKeyMacFor(this.registration.get().getPermanentIdentifier())), helloMessage);

		return HelloMessageDetail.builder()
				.timeFromHelloMessage(timeHello)
				.timeCollectedOnDevice(Integer.toUnsignedLong(timeReceived))
				.rssiCalibrated(rssi)
				.mac(mac)
				.build();
	}

	private byte[] getKeyMacFor(byte[] idA) {
		return this.generateRandomByteArrayOfSize(32);
	}

	private List<HelloMessageDetail> generateHelloMessagesFor(byte[] ebid, byte[] encryptedCountryCode, int currentEpoch) throws Exception {
		List<HelloMessageDetail> messages = new ArrayList<>();

		Random random = new Random();
		int nbOfHellos = random.nextInt(5) + 1;
		long t = currentEpoch * this.epochDuration + this.serviceTimeStart + 15L;

		for (int i = 0; i < nbOfHellos; i++) {
			int rssi = -30 - random.nextInt(90);
			t += random.nextInt(30) + 5;
			messages.add(generateHelloMessageFor(ebid, encryptedCountryCode, t, rssi));
		}

		return messages;
	}

	private void assertRiskThresholdExceededBasedOnConfiguration(Registration expectedRegistration) {
		boolean atRisk = expectedRegistration.isAtRisk();
		if (this.propertyLoader.getRiskThreshold() >= sumRiskScores(expectedRegistration.getExposedEpochs())) {
			assertFalse(atRisk);
		} else {
			assertTrue(atRisk);
		}
	}

	private Double sumRiskScores(List<EpochExposition> epochExpositions) {
		return epochExpositions.stream()
				.map(EpochExposition::getExpositionScores)
				.map(item -> item.stream().mapToDouble(Double::doubleValue).sum())
				.reduce(0.0, (a,b) -> a + b);
	}
}
