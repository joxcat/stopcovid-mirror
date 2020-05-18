package test.fr.gouv.stopc.robertserver.ws;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.structure.impl.Crypto3DES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.impl.RegistrationService;
import fr.gouv.stopc.robertserver.ws.RobertServerWsRestApplication;
import fr.gouv.stopc.robertserver.ws.dto.UnregisterResponseDto;
import fr.gouv.stopc.robertserver.ws.utils.UriConstants;
import fr.gouv.stopc.robertserver.ws.vo.UnregisterRequestVo;
import lombok.extern.slf4j.Slf4j;
import org.bson.internal.Base64;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentMatchers;
import org.mockito.MockitoAnnotations;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.*;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.annotation.DirtiesContext.ClassMode;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.util.UriComponentsBuilder;

import javax.crypto.KeyGenerator;
import javax.inject.Inject;
import java.net.URI;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@DirtiesContext(classMode = ClassMode.AFTER_EACH_TEST_METHOD)
@ExtendWith(SpringExtension.class)
@SpringBootTest(classes = {
		RobertServerWsRestApplication.class }, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource("classpath:application.properties")
@Slf4j
public class UnregisterControllerWsRestTest {
	@Value("${controller.path.prefix}")
	private String pathPrefix;

	@Inject
	private TestRestTemplate restTemplate;

	HttpEntity<UnregisterRequestVo> requestEntity;

	private URI targetUrl;

	private UnregisterRequestVo requestBody;

	private HttpHeaders headers;

	@MockBean
	private RegistrationService registrationService;

	@Autowired
	private CryptoService cryptoService;

	@MockBean
	ICryptoServerGrpcClient cryptoServerClient;

	@Autowired
	private IServerConfigurationService serverConfigurationService;

	private int currentEpoch;

	@BeforeEach
	public void before() {
		MockitoAnnotations.initMocks(this);
		assert (this.restTemplate != null);
		this.headers = new HttpHeaders();
		this.headers.setContentType(MediaType.APPLICATION_JSON);
		this.targetUrl = UriComponentsBuilder.fromUriString(this.pathPrefix).path(UriConstants.UNREGISTER).build().encode().toUri();

		this.currentEpoch = this.getCurrentEpoch();
	}

	@Test
	public void testBadHttpVerb() {
		this.requestBody = UnregisterRequestVo.builder().ebid(Base64.encode(new byte[4])).build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		ResponseEntity<String> response = this.restTemplate.exchange(this.targetUrl.toString(), HttpMethod.GET,
				this.requestEntity, String.class);

		log.info("******* Bad HTTP Verb Payload: {}", response.getBody());

		assertEquals(HttpStatus.METHOD_NOT_ALLOWED, response.getStatusCode());
		verify(this.registrationService, never()).delete(ArgumentMatchers.any());
	}

	@Test
	public void testBadEBIDSize() {
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();
		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

		requestBody = UnregisterRequestVo.builder()
				.ebid(Base64.encode("ABC".getBytes()))
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2]))
				.build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		ResponseEntity<UnregisterResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, UnregisterResponseDto.class);

		assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
		verify(this.registrationService, never()).findById(ArgumentMatchers.any());
		verify(this.registrationService, never()).delete(ArgumentMatchers.any());
	}

	/**
	 * Business requirement: app can use an old EBID to perform its request
	 */
	@Test
	public void testAcceptOldEBIDValueEpoch() {

		// Given
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();
		// Mess up with the epoch used to create the EBID
		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch - 10);
		Registration reg = Registration.builder()
				.permanentIdentifier(idA)
				.sharedKey(kA)
				.atRisk(true)
				.isNotified(false)
				.lastStatusRequestEpoch(currentEpoch - 3).build();

		byte[] decryptedEbid = new byte[8];
		System.arraycopy(idA, 0, decryptedEbid, 3, idA.length);
		System.arraycopy(ByteUtils.intToBytes(currentEpoch - 10), 1, decryptedEbid, 0, decryptedEbid.length - idA.length);

		doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

		doReturn(decryptedEbid).when(this.cryptoServerClient).decryptEBID(any());

		doReturn(true).when(this.cryptoServerClient).validateMacForType(any());


		requestBody = UnregisterRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2]))
				.build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		// When
		ResponseEntity<UnregisterResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, UnregisterResponseDto.class);

		// Given
		assertEquals(HttpStatus.OK, response.getStatusCode());
		verify(this.registrationService, times(1)).findById(ArgumentMatchers.any());
		verify(this.registrationService, times(1)).delete(ArgumentMatchers.any());
	}

	@Test
	public void testBadTimeFuture() {
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();

		byte[][] reqContent = createEBIDTimeMACFor(
				idA,
				kA,
				currentEpoch,
				0 - (this.serverConfigurationService.getRequestTimeDeltaTolerance() + 1));

		requestBody = UnregisterRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2]))
				.build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		ResponseEntity<UnregisterResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, UnregisterResponseDto.class);

		assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
		verify(this.registrationService, never()).findById(ArgumentMatchers.any());
		verify(this.registrationService, never()).delete(ArgumentMatchers.any());
	}

	@Test
	public void testBadTimePast() {
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();

		byte[][] reqContent = createEBIDTimeMACFor(
				idA,
				kA,
				currentEpoch,
				0 - (this.serverConfigurationService.getRequestTimeDeltaTolerance() + 1));

		requestBody = UnregisterRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2])).build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		ResponseEntity<UnregisterResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, UnregisterResponseDto.class);

		assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
		verify(this.registrationService, never()).findById(ArgumentMatchers.any());
		verify(this.registrationService, never()).delete(ArgumentMatchers.any());
	}

	@Test
	public void testBadTimeSize() {
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

		requestBody = UnregisterRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode("AB".getBytes()))
				.mac(Base64.encode(reqContent[2])).build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		ResponseEntity<UnregisterResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, UnregisterResponseDto.class);

		assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
		verify(this.registrationService, never()).findById(ArgumentMatchers.any());
		verify(this.registrationService, never()).delete(ArgumentMatchers.any());
	}

	@Test
	public void testBadMACSize() {
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

		requestBody = UnregisterRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode("ABC".getBytes())).build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		ResponseEntity<UnregisterResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, UnregisterResponseDto.class);

		assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
		verify(this.registrationService, never()).findById(ArgumentMatchers.any());
		verify(this.registrationService, never()).delete(ArgumentMatchers.any());
	}

	@Test
	public void testBadMAC() {

		// Given
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();
		Registration reg = Registration.builder().permanentIdentifier(idA).sharedKey(kA).atRisk(true).isNotified(false)
				.lastStatusRequestEpoch(currentEpoch - 3).build();

		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

		byte[] decryptedEbid = new byte[8];
		System.arraycopy(idA, 0, decryptedEbid, 3, idA.length);
		System.arraycopy(ByteUtils.intToBytes(currentEpoch), 1, decryptedEbid, 0, decryptedEbid.length - idA.length);

		doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

		doReturn(decryptedEbid).when(this.cryptoServerClient).decryptEBID(any());

		doReturn(false).when(this.cryptoServerClient).validateMacForType(any());


		requestBody = UnregisterRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2])).build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		// When
		ResponseEntity<UnregisterResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, UnregisterResponseDto.class);

		// Then
		assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
		verify(this.cryptoServerClient, times(1)).decryptEBID(ArgumentMatchers.any());
		verify(this.registrationService, times(1)).findById(ArgumentMatchers.any());
		verify(this.cryptoServerClient, times(1)).validateMacForType(ArgumentMatchers.any());
		verify(this.registrationService, never()).delete(ArgumentMatchers.any());
	}

	public byte[] generateKA() {
		byte[] ka = null;

		try {
			KeyGenerator keyGen = KeyGenerator.getInstance("HmacSHA256");

			SecureRandom secRandom = new SecureRandom();
			keyGen.init(secRandom);
			Key key = keyGen.generateKey();
			ka = key.getEncoded();

		} catch (NoSuchAlgorithmException e) {
			log.info("Problem generating KA");
		}
		return ka;
	}

	public byte[] generateKey(final int nbOfbytes) {
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

		System.arraycopy(tsInSecondsB, 4, time, 0, time.length);

		return time;
	}

	private byte[] generateHMAC(final CryptoHMACSHA256 cryptoHMACSHA256S, final byte[] argument, final DigestSaltEnum salt)
			throws Exception {

		final byte[] prefix = new byte[] { salt.getValue() };

		// HMAC-SHA256 processing
		byte[] generatedSHA256 = cryptoHMACSHA256S.encrypt(ByteUtils.addAll(prefix, argument));

		return generatedSHA256;
	}

	private byte[] generateMACforESR(byte[] ebid, byte[] time, byte[] ka) {
		byte[] agg = new byte[8 + 4];
		System.arraycopy(ebid, 0, agg, 0, ebid.length);
		System.arraycopy(time, 0, agg, ebid.length, time.length);

		byte[] mac = new byte[32];
		try {
			mac = this.generateHMAC(new CryptoHMACSHA256(ka), agg, DigestSaltEnum.UNREGISTER);
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
			res[0] = this.cryptoService.generateEBID(new Crypto3DES(this.serverConfigurationService.getServerKey()),
					currentEpoch, id);
			res[1] = this.generateTime32(adjustTimeBySeconds);
			res[2] = this.generateMACforESR(res[0], res[1], ka);
		} catch (Exception e) {
			log.info("Problem creating EBID, Time and MAC for test");
		}
		return res;
	}

	@Test
	public void testUnregisterRequestSuccess() {
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();
		Registration reg = Registration.builder()
				.permanentIdentifier(idA)
				.sharedKey(kA)
				.atRisk(true)
				.isNotified(false)
				.lastStatusRequestEpoch(currentEpoch - 3).build();


		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

		byte[] decryptedEbid = new byte[8];
		System.arraycopy(idA, 0, decryptedEbid, 3, idA.length);
		System.arraycopy(ByteUtils.intToBytes(currentEpoch), 1, decryptedEbid, 0, decryptedEbid.length - idA.length);

		doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

		doReturn(decryptedEbid).when(this.cryptoServerClient).decryptEBID(any());

		doReturn(true).when(this.cryptoServerClient).validateMacForType(any());

		requestBody = UnregisterRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2])).build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		ResponseEntity<UnregisterResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, UnregisterResponseDto.class);

		assertEquals(HttpStatus.OK, response.getStatusCode());
		assertTrue(response.getBody().getSuccess());
		verify(this.cryptoServerClient, times(1)).decryptEBID(ArgumentMatchers.any());
		verify(this.registrationService, times(1)).findById(idA);
		verify(this.cryptoServerClient, times(1)).validateMacForType(ArgumentMatchers.any());
		verify(this.registrationService, times(1)).delete(ArgumentMatchers.any());
	}

	@Test
	public void testUnregisterRequestNoSuchId() {

		// Given
		byte[] idA = this.generateKey(5);
		byte[] kA = this.generateKA();


		byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);
		byte[] decryptedEbid = new byte[8];
		System.arraycopy(idA, 0, decryptedEbid, 3, idA.length);
		System.arraycopy(ByteUtils.intToBytes(currentEpoch), 1, decryptedEbid, 0, decryptedEbid.length - idA.length);

		doReturn(decryptedEbid).when(this.cryptoServerClient).decryptEBID(any());

		doReturn(true).when(this.cryptoServerClient).validateMacForType(any());

		doReturn(Optional.empty()).when(this.registrationService).findById(idA);

		requestBody = UnregisterRequestVo.builder()
				.ebid(Base64.encode(reqContent[0]))
				.time(Base64.encode(reqContent[1]))
				.mac(Base64.encode(reqContent[2])).build();

		this.requestEntity = new HttpEntity<>(this.requestBody, this.headers);

		// When
		ResponseEntity<UnregisterResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, UnregisterResponseDto.class);

		// Then
		assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
		verify(this.cryptoServerClient, times(1)).decryptEBID(ArgumentMatchers.any());
		verify(this.registrationService, times(1)).findById(ArgumentMatchers.any());
		verify(this.cryptoServerClient, never()).validateMacForType(ArgumentMatchers.any());
		verify(this.registrationService, never()).delete(ArgumentMatchers.any());
	}
}
