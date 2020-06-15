package test.fr.gouv.stopc.robertserver.ws;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.net.URI;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import javax.crypto.KeyGenerator;
import javax.inject.Inject;

import org.bson.internal.Base64;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentMatchers;
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

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromStatusResponse;
import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoSkinny64;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.impl.RegistrationService;
import fr.gouv.stopc.robertserver.ws.RobertServerWsRestApplication;
import fr.gouv.stopc.robertserver.ws.config.RobertServerWsConfiguration;
import fr.gouv.stopc.robertserver.ws.dto.StatusResponseDto;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.utils.UriConstants;
import fr.gouv.stopc.robertserver.ws.vo.StatusVo;
import lombok.extern.slf4j.Slf4j;

@DirtiesContext(classMode = ClassMode.BEFORE_CLASS)
@ExtendWith(SpringExtension.class)
@SpringBootTest(classes = {
        RobertServerWsRestApplication.class }, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource("classpath:application.properties")
@Slf4j
public class StatusControllerWsRestTest {

    @Value("${controller.path.prefix}")
    private String pathPrefix;

    @Inject
    private TestRestTemplate restTemplate;

    HttpEntity<StatusVo> requestEntity;

    private URI targetUrl;

    private StatusVo statusBody;

    private HttpHeaders headers;

    @MockBean
    private RegistrationService registrationService;

    @Autowired
    private CryptoService cryptoService;

    @MockBean
    private ICryptoServerGrpcClient cryptoServerClient;

    @Autowired
    private IServerConfigurationService serverConfigurationService;

    @MockBean
    private PropertyLoader propertyLoader;

    @MockBean
    private RobertServerWsConfiguration config;

    private int currentEpoch;

    private byte[] serverKey;

    @BeforeEach
    public void before() {
        assert (this.restTemplate != null);
        this.headers = new HttpHeaders();
        this.headers.setContentType(MediaType.APPLICATION_JSON);
        this.targetUrl = UriComponentsBuilder.fromUriString(this.pathPrefix).path(UriConstants.STATUS).build().encode().toUri();

        this.currentEpoch = this.getCurrentEpoch();

        when(this.propertyLoader.getEsrLimit()).thenReturn(-1);
        when(this.propertyLoader.getRequestTimeDeltaTolerance()).thenReturn(60);
        doReturn(2).when(this.propertyLoader).getStatusRequestMinimumEpochGap();
        this.serverKey = this.generateKey(24);
    }

    @Test
    public void testBadHttpVerbFails() {
        this.statusBody = StatusVo.builder().ebid(Base64.encode(new byte[4])).build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        ResponseEntity<String> response = this.restTemplate.exchange(this.targetUrl.toString(), HttpMethod.GET,
                this.requestEntity, String.class);

        log.info("******* Bad HTTP Verb Payload: {}", response.getBody());

        assertEquals(HttpStatus.METHOD_NOT_ALLOWED, response.getStatusCode());
        verify(this.registrationService, times(0)).findById(ArgumentMatchers.any());
        verify(this.registrationService, times(0)).saveRegistration(ArgumentMatchers.any());
    }

    @Test
    public void testBadEBIDSizeFails() {
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(true)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch - 3).build();

        doReturn(Optional.of(reg)).when(this.registrationService).findById(ArgumentMatchers.any());

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

        statusBody = StatusVo.builder()
                .ebid(Base64.encode("ABC".getBytes()))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2])).build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        verify(this.registrationService, times(0)).findById(ArgumentMatchers.any());
        verify(this.registrationService, times(0)).saveRegistration(reg);
    }

    @Test
    public void testAcceptsOldEBIDValueEpochSucceeds() {

        int oldEpoch = currentEpoch - 10;

        // Given
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        // Mess up with the epoch used to create the EBID
        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, oldEpoch);
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(true)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch - 3).build();

        byte[] decryptedEbid = new byte[8];
        System.arraycopy(idA, 0, decryptedEbid, 3, 5);
        System.arraycopy(ByteUtils.intToBytes(oldEpoch), 1, decryptedEbid, 0, 3);

        doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

        doReturn(Optional.of(GetIdFromStatusResponse.newBuilder()
                .setEpochId(oldEpoch)
                .setIdA(ByteString.copyFrom(idA))
                .setTuples(ByteString.copyFrom("EncryptedJSONStringWithTuples".getBytes()))
                .build()))
                .when(this.cryptoServerClient).getIdFromStatus(any());

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2])).build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(this.registrationService, times(1)).findById(ArgumentMatchers.any());
        verify(this.registrationService, times(1)).saveRegistration(reg);
    }

    @Test
    public void testBadEBIDValueIdFails() {

        // Given
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();

        // Use unknown Id when creating the EBID
        byte[] modifiedIdA = new byte[5];
        System.arraycopy(idA, 0, modifiedIdA, 0, 5);
        modifiedIdA[4] = (byte)(modifiedIdA[4] ^ 0x4);

        byte[][] reqContent = createEBIDTimeMACFor(modifiedIdA, kA, currentEpoch);

        doReturn(Optional.of(GetIdFromStatusResponse.newBuilder()
                .setEpochId(currentEpoch)
                .setIdA(ByteString.copyFrom(modifiedIdA))
                .setTuples(ByteString.copyFrom("Base64encodedEncryptedJSONStringWithTuples".getBytes()))
                .build()))
                .when(this.cryptoServerClient).getIdFromStatus(any());
        when(this.registrationService.findById(modifiedIdA)).thenReturn(Optional.empty());

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2]))
                .build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        // When
        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        // Then
        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        verify(this.registrationService, times(1)).findById(ArgumentMatchers.any());
        verify(this.registrationService, times(0)).saveRegistration(ArgumentMatchers.any());
    }

    @Test
    public void testBadTimeFutureFails() {

        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(true)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch - 3).build();

        doReturn(Optional.of(reg)).when(this.registrationService).findById(ArgumentMatchers.any());

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch, 0 - (this.propertyLoader.getRequestTimeDeltaTolerance() + 1));

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2]))
                .build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        verify(this.registrationService, times(0)).findById(ArgumentMatchers.any());
        verify(this.registrationService, times(0)).saveRegistration(reg);
    }

    @Test
    public void testBadTimePastFails() {
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(true)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch - 3).build();

        doReturn(Optional.of(reg)).when(this.registrationService).findById(ArgumentMatchers.any());

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch, 0 - (this.propertyLoader.getRequestTimeDeltaTolerance() + 1));

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2]))
                .build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        verify(this.registrationService, times(0)).findById(ArgumentMatchers.any());
        verify(this.registrationService, times(0)).saveRegistration(reg);
    }

    @Test
    public void testBadTimeSizeFails() {
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(true)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch - 3).build();

        doReturn(Optional.of(reg)).when(this.registrationService).findById(ArgumentMatchers.any());

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode("AB".getBytes()))
                .mac(Base64.encode(reqContent[2]))
                .build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);


        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        verify(this.registrationService, times(0)).findById(ArgumentMatchers.any());
        verify(this.registrationService, times(0)).saveRegistration(reg);
    }

    @Test
    public void testBadMACSizeFails() {
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(true)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch - 3).build();

        doReturn(Optional.of(reg)).when(this.registrationService).findById(ArgumentMatchers.any());

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode("ABC".getBytes()))
                .build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        verify(this.registrationService, times(0)).findById(ArgumentMatchers.any());
        verify(this.registrationService, times(0)).saveRegistration(reg);
    }

    @Test
    public void testBadMACValueFails() {

        // Given
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(true)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch - 3).build();

        doReturn(Optional.of(reg)).when(this.registrationService).findById(ArgumentMatchers.any());

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

        doReturn(Optional.empty())
                .when(this.cryptoServerClient).getIdFromStatus(any());

        // Mess up with MAC
        reqContent[2][3] = 0x00;

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2]))
                .build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        // When
        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        // Given
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        verify(this.registrationService, times(0)).findById(ArgumentMatchers.any());
        verify(this.registrationService, times(0)).saveRegistration(reg);
    }

    public byte[] generateKA() {
        byte[] ka = null;

        try {
            KeyGenerator keyGen = KeyGenerator.getInstance("HmacSHA256");

            // Creating a SecureRandom object
            SecureRandom secRandom = new SecureRandom();

            // Initializing the KeyGenerator
            keyGen.init(secRandom);

            // Creating/Generating a key
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

        System.arraycopy(tsInSecondsB, 4, time, 0, 4);

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
        // Merge arrays
        // HMAC-256
        // return hash
        byte[] agg = new byte[8 + 4];
        System.arraycopy(ebid, 0, agg, 0, ebid.length);
        System.arraycopy(time, 0, agg, ebid.length, time.length);

        byte[] mac = new byte[32];
        try {
            mac = this.generateHMAC(new CryptoHMACSHA256(ka), agg, DigestSaltEnum.STATUS);
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
            res[0] = this.cryptoService.generateEBID(new CryptoSkinny64(this.serverKey),
                    currentEpoch, id);
            res[1] = this.generateTime32(adjustTimeBySeconds);
            res[2] = this.generateMACforESR(res[0], res[1], ka);
        } catch (Exception e) {
            log.info("Problem creating EBID, Time and MAC for test");
        }
        return res;
    }

    @Test
    public void testStatusRequestAtRiskSucceeds() {

        // Given
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(true)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch - 3).build();

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2]))
                .build();

        byte[] decryptedEbid = new byte[8];
        System.arraycopy(idA, 0, decryptedEbid, 3, 5);
        System.arraycopy(ByteUtils.intToBytes(currentEpoch), 1, decryptedEbid, 0, 3);

        doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

        doReturn(Optional.of(GetIdFromStatusResponse.newBuilder()
                    .setEpochId(currentEpoch)
                    .setIdA(ByteString.copyFrom(idA))
                    .setTuples(ByteString.copyFrom("Base64encodedEncryptedJSONStringWithTuples".getBytes()))
                    .build()))
                .when(this.cryptoServerClient).getIdFromStatus(any());

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        // When
        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody().isAtRisk());
        assertNotNull(response.getBody().getTuples());
        assertTrue(reg.isNotified());
        assertTrue(currentEpoch - 3 < reg.getLastStatusRequestEpoch());
        verify(this.registrationService, times(1)).findById(idA);
        verify(this.registrationService, times(1)).saveRegistration(reg);
    }

    @Test
    public void testStatusRequestNotAtRiskSucceeds() {

        // Given
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(false)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch - 3).build();

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2])).build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        byte[] decryptedEbid = new byte[8];
        System.arraycopy(idA, 0, decryptedEbid, 3, 5);
        System.arraycopy(ByteUtils.intToBytes(currentEpoch), 1, decryptedEbid, 0, 3);

        doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

        doReturn(Optional.of(GetIdFromStatusResponse.newBuilder()
                .setEpochId(currentEpoch)
                .setIdA(ByteString.copyFrom(idA))
                .setTuples(ByteString.copyFrom("Base64encodedEncryptedJSONStringWithTuples".getBytes()))
                .build()))
                .when(this.cryptoServerClient).getIdFromStatus(any());

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        // When
        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(!response.getBody().isAtRisk());
        assertNotNull(response.getBody().getTuples());
        assertTrue(currentEpoch - 3 < reg.getLastStatusRequestEpoch());
        verify(this.registrationService, times(1)).findById(idA);
        verify(this.registrationService, times(1)).saveRegistration(reg);
    }

    @Test
    public void testStatusRequestNoNewRiskSinceLastNotifSucceeds() {
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();

        List<EpochExposition> epochExpositions = new ArrayList<>();

        // Before latest notification
        epochExpositions.add(EpochExposition.builder()
                .epochId(currentEpoch - 9)
                .expositionScores(Arrays.asList(3.00, 4.30))
                .build());

        epochExpositions.add(EpochExposition.builder()
                .epochId(currentEpoch - 4)
                .expositionScores(Arrays.asList(0.076, 0.15))
                .build());

        epochExpositions.add(EpochExposition.builder()
                .epochId(currentEpoch - 3)
                .expositionScores(Arrays.asList(0.052, 0.16))
                .build());

        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(false)
                .isNotified(true)
                .lastStatusRequestEpoch(currentEpoch - 3)
                .latestRiskEpoch(currentEpoch - 8)
                .exposedEpochs(epochExpositions)
                .build();


        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

        byte[] decryptedEbid = new byte[8];
        System.arraycopy(idA, 0, decryptedEbid, 3, 5);
        System.arraycopy(ByteUtils.intToBytes(currentEpoch), 1, decryptedEbid, 0, 3);

        doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

        doReturn(Optional.of(GetIdFromStatusResponse.newBuilder()
                .setEpochId(currentEpoch)
                .setIdA(ByteString.copyFrom(idA))
                .setTuples(ByteString.copyFrom("Base64encodedEncryptedJSONStringWithTuples".getBytes()))
                .build()))
                .when(this.cryptoServerClient).getIdFromStatus(any());

        doReturn(Optional.of(reg)).when(this.registrationService).saveRegistration(reg);

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2]))
                .build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(currentEpoch, reg.getLastStatusRequestEpoch());
        assertEquals(false, response.getBody().isAtRisk());
        assertNotNull(response.getBody().getTuples());
        assertEquals(false, reg.isAtRisk());
        assertEquals(true, reg.isNotified());
        verify(this.registrationService, times(1)).findById(idA);
        verify(this.registrationService, times(1)).saveRegistration(reg);
    }

    @Test
    public void testStatusRequestNewRiskSinceLastNotifSucceeds() {
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();

        List<EpochExposition> epochExpositions = new ArrayList<>();

        // Before latest notification
        epochExpositions.add(EpochExposition.builder()
                .epochId(currentEpoch - 7)
                .expositionScores(Arrays.asList(3.00, 4.30))
                .build());

        epochExpositions.add(EpochExposition.builder()
                .epochId(currentEpoch - 4)
                .expositionScores(Arrays.asList(0.076, 0.15))
                .build());

        epochExpositions.add(EpochExposition.builder()
                .epochId(currentEpoch - 3)
                .expositionScores(Arrays.asList(0.052, 0.16))
                .build());

        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(true)
                .isNotified(true)
                .lastStatusRequestEpoch(currentEpoch - 3)
                .latestRiskEpoch(currentEpoch - 8)
                .exposedEpochs(epochExpositions)
                .build();

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

        byte[] decryptedEbid = new byte[8];
        System.arraycopy(idA, 0, decryptedEbid, 3, 5);
        System.arraycopy(ByteUtils.intToBytes(currentEpoch), 1, decryptedEbid, 0, 3);

        doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

        doReturn(Optional.of(GetIdFromStatusResponse.newBuilder()
                .setEpochId(currentEpoch)
                .setIdA(ByteString.copyFrom(idA))
                .setTuples(ByteString.copyFrom("Base64encodedEncryptedJSONStringWithTuples".getBytes()))
                .build()))
                .when(this.cryptoServerClient).getIdFromStatus(any());

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2]))
                .build();

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(currentEpoch, reg.getLastStatusRequestEpoch());
        assertEquals(true, response.getBody().isAtRisk());
        assertNotNull(response.getBody().getTuples());
        assertEquals(false, reg.isAtRisk());
        assertEquals(true, reg.isNotified());
        verify(this.registrationService, times(1)).findById(idA);
        verify(this.registrationService, times(1)).saveRegistration(reg);
    }

    @Test
    public void testStatusRequestESRThrottleFails() {

        // Given
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(false)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch).build();

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2])).build();

        byte[] decryptedEbid = new byte[8];
        System.arraycopy(idA, 0, decryptedEbid, 3, 5);
        System.arraycopy(ByteUtils.intToBytes(currentEpoch), 1, decryptedEbid, 0, 3);

        doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

        doReturn(Optional.of(GetIdFromStatusResponse.newBuilder()
                .setEpochId(currentEpoch)
                .setIdA(ByteString.copyFrom(idA))
                .setTuples(ByteString.copyFrom("Base64encodedEncryptedJSONStringWithTuples".getBytes()))
                .build()))
                .when(this.cryptoServerClient).getIdFromStatus(any());

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);


        // When
        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        // Then
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(currentEpoch, reg.getLastStatusRequestEpoch());
        verify(this.registrationService, times(1)).findById(idA);
        verify(this.registrationService, times(0)).saveRegistration(reg);
    }
    @Test
    public void testStatusRequestESRThrottleShouldSucceedsWhenLimitIsZero() {

        // Given
        byte[] idA = this.generateKey(5);
        byte[] kA = this.generateKA();
        Registration reg = Registration.builder()
                .permanentIdentifier(idA)
                .atRisk(true)
                .isNotified(false)
                .lastStatusRequestEpoch(currentEpoch - 3).build();

        byte[][] reqContent = createEBIDTimeMACFor(idA, kA, currentEpoch);

        statusBody = StatusVo.builder()
                .ebid(Base64.encode(reqContent[0]))
                .epochId(currentEpoch)
                .time(Base64.encode(reqContent[1]))
                .mac(Base64.encode(reqContent[2]))
                .build();

        byte[] decryptedEbid = new byte[8];
        System.arraycopy(idA, 0, decryptedEbid, 3, 5);
        System.arraycopy(ByteUtils.intToBytes(currentEpoch), 1, decryptedEbid, 0, 3);

        doReturn(Optional.of(reg)).when(this.registrationService).findById(idA);

        doReturn(Optional.of(GetIdFromStatusResponse.newBuilder()
                    .setEpochId(currentEpoch)
                    .setIdA(ByteString.copyFrom(idA))
                    .setTuples(ByteString.copyFrom("Base64encodedEncryptedJSONStringWithTuples".getBytes()))
                    .build()))
                .when(this.cryptoServerClient).getIdFromStatus(any());

        when(this.propertyLoader.getEsrLimit()).thenReturn(0);

        this.requestEntity = new HttpEntity<>(this.statusBody, this.headers);

        // When
        ResponseEntity<StatusResponseDto> response = this.restTemplate.exchange(this.targetUrl.toString(),
                HttpMethod.POST, this.requestEntity, StatusResponseDto.class);

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(currentEpoch, reg.getLastStatusRequestEpoch());
        assertEquals(true, response.getBody().isAtRisk());
        assertNotNull(response.getBody().getTuples());
        assertEquals(false, reg.isAtRisk());
        assertEquals(true, reg.isNotified());
        verify(this.registrationService, times(1)).findById(idA);
        verify(this.registrationService, times(1)).saveRegistration(reg);
    }
}
