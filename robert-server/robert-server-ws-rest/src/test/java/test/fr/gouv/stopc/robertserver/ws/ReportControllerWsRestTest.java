package test.fr.gouv.stopc.robertserver.ws;

import static fr.gouv.stopc.robertserver.ws.config.Config.API_V1;
import static fr.gouv.stopc.robertserver.ws.config.Config.API_V2;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.fail;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.atLeast;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.net.URI;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
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

import fr.gouv.stopc.robertserver.ws.RobertServerWsRestApplication;
import fr.gouv.stopc.robertserver.ws.dto.ReportBatchResponseDto;
import fr.gouv.stopc.robertserver.ws.dto.VerifyResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.ApiError;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.service.ContactDtoService;
import fr.gouv.stopc.robertserver.ws.service.IRestApiService;
import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import fr.gouv.stopc.robertserver.ws.utils.UriConstants;
import fr.gouv.stopc.robertserver.ws.vo.ContactVo;
import fr.gouv.stopc.robertserver.ws.vo.HelloMessageDetailVo;
import fr.gouv.stopc.robertserver.ws.vo.ReportBatchRequestVo;

@DirtiesContext(classMode = ClassMode.AFTER_EACH_TEST_METHOD)
@ExtendWith(SpringExtension.class)
@SpringBootTest(classes = { RobertServerWsRestApplication.class }, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource("classpath:application.properties")
public class ReportControllerWsRestTest {

    @Autowired
    private TestRestTemplate testRestTemplate;

    private HttpEntity<ReportBatchRequestVo> requestEntity;

    private HttpHeaders headers;

    @MockBean
    private ContactDtoService contactDtoService;

    @MockBean
    private IRestApiService restApiService;

    @Value("${controller.path.prefix}" + API_V1)
    private String pathPrefix_V1;

    @Value("${controller.path.prefix}" + API_V2)
    private String pathPrefix;

    private URI targetUrl;

    private final String token = "23DC4B32-7552-44C1-B98A-DDE5F75B1729";

    private final String contactsAsBinary = "contactsAsBinary";

	private List<ContactVo> contacts;

    private ReportBatchRequestVo reportBatchRequestVo;

    private static final String EXCEPTION_FAIL_MESSAGE = "Should not fail with exception";

    @BeforeEach
    public void setup() {

        this.headers = new HttpHeaders();
        this.headers.setContentType(MediaType.APPLICATION_JSON);

        this.targetUrl = UriComponentsBuilder.fromUriString(this.pathPrefix).path(UriConstants.REPORT).build().encode().toUri();

		HelloMessageDetailVo info = HelloMessageDetailVo.builder() //
			.timeCollectedOnDevice(1L) //
			.timeFromHelloMessage(1) //
			.mac("1") //
			.rssiCalibrated(20) //
			.build();

		ContactVo contact = ContactVo.builder().ecc("FR").ebid("ABCDEFGH").ids(Arrays.asList(info)).build();

        this.contacts = Arrays.asList(contact);

        this.reportBatchRequestVo = ReportBatchRequestVo.builder().token(this.token).contacts(this.contacts).build();
    }

    @Test
    public void testReportShouldNotAcceptInvalidTokenSizeSmall() {
        this.reportBatchRequestVo.setToken("1");
        try {
            // Given
            this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

            // When
            ResponseEntity<ApiError> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ApiError.class);

            // Then
            assertNotNull(response);
            assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
            assertNotNull(response.getBody());
            assertEquals(response.getBody(), buildApiError(MessageConstants.INVALID_DATA.getValue()));

            verify(this.contactDtoService, never()).saveContacts(any());
        } catch (RobertServerException e) {
            fail(EXCEPTION_FAIL_MESSAGE);
        }
    }

    @Test
    public void testReportShouldNotAcceptInvalidTokenSizeLarge() {
        this.reportBatchRequestVo.setToken("23DC4B32-7552-44C1-B98A-DDE5F75B1729" + "1");
        try {
            // Given
            this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

            // When
            ResponseEntity<ApiError> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ApiError.class);

            // Then
            assertNotNull(response);
            assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
            assertNotNull(response.getBody());
            assertEquals(response.getBody(), buildApiError(MessageConstants.INVALID_DATA.getValue()));

            verify(this.contactDtoService, never()).saveContacts(any());
        } catch (RobertServerException e) {
            fail(EXCEPTION_FAIL_MESSAGE);
        }
    }

    @Test
    public void testReportShouldNotAcceptInvalidTokenSizeIntermediate() {
        this.reportBatchRequestVo.setToken("23DC4B32-7552-44C1-B98A-DDE5F75B172");
        try {
            // Given
            this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

            // When
            ResponseEntity<ApiError> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ApiError.class);

            // Then
            assertNotNull(response);
            assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
            assertNotNull(response.getBody());
            assertEquals(response.getBody(), buildApiError(MessageConstants.INVALID_DATA.getValue()));

            verify(this.contactDtoService, never()).saveContacts(any());
        } catch (RobertServerException e) {
            fail(EXCEPTION_FAIL_MESSAGE);
        }
    }

    @Test
    public void testReportShouldNotAcceptNullContacts() {
        try {
            // Given
            this.reportBatchRequestVo.setContacts(null);
            this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

            // When
            ResponseEntity<ApiError> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ApiError.class);

            // Then
            assertNotNull(response);
            assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
            assertNull(response.getBody());

            verify(this.restApiService, never()).verifyReportToken(any(), any());
            verify(this.contactDtoService, never()).saveContacts(any());
        } catch (RobertServerException e) {
            fail(EXCEPTION_FAIL_MESSAGE);
        }
    }

    @Test
    public void testReportLargePayload() {
        try {
            // Given
            HelloMessageDetailVo info = HelloMessageDetailVo.builder() //
                    .timeCollectedOnDevice(3797833665L) //
                    .timeFromHelloMessage(22465) //
                    .mac("MEjHn3mWfhGNhbAooSiVBbVoNayotrLhMPDI8l3tum0=").rssiCalibrated(0).build();

                ContactVo contact = ContactVo.builder().ecc("2g==").ebid("GTr1XTqVS5g=").ids(Arrays.asList(info)).build();


            this.contacts = Arrays.asList(contact);

            this.reportBatchRequestVo = ReportBatchRequestVo.builder().token(token).contacts(this.contacts).build();

            this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

            when(this.restApiService.verifyReportToken(token, "1")).thenReturn(Optional.of(VerifyResponseDto.builder().valid(true).build()));

            // When
            ResponseEntity<ReportBatchResponseDto> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ReportBatchResponseDto.class);

            // Then
            assertNotNull(response);
            assertEquals(HttpStatus.OK, response.getStatusCode());
            assertNotNull(response.getHeaders());
            assertEquals(MediaType.APPLICATION_JSON, response.getHeaders().getContentType());
            assertNotNull(response.getBody());
            assertThat(response.getBody(), equalTo(buildReportBatchResponseDto()));
            verify(this.contactDtoService, atLeast(1)).saveContacts(any());
        } catch (RobertServerException e) {
            fail(EXCEPTION_FAIL_MESSAGE);
        }
    }

    /** Test the access for API V1, should not be used since API V2 */
    @Test
    public void testAccessV1() {
    	reportContactHistorySucceeds(UriComponentsBuilder.fromUriString(this.pathPrefix).path(UriConstants.REPORT).build().encode().toUri());
    }

    /** {@link #reportContactHistorySucceeds(URI)} and shortcut to test for API V2 exposure */
    @Test
    public void testReportContactHistorySucceedsV2() {
    	reportContactHistorySucceeds(this.targetUrl);
    }

    protected void reportContactHistorySucceeds(URI targetUrl) {

        try {
            // Given
            this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

            when(this.restApiService.verifyReportToken(token, "1")).thenReturn(Optional.of(VerifyResponseDto.builder().valid(true).build()));

            // When
            ResponseEntity<ReportBatchResponseDto> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ReportBatchResponseDto.class);

            // Then
            assertNotNull(response);
            assertEquals(HttpStatus.OK, response.getStatusCode());
            assertNotNull(response.getHeaders());
            assertEquals(MediaType.APPLICATION_JSON, response.getHeaders().getContentType());
            assertNotNull(response.getBody());
            assertThat(response.getBody(), equalTo(buildReportBatchResponseDto()));

            verify(this.restApiService).verifyReportToken(token, "1");
            verify(this.contactDtoService, atLeast(1)).saveContacts(any());
        } catch (RobertServerException e) {
            fail(EXCEPTION_FAIL_MESSAGE);
        }
    }

    @Test
    public void testReportContactHistorySucceedsWhenEmptyContacts() {

        try {
            // Given
            this.reportBatchRequestVo.setContacts(Collections.emptyList());
            this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

            when(this.restApiService.verifyReportToken(token, "1")).thenReturn(Optional.of(VerifyResponseDto.builder().valid(true).build()));

            // When
            ResponseEntity<ReportBatchResponseDto> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ReportBatchResponseDto.class);

            // Then
            assertNotNull(response);
            assertEquals(HttpStatus.OK, response.getStatusCode());
            assertNotNull(response.getHeaders());
            assertEquals(MediaType.APPLICATION_JSON, response.getHeaders().getContentType());
            assertNotNull(response.getBody());
            assertThat(response.getBody(), equalTo(buildReportBatchResponseDto()));

            verify(this.restApiService).verifyReportToken(token, "1");
            verify(this.contactDtoService, atLeast(1)).saveContacts(any());
        } catch (RobertServerException e) {
            fail(EXCEPTION_FAIL_MESSAGE);
        }
    }
    @Test
    public void testReportContacWhenContactsProvidedTwice() {

        try {
            // Given
            this.reportBatchRequestVo = ReportBatchRequestVo.builder().token(this.token).contacts(this.contacts).contactsAsBinary(this.contactsAsBinary).build();

            this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

            // When
            ResponseEntity<ReportBatchResponseDto> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ReportBatchResponseDto.class);

            // Then
            assertNotNull(response);
            assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());

            verify(this.restApiService, never()).verifyReportToken(any(), any());
            verify(this.contactDtoService, never()).saveContacts(any());
        } catch (RobertServerException e) {
            fail(EXCEPTION_FAIL_MESSAGE);
        }
    }

    @Test
    public void testReportContacWhenContactsNotProvided() {

        try {
            // Given
            this.reportBatchRequestVo = ReportBatchRequestVo.builder().token(this.token).build();

            this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

            // When
            ResponseEntity<ReportBatchResponseDto> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ReportBatchResponseDto.class);

            // Then
            assertNotNull(response);
            assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());

            verify(this.contactDtoService, never()).saveContacts(any());
        } catch (RobertServerException e) {
            fail(EXCEPTION_FAIL_MESSAGE);
        }
    }

    @Test
    public void testReportWhenTokenNotProvided() {

        try {
            // Given
            this.reportBatchRequestVo = ReportBatchRequestVo.builder().contacts(this.contacts).build();

            this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

            // When
            ResponseEntity<ReportBatchResponseDto> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ReportBatchResponseDto.class);

            // Then
            assertNotNull(response);
            assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
            verify(this.restApiService, never()).verifyReportToken(any(), any());
            verify(this.contactDtoService, never()).saveContacts(any());
        } catch (RobertServerException e) {

            fail("Should not fail");
        }
    }

    @Test
    public void testReportContactHistoryWhenUsingGetMethod() throws Exception {

        // Given
        this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

        // When
        ResponseEntity<String> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.GET, this.requestEntity, String.class);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.METHOD_NOT_ALLOWED, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(this.restApiService, never()).verifyReportToken(any(), any());
        verify(this.contactDtoService, never()).saveContacts(any());
    }

    @Test
    public void testReportContactHistoryWhenErrorOccurs() throws Exception {

        // Given
        this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

        when(this.restApiService.verifyReportToken(token, "1")).thenReturn(Optional.of(VerifyResponseDto.builder().valid(true).build()));

        doThrow(new RobertServerException(MessageConstants.ERROR_OCCURED)).when(this.contactDtoService).saveContacts(any());

        // When
        ResponseEntity<ApiError> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ApiError.class);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertNotNull(response.getHeaders());
        assertEquals(MediaType.APPLICATION_JSON, response.getHeaders().getContentType());
        assertNotNull(response.getBody());
        assertThat(response.getBody(), equalTo(buildApiError(MessageConstants.ERROR_OCCURED.getValue())));
        verify(this.restApiService).verifyReportToken(token, "1");
    }

    @Test
    public void testReportContactHistoryShouldFailWhenTokenVerificationFails() throws Exception {

        // Given
        this.requestEntity = new HttpEntity<>(this.reportBatchRequestVo, this.headers);

        when(this.restApiService.verifyReportToken(token, "1")).thenReturn(Optional.empty());

        // When
        ResponseEntity<ApiError> response = this.testRestTemplate.exchange(targetUrl, HttpMethod.POST, this.requestEntity, ApiError.class);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
        assertNotNull(response.getHeaders());
        assertEquals(MediaType.APPLICATION_JSON, response.getHeaders().getContentType());
        assertNotNull(response.getBody());
        assertThat(response.getBody(), equalTo(buildApiError(MessageConstants.INVALID_AUTHENTICATION.getValue())));
        verify(this.restApiService).verifyReportToken(token, "1");
        verify(this.contactDtoService, never()).saveContacts(any());

    }

    private ReportBatchResponseDto buildReportBatchResponseDto() {

        return ReportBatchResponseDto.builder().message(MessageConstants.SUCCESSFUL_OPERATION.getValue()).success(true).build();
    }

    private ApiError buildApiError(String message) {

        return ApiError.builder().message(message).build();
    }

}
