package test.fr.gouv.stopc.robertserver.ws;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import java.net.URI;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

import javax.crypto.KeyGenerator;
import javax.inject.Inject;

import com.google.protobuf.ByteString;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromAuthResponse;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoSkinny64;
import org.bson.internal.Base64;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.ArgumentMatchers;
import org.mockito.MockitoAnnotations;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.annotation.DirtiesContext.ClassMode;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.util.UriComponentsBuilder;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.impl.RegistrationService;
import fr.gouv.stopc.robertserver.ws.RobertServerWsRestApplication;
import fr.gouv.stopc.robertserver.ws.dto.DeleteHistoryResponseDto;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.utils.UriConstants;
import fr.gouv.stopc.robertserver.ws.vo.DeleteHistoryRequestVo;
import lombok.extern.slf4j.Slf4j;

@DirtiesContext(classMode = ClassMode.AFTER_EACH_TEST_METHOD)
@ExtendWith(SpringExtension.class)
@SpringBootTest(classes = {
		RobertServerWsRestApplication.class }, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource("classpath:application.properties")
@Slf4j
public class DeleteHistoryControllerWsRestTest {
	@Value("${controller.path.prefix}")
	private String pathPrefix;

	@Inject
	private TestRestTemplate restTemplate;

	HttpEntity<DeleteHistoryRequestVo> requestEntity;

	private URI targetUrl;

	private DeleteHistoryRequestVo requestBody;

	private HttpHeaders headers;

	@MockBean
	private RegistrationService registrationService;

	@Autowired
	private CryptoService cryptoService;

	@MockBean
	ICryptoServerGrpcClient cryptoServerClient;

	@Autowired
	private IServerConfigurationService serverConfigurationService;

	@Autowired
    private PropertyLoader propertyLoader;

	private int currentEpoch;

	private byte[] serverKey;

	@BeforeEach
	public void before() {
		MockitoAnnotations.initMocks(this);
		assert (this.restTemplate != null);
		this.headers = new HttpHeaders();
		this.headers.setContentType(MediaType.APPLICATION_JSON);
		this.targetUrl = UriComponentsBuilder.fromUriString(this.pathPrefix).path(UriConstants.DELETE_HISTORY).build()
				.encode().toUri();

		this.currentEpoch = this.getCurrentEpoch();

		this.serverKey = this.generateKey(24);
	}

	@Test
	public void testBadHttpVerb() {
		// GIVEN
		this.requestBody = DeleteHistoryRequestVo.builder().ebid(Base64.encode(new byte[4])).build();
		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		// WHEN
		ResponseEntity<String> response = this.restTemplate.exchange(this.targetUrl.toString(), HttpMethod.GET,
				this.requestEntity, String.class);
		// THEN
		assertEquals(HttpStatus.METHOD_NOT_ALLOWED, response.getStatusCode());
		verify(this.registrationService, times(0)).saveRegistration(ArgumentMatchers.any());
	}

	@Test
	public void testDeleteHistoryNoExposedEpochsSucceeds() {
		// GIVEN
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();
		Registration reg = Registration.builder()
				.permanentIdentifier(idA)
				.atRisk(true)
				.isNotified(false)
				.lastStatusRequestEpoch(this.currentEpoch - 3).build();

		byte[] decryptedEbid = new byte[8];
		System.arraycopy(idA, 0, decryptedEbid, 3, idA.length);
		System.arraycopy(ByteUtils.intToBytes(this.currentEpoch), 1, decryptedEbid, 0, decryptedEbid.length - idA.length);

		doReturn(Optional.of(GetIdFromAuthResponse.newBuilder()
								.setIdA(ByteString.copyFrom(idA))
								.setEpochId(this.currentEpoch)
								.build()))
				.when(this.cryptoServerClient).getIdFromAuth(any());
		doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

		this.requestBody = DeleteHistoryRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.epochId(this.currentEpoch)
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2]))
				.build();

		// WHEN - THEN
		callWsAndAssertResponse(reg, this.requestBody, HttpStatus.OK, 1, 0);
	}

	@Test
	public void testDeleteHistoryWithExposedEpochsSucceeds() {
		// GIVEN
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();
		List<EpochExposition> history = new ArrayList<>(Arrays.asList(new EpochExposition(), new EpochExposition()));
		Registration reg = Registration.builder()
				.permanentIdentifier(idA)
				.atRisk(true)
				.isNotified(false)
				.lastStatusRequestEpoch(this.currentEpoch - 3).exposedEpochs(history).build();

		byte[] decryptedEbid = new byte[8];
		System.arraycopy(idA, 0, decryptedEbid, 3, idA.length);
		System.arraycopy(ByteUtils.intToBytes(this.currentEpoch), 1, decryptedEbid, 0, decryptedEbid.length - idA.length);

		doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);
		doReturn(Optional.of(GetIdFromAuthResponse.newBuilder()
				.setIdA(ByteString.copyFrom(idA))
				.setEpochId(this.currentEpoch)
				.build()))
				.when(this.cryptoServerClient).getIdFromAuth(any());

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, this.currentEpoch);

		this.requestBody = DeleteHistoryRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.epochId(this.currentEpoch)
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2])).build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		// WHEN
		ResponseEntity<DeleteHistoryResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, DeleteHistoryResponseDto.class);

		// THEN
		assertEquals(HttpStatus.OK, response.getStatusCode());
		verify(this.registrationService, times(1)).findById(ArgumentMatchers.any());
		ArgumentCaptor<Registration> captor = ArgumentCaptor.forClass(Registration.class);
		verify(this.registrationService).saveRegistration(captor.capture());

		Registration arg = captor.getValue();
		assertTrue(arg.getExposedEpochs().isEmpty());
	}

	@Test
	public void testWhenIdNotFoundFails() {
		// GIVEN
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();
		Registration reg = Registration.builder()
				.permanentIdentifier(idA)
				.atRisk(true)
				.isNotified(false)
				.lastStatusRequestEpoch(this.currentEpoch - 3).build();

		doReturn(Optional.empty()).when(this.registrationService).findById(idA);

		byte[] decryptedEbid = new byte[8];
		System.arraycopy(idA, 0, decryptedEbid, 3, idA.length);
		System.arraycopy(ByteUtils.intToBytes(this.currentEpoch), 1, decryptedEbid, 0, decryptedEbid.length - idA.length);

		doReturn(Optional.of(GetIdFromAuthResponse.newBuilder()
				.setIdA(ByteString.copyFrom(idA))
				.setEpochId(this.currentEpoch)
				.build()))
				.when(this.cryptoServerClient).getIdFromAuth(any());

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, this.currentEpoch);

		this.requestBody = DeleteHistoryRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.epochId(this.currentEpoch)
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2])).build();

		// WHEN - THEN
		callWsAndAssertResponse(reg, this.requestBody, HttpStatus.NOT_FOUND, 1, 0);
	}

	@Test
	public void testBadEBIDSizeFails() {
		// GIVEN
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, this.currentEpoch);

		this.requestBody = DeleteHistoryRequestVo.builder().ebid(Base64.encode("ABC".getBytes()))
				.time(Base64.encode(reqContent[1])).mac(Base64.encode(reqContent[2])).build();
		// WHEN - THEN
		callWsAndAssertResponse(null, this.requestBody, HttpStatus.BAD_REQUEST, 0, 0);
	}

	/**
	 * Business requirement: app can use an old EBID to perform its request
	 */
	@Test
	public void testAcceptOldEBIDValueEpochSucceeds() {
		// GIVEN
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();
		List<EpochExposition> history = new ArrayList<>(Arrays.asList(new EpochExposition(), new EpochExposition()));
		Registration reg = Registration.builder()
				.permanentIdentifier(idA)
				.atRisk(true)
				.isNotified(false)
				.lastStatusRequestEpoch(this.currentEpoch - 3).exposedEpochs(history).build();

		doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

		// Mess up with the epoch used to create the EBID
		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, this.currentEpoch - 10);

		byte[] decryptedEbid = new byte[8];
		System.arraycopy(idA, 0, decryptedEbid, 3, idA.length);
		System.arraycopy(ByteUtils.intToBytes(currentEpoch - 10), 1, decryptedEbid, 0,
				decryptedEbid.length - idA.length);
		doReturn(Optional.of(GetIdFromAuthResponse.newBuilder()
				.setIdA(ByteString.copyFrom(idA))
				.setEpochId(this.currentEpoch - 10)
				.build()))
				.when(this.cryptoServerClient).getIdFromAuth(any());

		this.requestBody = DeleteHistoryRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.epochId(this.currentEpoch - 10)
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2]))
				.build();
		// WHEN - THEN
		callWsAndAssertResponse(reg, this.requestBody, HttpStatus.OK, 1, 1);
	}

	@Test
	public void testBadTimeFutureFails() {
		// GIVEN
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, this.currentEpoch,
				0 - ((int) this.propertyLoader.getRequestTimeDeltaTolerance() + 1));

		this.requestBody = DeleteHistoryRequestVo.builder().ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode(reqContent[1])).mac(Base64.encode(reqContent[2])).build();

		// WHEN - THEN
		callWsAndAssertResponse(null, this.requestBody, HttpStatus.BAD_REQUEST, 0, 0);
	}

	@Test
	public void testBadTimePastFails() {
		// GIVEN
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, this.currentEpoch,
				0 - (this.propertyLoader.getRequestTimeDeltaTolerance() + 1));

		this.requestBody = DeleteHistoryRequestVo.builder().ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode(reqContent[1])).mac(Base64.encode(reqContent[2])).build();

		// WHEN - THEN
		callWsAndAssertResponse(null, this.requestBody, HttpStatus.BAD_REQUEST, 0, 0);
	}

	@Test
	public void testBadTimeSizeFails() {
		// GIVEN
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, this.currentEpoch);

		this.requestBody = DeleteHistoryRequestVo.builder().ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode("AB".getBytes())).mac(Base64.encode(reqContent[2])).build();

		// WHEN - THEN
		callWsAndAssertResponse(null, this.requestBody, HttpStatus.BAD_REQUEST, 0, 0);
	}

	@Test
	public void testBadMACSizeFails() {
		// GIVEN
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, this.currentEpoch);

		this.requestBody = DeleteHistoryRequestVo.builder().ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode(reqContent[1])).mac(Base64.encode("ABC".getBytes())).build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		// WHEN - THEN
		callWsAndAssertResponse(null, this.requestBody, HttpStatus.BAD_REQUEST, 0, 0);
	}

	@Test
	public void testBadMACFails() {
		// GIVEN
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();
		Registration reg = Registration.builder()
				.permanentIdentifier(idA)
				.atRisk(true)
				.isNotified(false)
				.lastStatusRequestEpoch(this.currentEpoch - 3).build();

		byte[] decryptedEbid = new byte[8];
		System.arraycopy(idA, 0, decryptedEbid, 3, idA.length);
		System.arraycopy(ByteUtils.intToBytes(this.currentEpoch), 1, decryptedEbid, 0, decryptedEbid.length - idA.length);

		doReturn(Optional.of(reg)).when(this.registrationService).findById(ArgumentMatchers.any());
		doReturn(Optional.empty()).when(this.cryptoServerClient).getIdFromAuth(any());

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, this.currentEpoch);

		// Mess up with MAC
		reqContent[2][3] = 0x00;

		this.requestBody = DeleteHistoryRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.epochId(this.currentEpoch)
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2])).build();

		// WHEN - THEN
		callWsAndAssertResponse(null, this.requestBody, HttpStatus.BAD_REQUEST, 0, 0);
	}

	private byte[] generateKA() {
		byte[] ka = null;

		try {
			KeyGenerator keyGen = KeyGenerator.getInstance("HmacSHA256");

			// Creating a SecureRandom object
			SecureRandom secRandom = new SecureRandom();

			// Initializing the KeyGenerator
			keyGen.init(secRandom);

			// Creating/Generating a key
			Key key = keyGen.generateKey();
			ka = key.getEncoded();

		} catch (NoSuchAlgorithmException e) {
			log.info("Problem generating KA");
		}
		return ka;
	}

	private byte[] generateKey(final int nbOfbytes) {
		byte[] rndBytes = new byte[nbOfbytes];
		SecureRandom sr = new SecureRandom();
		sr.nextBytes(rndBytes);
		return rndBytes;
	}

	private int getCurrentEpoch() {
		long tpStartInSecondsNTP = this.serverConfigurationService.getServiceTimeStart();
		return TimeUtils.getCurrentEpochFrom(tpStartInSecondsNTP);
	}

	private byte[] generateTime32(int adjustTimeInSeconds) {
		long tsInSeconds = TimeUtils.convertUnixMillistoNtpSeconds(System.currentTimeMillis());
		tsInSeconds += adjustTimeInSeconds;
		byte[] tsInSecondsB = ByteUtils.longToBytes(tsInSeconds);
		byte[] time = new byte[4];

		System.arraycopy(tsInSecondsB, 4, time, 0, 4);

		return time;
	}

	private byte[] generateHMAC(final CryptoHMACSHA256 cryptoHMACSHA256S, final byte[] argument, final byte prefixByte)
			throws Exception {

		final byte[] prefix = new byte[] { prefixByte };

		// HMAC-SHA256 processing
		byte[] generatedSHA256 = cryptoHMACSHA256S.encrypt(ByteUtils.addAll(prefix, argument));

		return generatedSHA256;
	}

	private final byte AUTH_REQUEST_TYPE = (byte) 0x04;

	private byte[] generateMACforESR(byte[] ebid, byte[] time, byte[] ka) {
		// Merge arrays
		// HMAC-256
		// return hash
		byte[] agg = new byte[8 + 4];
		System.arraycopy(ebid, 0, agg, 0, ebid.length);
		System.arraycopy(time, 0, agg, ebid.length, time.length);

		byte[] mac = new byte[32];
		try {
			mac = this.generateHMAC(new CryptoHMACSHA256(ka), agg, AUTH_REQUEST_TYPE);
		} catch (Exception e) {
			log.info("Problem generating SHA256");
		}
		return mac;
	}

	private byte[][] createEBIDTimeMACFor(byte[] id, byte[] ka, int currentEpoch) {
		return this.createEBIDTimeMACFor(id, ka, currentEpoch, 0);
	}

	private byte[][] createEBIDTimeMACFor(byte[] id, byte[] ka, int currentEpoch, int adjustTimeBySeconds) {
		byte[][] res = new byte[3][];
		try {
			res[0] = this.cryptoService.generateEBID(new CryptoSkinny64(this.serverKey),
					currentEpoch, id);
			res[1] = this.generateTime32(adjustTimeBySeconds);
			res[2] = this.generateMACforESR(res[0], res[1], ka);
		} catch (Exception e) {
			log.info("Problem creating EBID, Time and MAC for test");
		}
		return res;
	}

	private void callWsAndAssertResponse(Registration reg, DeleteHistoryRequestVo requestBody,
			HttpStatus expectedStatus, int findByIdCalls, int saveRegistrationCalls) {
		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		ResponseEntity<DeleteHistoryResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, DeleteHistoryResponseDto.class);
		// THEN
		assertEquals(expectedStatus, response.getStatusCode());
		verify(this.registrationService, times(findByIdCalls)).findById(ArgumentMatchers.any());
		if (Objects.nonNull(reg)) {
			verify(this.registrationService, times(saveRegistrationCalls)).saveRegistration(reg);
		} else {
			verify(this.registrationService, times(saveRegistrationCalls)).saveRegistration(ArgumentMatchers.any());
		}
	}
}
