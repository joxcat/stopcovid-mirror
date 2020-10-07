package test.fr.gouv.stopc.robertserver.ws.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.net.URI;
import java.util.Optional;

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
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.reactive.function.client.WebClient;

import fr.gouv.stopc.robertserver.ws.dto.VerifyResponseDto;
import fr.gouv.stopc.robertserver.ws.service.impl.RestApiServiceImpl;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.PushInfoVo;

@ExtendWith(SpringExtension.class)
@TestPropertySource("classpath:application.properties")
public class RestApiServiceImplTest {

    @InjectMocks
    private RestApiServiceImpl restApiServiceImpl;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private PropertyLoader propertyLoader;

    @Mock
    private WebClient webClient;

    @Value("${controller.internal.path.prefix}")
    private String internalPathPrefix;

    @Value("${push.server.host}")
    private String pushServerHost;

    @Value("${push.server.port}")
    private String pushServerPort;

    @Value("${push.api.version}")
    private String pushApiVersion;

    @Value("${push.api.path}")
    private String pushApiPath;

    @Value("${push.api.path.token}")
    private String pushApiTokenPath;

    private PushInfoVo pushInfoVo;

    @BeforeEach
    public void beforeEach() {

        assertNotNull(restApiServiceImpl);
        assertNotNull(restTemplate);
        assertNotNull(propertyLoader);

        this.pushInfoVo = PushInfoVo.builder()
                .token("token")
                .locale("fr_FR")
                .timezone("Europe/Paris")
                .build();

        when(this.propertyLoader.getServerCodeHost()).thenReturn("localhost");
        when(this.propertyLoader.getServerCodePort()).thenReturn("8080");
        when(this.propertyLoader.getServerCodeVerificationPath()).thenReturn("/api/v1/verify");

        when(this.propertyLoader.getPushServerHost()).thenReturn(this.pushServerHost);
        when(this.propertyLoader.getPushServerPort()).thenReturn(this.pushServerPort);
        when(this.propertyLoader.getInternalPathPrefix()).thenReturn(this.internalPathPrefix);
        when(this.propertyLoader.getPushApiVersion()).thenReturn(this.pushApiVersion);
        when(this.propertyLoader.getPushApiPath()).thenReturn(this.pushApiPath);
        when(this.propertyLoader.getPushApiTokenPath()).thenReturn(this.pushApiTokenPath);
    }

    @Test
    public void testVerifyReportTokenWhenTokenIsNullFails() {

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken(null, "notEmpty");

        // Then
        assertFalse(response.isPresent());
        verify(this.restTemplate, never()).getForEntity(any(URI.class), any());
    }

    @Test
    public void testVerifyReportTokenWhenTokenIsEmptyFails() {

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken("", "notEmpty");

        // Then
        assertFalse(response.isPresent());
        verify(this.restTemplate, never()).getForEntity(any(URI.class), any());
    }

    @Test
    public void testVerifyReportTokenWhenTypeIsNullFails() {

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken("token", null);

        // Then
        assertFalse(response.isPresent());
        verify(this.restTemplate, never()).getForEntity(any(URI.class), any());
    }

    @Test
    public void testVerifyReportTokenWhenTypeIsEmptyFails() {

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken("token", "");

        // Then
        assertFalse(response.isPresent());
        verify(this.restTemplate, never()).getForEntity(any(URI.class), any());
    }

    @Test
    public void testVerifyReportTokenAnExceptionIsThrownFails() {

        // Given
        when(this.restTemplate.getForEntity(any(URI.class), any())).thenThrow(
                new HttpClientErrorException(HttpStatus.BAD_REQUEST));

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken("token", "type");

        // Then
        assertFalse(response.isPresent());
        verify(this.restTemplate).getForEntity(any(URI.class), any());
    }

    @Test
    public void testVerifyReportTokenShouldSucceed() {

        // Given
        VerifyResponseDto verified  = VerifyResponseDto.builder().valid(true).build();

        when(this.restTemplate.getForEntity(any(URI.class), any())).thenReturn(ResponseEntity.ok(verified));

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken("token", "type");

        // Then
        assertTrue(response.isPresent());
        assertEquals(verified, response.get());
        verify(this.restTemplate).getForEntity(any(URI.class), any());
    }

    @Test
    public void testRegisterPushNotifShouldNotCallPushServerWhenPushInfoIsNull() {

        // Given
        PushInfoVo pushInfo = null;

        // When
        this.restApiServiceImpl.registerPushNotif(pushInfo);

        // Then
        verify(this.webClient, never()).post();
    }

    @Test
    public void testRegisterPushNotifShouldNotCallPushServerWhenPushInfoTokenIsNull() {

        // Given
        this.pushInfoVo.setToken(null);

        // When
        this.restApiServiceImpl.registerPushNotif(this.pushInfoVo);

        // Then
        verify(this.webClient, never()).post();
    }

    @Test
    public void testRegisterPushNotifShouldNotCallPushServerWhenPushInfoTokenIsBlank() {

        // Given
        this.pushInfoVo.setToken("");

        // When
        this.restApiServiceImpl.registerPushNotif(this.pushInfoVo);

        // Then
        verify(this.webClient, never()).post();
    }

    @Test
    public void testRegisterPushNotifShouldNotCallPushServerWhenPushInfoLocaleIsNull() {

        // Given
        this.pushInfoVo.setToken(null);

        // When
        this.restApiServiceImpl.registerPushNotif(this.pushInfoVo);

        // Then
        verify(this.webClient, never()).post();
    }

    @Test
    public void testRegisterPushNotifShouldNotCallPushServerWhenPushInfoLocaleIsBlank() {

        // Given
        this.pushInfoVo.setLocale("");

        // When
        this.restApiServiceImpl.registerPushNotif(this.pushInfoVo);

        // Then
        verify(this.webClient, never()).post();
    }

    @Test
    public void testRegisterPushNotifShouldNotCallPushServerWhenPushInfoTimezoneIsNull() {

        // Given
        this.pushInfoVo.setTimezone(null);

        // When
        this.restApiServiceImpl.registerPushNotif(this.pushInfoVo);

        // Then
        verify(this.webClient, never()).post();
    }

    @Test
    public void testRegisterPushNotifShouldNotCallPushServerWhenPushInfoTimezoneIsBlank() {

        // Given
        this.pushInfoVo.setTimezone("");

        // When
        this.restApiServiceImpl.registerPushNotif(this.pushInfoVo);

        // Then
        verify(this.webClient, never()).post();

    }

    @Test
    public void testUnregisterPushNotifShouldNotCallPushServerWhenPushTokenIsNull() {

        // Given
        String pushToken = null;

        // When
        this.restApiServiceImpl.unregisterPushNotif(pushToken);

        // Then
        verify(this.webClient, never()).delete();
    }

}
