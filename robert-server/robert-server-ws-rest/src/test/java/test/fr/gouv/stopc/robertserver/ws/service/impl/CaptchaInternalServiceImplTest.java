package test.fr.gouv.stopc.robertserver.ws.service.impl;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.net.URI;

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
import fr.gouv.stopc.robertserver.ws.dto.CaptchaInternalDto;
import fr.gouv.stopc.robertserver.ws.service.impl.CaptchaInternalErrorMessage;
import fr.gouv.stopc.robertserver.ws.service.impl.CaptchaInternalServiceImpl;
import fr.gouv.stopc.robertserver.ws.service.impl.utils.CaptchaInternalAccessException;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.RegisterInternalVo;

@ExtendWith(SpringExtension.class)
@TestPropertySource("classpath:application.properties")
public class CaptchaInternalServiceImplTest {

    @Value("${captcha.internal.verify.url}")
    private String captchaInternalVerificationUrl;

    @Value("${captcha.internal.success.code}")
    private String captchaInternalSuccessCode;

    @InjectMocks
    private CaptchaInternalServiceImpl captchaStrictServiceImpl;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private IServerConfigurationService serverConfigurationService;

    @Mock
    private PropertyLoader propertyLoader;

    private RegisterInternalVo registerVo;

    @BeforeEach
    public void beforeEach() {

        this.registerVo = RegisterInternalVo.builder().captcha("captcha").captchaId("captchaId").build();
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
        CaptchaInternalDto captchaDto = CaptchaInternalDto.builder()
                .result("SUCCESS")
                .errorCode(null)
                .errorMessage(null)
                .build();
        when(this.restTemplate.postForEntity(any(URI.class), any(),
                any())).thenReturn(ResponseEntity.ok(captchaDto));

        when(this.propertyLoader.getCaptchaInternalVerificationUrl()).thenReturn(this.captchaInternalVerificationUrl);
        when(this.propertyLoader.getCaptchaInternalSuccessCode()).thenReturn(this.captchaInternalSuccessCode);

        // When
        boolean isVerified = this.captchaStrictServiceImpl.verifyCaptcha(this.registerVo);

        // Then
        assertTrue(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenFailed() {

        // Given
        CaptchaInternalDto captchaDto = CaptchaInternalDto.builder()
                .result("FAILED")
                .errorCode(null)
                .errorMessage(null)
                .build();
        when(this.restTemplate.postForEntity(any(URI.class), any(),
                any())).thenReturn(ResponseEntity.ok(captchaDto));

        when(this.propertyLoader.getCaptchaInternalVerificationUrl()).thenReturn(this.captchaInternalVerificationUrl);
        when(this.propertyLoader.getCaptchaInternalSuccessCode()).thenReturn(this.captchaInternalSuccessCode);

        // When
        boolean isVerified = this.captchaStrictServiceImpl.verifyCaptcha(this.registerVo);

        // Then
        assertFalse(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenErrorIsThrown() {

        // Given
        when(this.propertyLoader.getCaptchaInternalVerificationUrl()).thenReturn(this.captchaInternalVerificationUrl);
        when(this.propertyLoader.getCaptchaInternalSuccessCode()).thenReturn(this.captchaInternalSuccessCode);
        when(this.restTemplate.postForEntity(any(String.class), any(), any())).thenThrow(RestClientException.class);

        // When
        boolean isVerified = this.captchaStrictServiceImpl.verifyCaptcha(this.registerVo);

        // Then
        assertFalse(isVerified);
    }

    @Test
    public void testVerifyCaptchaWhenDataInvalid() {

        // Given
        when(this.propertyLoader.getCaptchaInternalVerificationUrl()).thenReturn(this.captchaInternalVerificationUrl);
        when(this.propertyLoader.getCaptchaInternalSuccessCode()).thenReturn(this.captchaInternalSuccessCode);
        when(this.restTemplate.postForEntity(any(String.class), any(), any()))
                .thenThrow( new CaptchaInternalAccessException(HttpStatus.NOT_FOUND,
                        CaptchaInternalErrorMessage.builder().httpStatus(HttpStatus.NOT_FOUND).message("The captcha does not exist").code("0002").build(),
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
