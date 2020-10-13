package test.fr.gouv.stopc.robertserver.ws.service.impl;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.net.URI;

import fr.gouv.stopc.robertserver.ws.vo.RegisterVo;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.ws.dto.CaptchaDto;
import fr.gouv.stopc.robertserver.ws.service.impl.CaptchaErrorMessage;
import fr.gouv.stopc.robertserver.ws.service.impl.CaptchaServiceImpl;
import fr.gouv.stopc.robertserver.ws.service.impl.utils.CaptchaAccessException;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;

@ExtendWith(SpringExtension.class)
@TestPropertySource("classpath:application.properties")
public class CaptchaServiceImplTest {

    @Value("${captcha.internal.verify.url}")
    private String captchaVerificationUrl;

    @Value("${captcha.internal.success.code}")
    private String captchaSuccessCode;

    @InjectMocks
    private CaptchaServiceImpl captchaStrictServiceImpl;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private IServerConfigurationService serverConfigurationService;

    @Mock
    private PropertyLoader propertyLoader;

    private RegisterVo registerVo;

    @BeforeEach
    public void beforeEach() {

        this.registerVo = RegisterVo.builder().captcha("captcha").captchaId("captchaId").build();
    }

    @Test
    public void testVerifyCaptchaWhenVoIsNull() {

        // When
        boolean isVerified = this.captchaStrictServiceImpl.verifyCaptcha(null);

        // Then
        assertFalse(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenVoHasNoCaptcha() {

        // Given
        this.registerVo.setCaptcha(null);

        // When
        boolean isVerified = this.captchaStrictServiceImpl.verifyCaptcha(null);

        // Then
        assertFalse(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenVoIsNotNull() {

        // Given
        CaptchaDto captchaDto = CaptchaDto.builder()
                .result("SUCCESS")
                .errorCode(null)
                .errorMessage(null)
                .build();
        when(this.restTemplate.postForEntity(any(URI.class), any(),
                any())).thenReturn(ResponseEntity.ok(captchaDto));

        when(this.propertyLoader.getCaptchaVerificationUrl()).thenReturn(this.captchaVerificationUrl);
        when(this.propertyLoader.getCaptchaSuccessCode()).thenReturn(this.captchaSuccessCode);

        // When
        boolean isVerified = this.captchaStrictServiceImpl.verifyCaptcha(this.registerVo);

        // Then
        assertTrue(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenFailed() {

        // Given
        CaptchaDto captchaDto = CaptchaDto.builder()
                .result("FAILED")
                .errorCode(null)
                .errorMessage(null)
                .build();
        when(this.restTemplate.postForEntity(any(URI.class), any(),
                any())).thenReturn(ResponseEntity.ok(captchaDto));

        when(this.propertyLoader.getCaptchaVerificationUrl()).thenReturn(this.captchaVerificationUrl);
        when(this.propertyLoader.getCaptchaSuccessCode()).thenReturn(this.captchaSuccessCode);

        // When
        boolean isVerified = this.captchaStrictServiceImpl.verifyCaptcha(this.registerVo);

        // Then
        assertFalse(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenErrorIsThrown() {

        // Given
        when(this.propertyLoader.getCaptchaVerificationUrl()).thenReturn(this.captchaVerificationUrl);
        when(this.propertyLoader.getCaptchaSuccessCode()).thenReturn(this.captchaSuccessCode);
        when(this.restTemplate.postForEntity(any(String.class), any(), any())).thenThrow(RestClientException.class);

        // When
        boolean isVerified = this.captchaStrictServiceImpl.verifyCaptcha(this.registerVo);

        // Then
        assertFalse(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenDataInvalid() {

        // Given
        when(this.propertyLoader.getCaptchaVerificationUrl()).thenReturn(this.captchaVerificationUrl);
        when(this.propertyLoader.getCaptchaSuccessCode()).thenReturn(this.captchaSuccessCode);
        when(this.restTemplate.postForEntity(any(String.class), any(), any()))
                .thenThrow( new CaptchaAccessException(HttpStatus.NOT_FOUND,
                        CaptchaErrorMessage.builder().httpStatus(HttpStatus.NOT_FOUND).message("The captcha does not exist").code("0002").build(),
                        "{\r\n"
                        + "    \"code\": \"0002\",\r\n"
                        + "    \"message\": \"The captcha does not exist\"\r\n"
                        + "}"));

        // When
        boolean isVerified = this.captchaStrictServiceImpl.verifyCaptcha(this.registerVo);

        // Then
        assertFalse(isVerified);
    }
    

}
