package test.fr.gouv.stopc.robertserver.ws;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.net.URI;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Optional;

import javax.inject.Inject;

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
import fr.gouv.stopc.robert.crypto.grpc.server.response.EphemeralTupleResponse;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.impl.RegistrationService;
import fr.gouv.stopc.robertserver.ws.RobertServerWsRestApplication;
import fr.gouv.stopc.robertserver.ws.dto.EpochKeyBundleDto;
import fr.gouv.stopc.robertserver.ws.dto.EpochKeyDto;
import fr.gouv.stopc.robertserver.ws.dto.RegisterResponseDto;
import fr.gouv.stopc.robertserver.ws.dto.mapper.EpochKeyBundleDtoMapper;
import fr.gouv.stopc.robertserver.ws.service.CaptchaService;
import fr.gouv.stopc.robertserver.ws.utils.UriConstants;
import fr.gouv.stopc.robertserver.ws.vo.RegisterVo;
import lombok.extern.slf4j.Slf4j;

@DirtiesContext(classMode = ClassMode.AFTER_EACH_TEST_METHOD)
@ExtendWith(SpringExtension.class)
@SpringBootTest(classes = {
		RobertServerWsRestApplication.class }, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource("classpath:application.properties")
@Slf4j
public class RegisterControllerWsRestTest {
	@Value("${controller.path.prefix}")
	private String pathPrefix;

	@Inject
	private TestRestTemplate restTemplate;

	HttpEntity<RegisterVo> requestEntity;

	private URI targetUrl;

	private RegisterVo body;

	private HttpHeaders headers;

	@MockBean
	private RegistrationService registrationService;

	@MockBean
	private CaptchaService captchaService;

	@MockBean
	ICryptoServerGrpcClient cryptoServerClient;

	@MockBean
	EpochKeyBundleDtoMapper epochKeyBundleDtoMapper;


	@Autowired
	private IServerConfigurationService serverConfigurationService;

	private int currentEpoch;

	@BeforeEach
	public void before() {
		MockitoAnnotations.initMocks(this);
		assert (this.restTemplate != null);
		this.headers = new HttpHeaders();
		this.headers.setContentType(MediaType.APPLICATION_JSON);
		this.targetUrl = UriComponentsBuilder.fromUriString(this.pathPrefix).path(UriConstants.REGISTER).build()
				.encode().toUri();

		this.currentEpoch = this.getCurrentEpoch();

		// TODO: review this or find a better wail to validate epochid
		// Sanity check: this test will fail one year after the start of the service
		// (used to prevent epoch calculation errors)
		assertTrue(this.currentEpoch <= 4*24*365);
	}

	@Test
	public void testBadHttpVerb() {
		this.body = RegisterVo.builder().captcha("TEST").build();

		this.requestEntity = new HttpEntity<>(this.body, this.headers);

		ResponseEntity<String> response = this.restTemplate.exchange(this.targetUrl.toString(), HttpMethod.GET,
				this.requestEntity, String.class);

		log.info("******* Bad HTTP Verb Payload: {}", response.getBody());

		assertEquals(HttpStatus.METHOD_NOT_ALLOWED, response.getStatusCode());
		verify(this.registrationService, times(0)).saveRegistration(ArgumentMatchers.any());
	}
// TODO: Uncomment theses tests when the captcha becomes mandatory
//	@Test
//	public void testNullCaptcha() {
//		this.body = RegisterVo.builder().captcha(null).build();
//
//		this.requestEntity = new HttpEntity<>(this.body, this.headers);
//
//		ResponseEntity<String> response = this.restTemplate.exchange(this.targetUrl.toString(), HttpMethod.POST,
//				this.requestEntity, String.class);
//
//		assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
//		verify(this.registrationService, times(0)).saveRegistration(ArgumentMatchers.any());
//	}
//
//	@Test
//	public void testNoCaptcha() {
//		this.body = RegisterVo.builder().build();
//
//		this.requestEntity = new HttpEntity<>(this.body, this.headers);
//
//		ResponseEntity<String> response = this.restTemplate.exchange(this.targetUrl.toString(), HttpMethod.POST,
//				this.requestEntity, String.class);
//
//		assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
//		verify(this.registrationService, times(0)).saveRegistration(ArgumentMatchers.any());
//	}

	@Test
	public void testCaptchaFailure() {
		this.body = RegisterVo.builder().captcha("TEST").build();

		this.requestEntity = new HttpEntity<>(this.body, this.headers);

		// Make it so that CAPTCHA verification fails (either incorrect token or too
		// great a time
		// difference between solving and the request)
		doReturn(false).when(this.captchaService).verifyCaptcha(ArgumentMatchers.any());

		ResponseEntity<String> response = this.restTemplate.exchange(this.targetUrl.toString(), HttpMethod.POST,
				this.requestEntity, String.class);

		assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
		verify(this.registrationService, times(0)).saveRegistration(ArgumentMatchers.any());
	}

	@Test
	public void testSuccess() {
		this.body = RegisterVo.builder().captcha("TEST").build();

		this.requestEntity = new HttpEntity<>(this.body, this.headers);

		byte[] key = "0123456789ABCDEF0123456789ABCDEF".getBytes();
		byte[] id = "12345".getBytes();
		
		
		EpochKeyBundleDto epochKeyDto = EpochKeyBundleDto.builder()
		.epochId(120L)
		.key(EpochKeyDto.builder()
				.ebid(Base64.encode("12345678".getBytes()))
				.ecc(Base64.encode("1".getBytes()))
				.build())
		.build();

		Registration reg = Registration.builder().permanentIdentifier(id).exposedEpochs(new ArrayList<>())
				.isNotified(false).sharedKey(key).atRisk(false).build();

		when(this.cryptoServerClient.generateEphemeralTuple(any())).thenReturn(Arrays.asList( EphemeralTupleResponse
				.newBuilder().build()));
		when(this.epochKeyBundleDtoMapper.convert(anyList())).thenReturn(Arrays.asList(epochKeyDto));
		
		when(this.registrationService.createRegistration()).thenReturn(Optional.of(reg));
		when(this.captchaService.verifyCaptcha(this.body)).thenReturn(true);


		ResponseEntity<RegisterResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
				HttpMethod.POST, this.requestEntity, RegisterResponseDto.class);

		assertEquals(HttpStatus.CREATED, response.getStatusCode());
		assertNotNull(response.getBody().getFilteringAlgoConfig());
		assertEquals(32, Base64.decode(response.getBody().getKey()).length);
		assertTrue(Arrays.equals(key, Base64.decode(response.getBody().getKey())));
		assertNotNull(response.getBody().getIdsForEpochs());
		assertTrue(response.getBody().getIdsForEpochs().size() > 0);
		verify(this.registrationService, times(1)).createRegistration();
	}

	private int getCurrentEpoch() {
		long tpStartInSecondsNTP = this.serverConfigurationService.getServiceTimeStart();
		return TimeUtils.getCurrentEpochFrom(tpStartInSecondsNTP);
	}
}
