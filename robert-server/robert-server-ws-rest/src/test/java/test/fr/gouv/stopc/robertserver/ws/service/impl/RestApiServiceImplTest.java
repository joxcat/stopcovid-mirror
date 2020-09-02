package test.fr.gouv.stopc.robertserver.ws.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.net.URI;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import fr.gouv.stopc.robertserver.ws.dto.VerifyResponseDto;
import fr.gouv.stopc.robertserver.ws.service.impl.RestApiServiceImpl;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.PushInfoVo;

@ExtendWith(SpringExtension.class)
@TestPropertySource("classpath:application.properties")
public class RestApiServiceImplTest {

    private static final String SHOULD_NOT_FAIL = "It should not fail";

    @InjectMocks
    private RestApiServiceImpl restApiServiceImpl;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private PropertyLoader propertyLoader;

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

    @BeforeEach
    public void beforeEach() {

        assertNotNull(restApiServiceImpl);
        assertNotNull(restTemplate);
        assertNotNull(propertyLoader);

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
        verify(this.restTemplate, never()).postForEntity(any(URI.class), any(PushInfoVo.class), any());
    }

    @Test
    public void testRegisterPushNotifShouldNotThrownAnExceptionEvenIfCallFail() {

        // Given
        PushInfoVo pushInfo = PushInfoVo.builder().build();

        when(this.restTemplate.postForEntity(any(URI.class), any(PushInfoVo.class), any()))
        .thenThrow(new HttpClientErrorException(HttpStatus.BAD_REQUEST));

        // When
        this.restApiServiceImpl.registerPushNotif(pushInfo);

        // Then
        verify(this.restTemplate).postForEntity(any(URI.class), any(PushInfoVo.class), any());
    }

    @Test
    public void testRegisterPushNotifShouldCallPushServerWhenPushInfoIsNotNull() {

        try {
            // Given
            PushInfoVo pushInfo = PushInfoVo.builder().build();

            when(this.restTemplate.postForEntity(any(URI.class), any(PushInfoVo.class), any()))
            .thenReturn(ResponseEntity.status(HttpStatus.CREATED).build());

            // When
            this.restApiServiceImpl.registerPushNotif(pushInfo);

            // Then
            verify(this.restTemplate).postForEntity(any(URI.class), any(PushInfoVo.class), any());
        } catch (Exception e) {

            fail(SHOULD_NOT_FAIL);
        }
    }

    @Test
    public void testUnregisterPushNotifShouldNotCallPushServerWhenPushTokenIsNull() {

        // Given
        String pushToken = null;

        // When
        this.restApiServiceImpl.unregisterPushNotif(pushToken);

        // Then
        verify(this.restTemplate, never()).getForEntity(any(URI.class), any());
    }

    @Test
    public void testUnregisterPushNotifShouldNotCallPushServerWhenPushTokenIsEmpty() {

        // Given
        String pushToken = "";

        // When
        this.restApiServiceImpl.unregisterPushNotif(pushToken);

        // Then
        verify(this.restTemplate, never()).getForEntity(any(URI.class), any());
    }

    @Test
    public void testUnregisterPushNotifShouldCallPushServerWhenPushTokenIsNotEmpty() {

        try {
            // Given
            String pushToken = "token";

            when(this.restTemplate.exchange(this.buildRegistertPushNotifURI(pushToken), HttpMethod.DELETE, null, Object.class))
            .thenReturn(ResponseEntity.accepted().build());

            // When
            this.restApiServiceImpl.unregisterPushNotif(pushToken);

            // Then
            verify(this.restTemplate).exchange(this.buildRegistertPushNotifURI(pushToken), HttpMethod.DELETE, null, Object.class);

        } catch (Exception e) {
            fail(SHOULD_NOT_FAIL);
        }
    }

    @Test
    public void testUnregisterPushNotifShouldCallPushServerThrownAnExceptionEvenIfCallFail() {

        // Given
        String pushToken = "token";

        when(this.restTemplate.exchange(this.buildRegistertPushNotifURI(pushToken), HttpMethod.DELETE, null, Object.class))
        .thenThrow(new HttpClientErrorException(HttpStatus.BAD_REQUEST));


        // When
        this.restApiServiceImpl.unregisterPushNotif(pushToken);

        // Then
        verify(this.restTemplate).exchange(this.buildRegistertPushNotifURI(pushToken), HttpMethod.DELETE, null, Object.class);
    }

    private URI buildRegistertPushNotifURI(String pushToken) {

        Map<String, String> parameters = new HashMap<>();
        parameters.put("token", pushToken);

        return UriComponentsBuilder.newInstance().scheme("http")
                .host(this.propertyLoader.getPushServerHost())
                .port(this.propertyLoader.getPushServerPort())
                .path(this.propertyLoader.getInternalPathPrefix())
                .path(this.propertyLoader.getPushApiVersion())
                .path(this.propertyLoader.getPushApiPath())
                .path(this.propertyLoader.getPushApiTokenPath())
                .build(parameters);
    }
}
