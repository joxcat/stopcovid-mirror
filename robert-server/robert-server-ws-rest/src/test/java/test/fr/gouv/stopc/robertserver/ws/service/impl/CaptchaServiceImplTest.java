package test.fr.gouv.stopc.robertserver.ws.service.impl;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.util.Date;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.ws.dto.CaptchaDto;
import fr.gouv.stopc.robertserver.ws.service.impl.CaptchaServiceImpl;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.RegisterVo;

@ExtendWith(SpringExtension.class)
public class CaptchaServiceImplTest {

	@Value("${captcha.verify.url}")
	private String captchaVerificationUrl;

	@Value("${captcha.secret}")
	private String captchaSecret;

	@Value("${captcha.hostname}")
	private String captchaHostname;

	@InjectMocks
	private CaptchaServiceImpl captchaServiceImpl;

	@Mock
	private RestTemplate restTemplate;

	@Mock
	private IServerConfigurationService serverConfigurationService;

	@Mock
	private PropertyLoader propertyLoader;

	@Test
	public void testVerifyCaptchaWhenVoIsNull() {

		// When
		boolean isVerified = this.captchaServiceImpl.verifyCaptcha(null);

		// Then
		assertTrue(isVerified);
	}

	@Test
	public void testVerifyCaptchaWhenVoIsNotNull() {

		// Given
		CaptchaDto captchaDto = CaptchaDto.builder().success(true).challengeTimestamp(new Date()).hostname(this.captchaHostname).build();
		when(this.restTemplate.postForEntity(any(String.class), any(), any())).thenReturn(ResponseEntity.ok(captchaDto));

		when(this.propertyLoader.getCaptchaVerificationUrl()).thenReturn(this.captchaVerificationUrl);
		when(this.propertyLoader.getCaptchaSecret()).thenReturn(this.captchaSecret);
		when(this.propertyLoader.getCaptchaHostname()).thenReturn(this.captchaHostname);
		when(this.serverConfigurationService.getCaptchaChallengeTimestampTolerance()).thenReturn(3600);

		// When
		boolean isVerified = this.captchaServiceImpl.verifyCaptcha(RegisterVo.builder().build());

		// Then
		assertTrue(isVerified);
	}

	@Test
	public void testVerifyCaptchaWhenErrorIsThrown() {

		// Given
		when(this.restTemplate.postForEntity(any(String.class), any(), any())).thenThrow(RestClientException.class);

		// When
		boolean isVerified = this.captchaServiceImpl.verifyCaptcha(RegisterVo.builder().build());

		// Then
		assertTrue(isVerified);
	}

}
