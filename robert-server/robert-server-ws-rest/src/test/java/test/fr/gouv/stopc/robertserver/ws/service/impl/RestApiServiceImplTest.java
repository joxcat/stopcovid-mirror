package test.fr.gouv.stopc.robertserver.ws.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.ArgumentMatchers.any;

import java.net.URI;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import fr.gouv.stopc.robertserver.ws.dto.VerifyResponseDto;
import fr.gouv.stopc.robertserver.ws.service.impl.RestApiServiceImpl;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;

@ExtendWith(SpringExtension.class)
public class RestApiServiceImplTest {

    @InjectMocks
    private RestApiServiceImpl restApiServiceImpl;

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private PropertyLoader propertyLoader;

    @BeforeEach
    public void beforeEach() {

        assertNotNull(restApiServiceImpl);
        assertNotNull(restTemplate);
        assertNotNull(propertyLoader);

        when(this.propertyLoader.getServerCodeHost()).thenReturn("localhost");
        when(this.propertyLoader.getServerCodePort()).thenReturn("8080");
        when(this.propertyLoader.getServerCodeVerificationPath()).thenReturn("/api/v1/verify");
    }

    @Test
    public void testVerifyReportTokenWhenTokenIsNullFails() {

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken(null, "notEmpty");

        // Then
        assertFalse(response.isPresent());
        verify(this.restTemplate, never()).getForEntity(any(URI.class), any(Class.class));
    }

    @Test
    public void testVerifyReportTokenWhenTokenIsEmptyFails() {

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken("", "notEmpty");

        // Then
        assertFalse(response.isPresent());
        verify(this.restTemplate, never()).getForEntity(any(URI.class), any(Class.class));
    }

    @Test
    public void testVerifyReportTokenWhenTypeIsNullFails() {

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken("token", null);

        // Then
        assertFalse(response.isPresent());
        verify(this.restTemplate, never()).getForEntity(any(URI.class), any(Class.class));
    }

    @Test
    public void testVerifyReportTokenWhenTypeIsEmptyFails() {

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken("token", "");

        // Then
        assertFalse(response.isPresent());
        verify(this.restTemplate, never()).getForEntity(any(URI.class), any(Class.class));
    }

    @Test
    public void testVerifyReportTokenAnExceptionIsThrownFails() {

        // Given
        when(this.restTemplate.getForEntity(any(URI.class), any(Class.class))).thenThrow(
        new HttpClientErrorException(HttpStatus.BAD_REQUEST));

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken("token", "type");

        // Then
        assertFalse(response.isPresent());
        verify(this.restTemplate).getForEntity(any(URI.class), any(Class.class));
    }

    @Test
    public void testVerifyReportTokenShouldSucceed() {

        // Given
        VerifyResponseDto verified  = VerifyResponseDto.builder().valid(true).build();

        when(this.restTemplate.getForEntity(any(URI.class), any(Class.class))).thenReturn(ResponseEntity.ok(verified));

        // When
        Optional<VerifyResponseDto> response = this.restApiServiceImpl.verifyReportToken("token", "type");

        // Then
        assertTrue(response.isPresent());
        assertEquals(verified, response.get());
        verify(this.restTemplate).getForEntity(any(URI.class), any(Class.class));
    }
}
