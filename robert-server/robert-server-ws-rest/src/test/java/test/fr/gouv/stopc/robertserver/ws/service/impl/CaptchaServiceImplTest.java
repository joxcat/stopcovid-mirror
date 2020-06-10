package test.fr.gouv.stopc.robertserver.ws.service.impl;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.net.URI;
import java.util.Date;

import org.junit.jupiter.api.BeforeEach;
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
@TestPropertySource("classpath:application.properties")
public class CaptchaServiceImplTest {

    @Value("${captcha.verify.url}")
    private String captchaVerificationUrl;

    @Value("${captcha.secret}")
    private String captchaSecret;

    @Value("${captcha.hostname}")
    private String captchaHostname;

    /**
     *
     * TODO: Remove this as far as it is no more needed for tests
     */
    @Value("${captcha.magicnumber}")
    private String magicNumber;

    @InjectMocks
    private CaptchaServiceImpl captchaServiceImpl;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private IServerConfigurationService serverConfigurationService;

    @Mock
    private PropertyLoader propertyLoader;

    private RegisterVo registerVo;

    @BeforeEach
    public void beforeEach() {

        this.registerVo = RegisterVo.builder().captcha("captcha").build();
    }

    @Test
    public void testVerifyCaptchaWhenVoIsNull() {

        // When
        boolean isVerified = this.captchaServiceImpl.verifyCaptcha(null);

        // Then
        assertFalse(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenVoHasNoCaptcha() {

        // Given
        this.registerVo.setCaptcha(null);

        // When
        boolean isVerified = this.captchaServiceImpl.verifyCaptcha(null);

        // Then
        assertFalse(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenVoIsNotNull() {

        // Given
        CaptchaDto captchaDto = CaptchaDto.builder()
                .success(true)
                .challengeTimestamp(new Date())
                .hostname(this.captchaHostname)
                .build();
        when(this.restTemplate.postForEntity(any(URI.class), any(),
                any())).thenReturn(ResponseEntity.ok(captchaDto));

        when(this.propertyLoader.getCaptchaVerificationUrl()).thenReturn(this.captchaVerificationUrl);
        when(this.propertyLoader.getCaptchaSecret()).thenReturn(this.captchaSecret);
        when(this.propertyLoader.getCaptchaHostname()).thenReturn(this.captchaHostname);
        when(this.propertyLoader.getCaptchaChallengeTimestampTolerance()).thenReturn(3600);

        // When
        boolean isVerified = this.captchaServiceImpl.verifyCaptcha(this.registerVo);

        // Then
        assertTrue(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenErrorIsThrown() {

        // Given
        when(this.propertyLoader.getCaptchaVerificationUrl()).thenReturn(this.captchaVerificationUrl);
        when(this.propertyLoader.getCaptchaSecret()).thenReturn(this.captchaSecret);
        when(this.propertyLoader.getCaptchaHostname()).thenReturn(this.captchaHostname);
        when(this.propertyLoader.getCaptchaChallengeTimestampTolerance()).thenReturn(3600);
        when(this.restTemplate.postForEntity(any(String.class), any(), any())).thenThrow(RestClientException.class);

        // When
        boolean isVerified = this.captchaServiceImpl.verifyCaptcha(this.registerVo);

        // Then
        assertFalse(isVerified);
    }

}
