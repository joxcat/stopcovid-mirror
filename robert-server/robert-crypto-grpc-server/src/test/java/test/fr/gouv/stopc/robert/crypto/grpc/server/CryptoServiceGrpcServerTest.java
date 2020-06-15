package test.fr.gouv.stopc.robert.crypto.grpc.server;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.when;

import java.io.IOException;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import javax.crypto.KeyGenerator;
import javax.crypto.spec.SecretKeySpec;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.CryptoServiceGrpcServer;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.*;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplImplBase;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplStub;
import fr.gouv.stopc.robert.crypto.grpc.server.service.ICryptoServerConfigurationService;
import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.CryptoGrpcServiceBaseImpl;
import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.ECDHKeyServiceImpl;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.cryptographic.service.ICryptographicStorageService;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.model.ClientIdentifierBundle;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.service.IClientKeyStorageService;
import fr.gouv.stopc.robert.crypto.grpc.server.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.service.impl.CryptoServiceImpl;
import fr.gouv.stopc.robert.server.crypto.structure.CryptoAES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESECB;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESGCM;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoSkinny64;
import io.grpc.ManagedChannel;
import io.grpc.inprocess.InProcessChannelBuilder;
import io.grpc.inprocess.InProcessServerBuilder;
import io.grpc.stub.StreamObserver;
import io.grpc.testing.GrpcCleanupRule;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import test.fr.gouv.stopc.robert.crypto.grpc.server.utils.CryptoTestUtils;

@Slf4j
@ExtendWith(SpringExtension.class)
class CryptoServiceGrpcServerTest {

    private final static String UNEXPECTED_FAILURE_MESSAGE = "Should not fail";
    private final static byte[] SERVER_COUNTRY_CODE = new byte[] { (byte) 0x21 };
    private final static int NUMBER_OF_DAYS_FOR_BUNDLES = 4;

    private final static int MAX_EPOCH_DOUBLE_KS_CHECK = 672;

    final GrpcCleanupRule grpcCleanup = new GrpcCleanupRule();

    private ManagedChannel inProcessChannel;

    private CryptoServiceGrpcServer server;

    private CryptoGrpcServiceImplImplBase service;

    private ICryptoServerConfigurationService serverConfigurationService;

    private CryptoService cryptoService;

    @InjectMocks
    private ECDHKeyServiceImpl keyService;

    private IClientKeyStorageService clientStorageService;

    @Mock
    private ICryptographicStorageService cryptographicStorageService;

    @Mock
    private PropertyLoader propertyLoader;

    private int currentEpochId;

    private Key federationKey;

    @BeforeEach
    void beforeEach() throws IOException {

        serverConfigurationService = new ICryptoServerConfigurationService() {
           long timeStartNtp = TimeUtils.convertUnixStoNtpSeconds(LocalDate.of(2020, 6, 1).atStartOfDay().toEpochSecond(ZoneOffset.UTC));

           @Override
            public long getServiceTimeStart() {
                return timeStartNtp;
            }

        };

        cryptoService = new CryptoServiceImpl();

        clientStorageService = new MockClientKeyStorageService();

        service = new CryptoGrpcServiceBaseImpl(serverConfigurationService,
                cryptoService,
                keyService,
                clientStorageService,
                cryptographicStorageService,
                propertyLoader);

        when(this.cryptographicStorageService.getServerKeyPair())
        .thenReturn(Optional.ofNullable(CryptoTestUtils.generateECDHKeyPair()));

        when(this.propertyLoader.getHelloMessageTimeStampTolerance())
        .thenReturn(180);

        byte[] keyToEncodeKeys = new byte[32];
        new SecureRandom().nextBytes(keyToEncodeKeys);
        SecretKeySpec secretKey = new SecretKeySpec(keyToEncodeKeys, "AES");
        when(this.cryptographicStorageService.getKeyForEncryptingClientKeys()).thenReturn(secretKey);

        String serverName = InProcessServerBuilder.generateName();

        server = new CryptoServiceGrpcServer(
                InProcessServerBuilder.forName(serverName)
                .directExecutor(),
                0,
                service);
        server.start();
        inProcessChannel = grpcCleanup.register(
                InProcessChannelBuilder.forName(serverName).directExecutor().build());

        this.currentEpochId = TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart());

        this.federationKey = new SecretKeySpec(CryptoTestUtils.generateKey(32), CryptoAES.AES_ENCRYPTION_KEY_SCHEME);

        when(this.cryptographicStorageService.getFederationKey()).thenReturn(this.federationKey);
    }

    @AfterEach
    void tearDown() throws Exception {
        server.stop();
    }

    @Test
    void testCreateRegistrationSucceeds() {
        // Given
        CreateRegistrationRequest request = CreateRegistrationRequest
                .newBuilder()
                .setClientPublicKey(ByteString.copyFrom(CryptoTestUtils.generateECDHPublicKey()))
                .setFromEpochId(this.currentEpochId)
                .setNumberOfDaysForEpochBundles(NUMBER_OF_DAYS_FOR_BUNDLES)
                .setServerCountryCode(ByteString.copyFrom(SERVER_COUNTRY_CODE))
                .build();

        byte[][] serverKeys = generateRandomServerKeys();

        doReturn(serverKeys).when(this.cryptographicStorageService).getServerKeys(
                this.currentEpochId,
                this.serverConfigurationService.getServiceTimeStart(),
                4);

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        CreateRegistrationResponse createRegistrationResponse =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.createRegistration(req, observer),
                        (t) -> fail(),
                        res);

        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(createRegistrationResponse.getIdA().toByteArray()));
        byte[] tuples = createRegistrationResponse.getTuples().toByteArray();
        assertTrue(ByteUtils.isNotEmpty(tuples));
        assertTrue(checkTuples(createRegistrationResponse.getIdA().toByteArray(), tuples, this.currentEpochId, serverKeys));
    }

    private byte[] getIdFromDecryptedEBID(byte[] ebid) {
        byte[] idA = new byte[5];
        System.arraycopy(ebid, 3, idA, 0, idA.length);
        return idA;
    }

    private int getEpochIdFromDecryptedEBID(byte[] ebid) {
        byte[] epochId = new byte[3];
        System.arraycopy(ebid, 0, epochId, 0, epochId.length);
        return ByteUtils.convertEpoch24bitsToInt(epochId);
    }

    private boolean checkTuplesForDay(List<CryptoGrpcServiceBaseImpl.EphemeralTupleJson> tuples, byte[] key) {
        byte[] id = null;
        boolean atLeastOneError = false;
        for (CryptoGrpcServiceBaseImpl.EphemeralTupleJson tuple : tuples) {
            int epochIdFromTuple = tuple.getEpochId();
            try {
                byte[] decryptedEbid = this.cryptoService.decryptEBID(new CryptoSkinny64(key), tuple.getKey().getEbid());
                byte[] idFromMessage = getIdFromDecryptedEBID(decryptedEbid);
                if (id == null) {
                    id = idFromMessage;
                } else {
                    if (!Arrays.equals(id, idFromMessage)) {
                        log.error("ids do not match from first message {} and from other message {}", id, idFromMessage);
                        atLeastOneError = true;
                    }
                }
                int epochIdFromMessage = getEpochIdFromDecryptedEBID(decryptedEbid);
                if (epochIdFromMessage != epochIdFromTuple) {
                    log.error("epoch ids do not match from message {} and from tuple {}", epochIdFromMessage, epochIdFromTuple);
                    atLeastOneError = true;
                }
            } catch (RobertServerCryptoException e) {
                atLeastOneError = true;
            }
        }
        return !atLeastOneError;
    }

    private boolean checkTuplesContentMatchesKeysForDays(Collection<CryptoGrpcServiceBaseImpl.EphemeralTupleJson> decodedTuples,
                                                      int epochId,
                                                      byte[][] serverKeys) {
        ArrayList<CryptoGrpcServiceBaseImpl.EphemeralTupleJson> list = new ArrayList(decodedTuples);

        int offset = TimeUtils.remainingEpochsForToday(epochId);
        int lowerBound = 0;
        ArrayList<Boolean> results = new ArrayList<>();
        for (int i = 0; i < serverKeys.length; i++) {
            List<CryptoGrpcServiceBaseImpl.EphemeralTupleJson> listToProcess = list.subList(lowerBound, offset);
            log.info("Chunking list of size {}", listToProcess.size());
            results.add(checkTuplesForDay(listToProcess, serverKeys[i]));
            lowerBound = offset;
            offset += 96;
        }
        return results.stream().allMatch(Boolean::valueOf);
    }

    private boolean checkTuples(byte[] id, byte[] tuples, int epochId, byte[][] serverKeys) {
        CryptoAESGCM aesGcm = new CryptoAESGCM(this.clientStorageService.findKeyById(id).get().getKeyForTuples());
        try {
            byte[] decryptedTuples = aesGcm.decrypt(tuples);
            ObjectMapper objectMapper = new ObjectMapper();
            Collection<CryptoGrpcServiceBaseImpl.EphemeralTupleJson> decodedTuples = objectMapper.readValue(
                    decryptedTuples,
                    new TypeReference<Collection<CryptoGrpcServiceBaseImpl.EphemeralTupleJson>>(){});
            boolean sizeMatches = ((NUMBER_OF_DAYS_FOR_BUNDLES - 1) * 96 + TimeUtils.remainingEpochsForToday(epochId)) == decodedTuples.size();

            return sizeMatches && checkTuplesContentMatchesKeysForDays(decodedTuples, epochId, serverKeys);
        } catch (RobertServerCryptoException | IOException e) {
            fail(UNEXPECTED_FAILURE_MESSAGE);
        }
        return false;
    }

    @Test
    void testCreateRegistrationFakeClientPublicKeyFails() {
        byte[] fakeKey = new byte[32];
        new SecureRandom().nextBytes(fakeKey);

        CreateRegistrationRequest request = CreateRegistrationRequest
                .newBuilder()
                .setClientPublicKey(ByteString.copyFrom(fakeKey))
                .setFromEpochId(this.currentEpochId)
                .setNumberOfDaysForEpochBundles(NUMBER_OF_DAYS_FOR_BUNDLES)
                .setServerCountryCode(ByteString.copyFrom(SERVER_COUNTRY_CODE))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        CreateRegistrationResponse createRegistrationResponse =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.createRegistration(req, observer),
                        (t) -> log.error(t.getMessage()),
                        res);

        assertNull(createRegistrationResponse);
        assertTrue(res.isError());
    }

    @Test
    void testCreateRegistrationClientPublicKeyNotECDHFails() {
        CreateRegistrationRequest request = CreateRegistrationRequest
                .newBuilder()
                .setClientPublicKey(ByteString.copyFrom(CryptoTestUtils.generateDHPublicKey()))
                .setFromEpochId(this.currentEpochId)
                .setNumberOfDaysForEpochBundles(NUMBER_OF_DAYS_FOR_BUNDLES)
                .setServerCountryCode(ByteString.copyFrom(SERVER_COUNTRY_CODE))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        CreateRegistrationResponse createRegistrationResponse =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.createRegistration(req, observer),
                        (t) -> assertNotNull(t),
                        res);

        assertNull(createRegistrationResponse);
        assertTrue(res.isError());
    }

    @Test
    void testCreateRegistrationClientPublicKeyImproperECFails() {
        // Client public key generated with EC curve "secp256k1" instead of server's choice of "secp256*r*1"
        CreateRegistrationRequest request = CreateRegistrationRequest
                .newBuilder()
                .setClientPublicKey(ByteString.copyFrom(CryptoTestUtils.generateECDHPublicKey("secp256k1")))
                .setFromEpochId(this.currentEpochId)
                .setNumberOfDaysForEpochBundles(NUMBER_OF_DAYS_FOR_BUNDLES)
                .setServerCountryCode(ByteString.copyFrom(SERVER_COUNTRY_CODE))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        CreateRegistrationResponse createRegistrationResponse =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.createRegistration(req, observer),
                        (t) -> assertNotNull(t),
                        res);

        assertNull(createRegistrationResponse);
        assertTrue(res.isError());
    }

    @AllArgsConstructor
    @NoArgsConstructor
    @Getter
    @Builder
    static class AuthRequestBundle {
        private byte[] ebid;
        private int epochId;
        private long time;
        private byte[] mac;
        private DigestSaltEnum requestType;
        private byte[] serverKey;
    }

    private Optional<ClientIdentifierBundle> createId() {
        byte[] keyForMac = new byte[32];
        byte[] keyForTuples = new byte[32];

        return this.clientStorageService.createClientIdUsingKeys(keyForMac, keyForTuples);
    }

    private byte[] generateMac(byte[] ebid, int epochId, long time, byte[] keyForMac, DigestSaltEnum digestSalt) {
        byte[] digest = new byte[] { digestSalt.getValue() };
        byte[] toHash = new byte[digest.length + ebid.length + Integer.BYTES + Integer.BYTES];
        System.arraycopy(digest, 0, toHash, 0, digest.length);
        System.arraycopy(ebid, 0, toHash, digest.length, ebid.length);
        System.arraycopy(ByteUtils.intToBytes(epochId), 0, toHash, digest.length + ebid.length, Integer.BYTES);
        System.arraycopy(ByteUtils.longToBytes(time), 4, toHash, digest.length + ebid.length + Integer.BYTES, Integer.BYTES);

        try {
            CryptoHMACSHA256 hmacsha256 = new CryptoHMACSHA256(keyForMac);
            return hmacsha256.encrypt(toHash);
        } catch (RobertServerCryptoException e) {
            fail();
        }
        return null;
    }

    private byte[] generateEbid(byte[] id, int epochId, byte[] ks) {
        byte[] decryptedEbid = new byte[8];
        System.arraycopy(ByteUtils.intToBytes(epochId), 1, decryptedEbid, 0, Integer.BYTES - 1);
        System.arraycopy(id, 0, decryptedEbid, Integer.BYTES - 1, id.length);

        CryptoSkinny64 cryptoSkinny64 = new CryptoSkinny64(ks);
        byte[] encryptedEbid = null;

        try {
            encryptedEbid = cryptoSkinny64.encrypt(decryptedEbid);
        } catch (RobertServerCryptoException e) {
            fail();
        }

        return encryptedEbid;
    }

    private long getCurrentTimeNTPSeconds() {
        return System.currentTimeMillis() / 1000 + 2208988800L;
    }

    private AuthRequestBundle generateAuthRequestBundleWithTimeDeltaAndOtherKS(byte[] id,
            byte[] keyForMac,
            DigestSaltEnum digestSalt,
            long timeDelta,
            OtherKSEnum otherKs) {

        long time = getCurrentTimeNTPSeconds();
        int epochId = TimeUtils.getNumberOfEpochsBetween(
                this.serverConfigurationService.getServiceTimeStart(),
                time - timeDelta);

        // Mock K_S
        byte[] ks = new byte[24];
        new SecureRandom().nextBytes(ks);

        byte[] ksPrevious = new byte[24];
        new SecureRandom().nextBytes(ksPrevious);
        byte[] ksNext = new byte[24];
        new SecureRandom().nextBytes(ksNext);

        byte[] ksToUseToEncryptEBID;
        switch(otherKs) {
            case PREVIOUS:
                ksToUseToEncryptEBID = ksPrevious;
                break;
            case NEXT:
                ksToUseToEncryptEBID = ksNext;
                break;
            case NONE:
            default:
                ksToUseToEncryptEBID = ks;
                break;
        }
        
        byte[] ebid = generateEbid(id, epochId, ksToUseToEncryptEBID);
        doReturn(Arrays.copyOf(ks, ks.length))
                .when(this.cryptographicStorageService).getServerKey(
                        epochId,
                        this.serverConfigurationService.getServiceTimeStart(),
                        false);
        doReturn(Arrays.copyOf(ksPrevious, ksPrevious.length))
                .when(this.cryptographicStorageService).getServerKey(
                        epochId,
                        this.serverConfigurationService.getServiceTimeStart(),
                        true);

        return new AuthRequestBundle().builder()
                .ebid(ebid)
                .epochId(epochId)
                .time(time)
                .mac(generateMac(ebid, epochId, time, keyForMac, digestSalt))
                .requestType(digestSalt)
                .serverKey(ks)
                .build();
    }

    private AuthRequestBundle generateAuthRequestBundle(byte[] id, byte[] keyForMac, DigestSaltEnum digestSalt) {
        return generateAuthRequestBundleWithTimeDeltaAndOtherKS(id, keyForMac, digestSalt, 0L, OtherKSEnum.NONE);
    }

    private enum OtherKSEnum {
        NONE,
        NEXT,
        PREVIOUS;
    }

    @Test
    void testGetIdFromAuthRequestSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY);

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType(bundle.getRequestType().getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
    }

    @Test
    void testGetIdFromAuthRequestWithOlderEBIDAndEpochSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundleWithTimeDeltaAndOtherKS(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY,
                900 * 3,
                OtherKSEnum.NONE); // ebid will be 3-epochs old

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType(bundle.getRequestType().getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
    }

    @Test
    void testGetIdFromAuthRequestFakeEBIDFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY);

        byte[] fakeEbid = new byte[8];
        new SecureRandom().nextBytes(fakeEbid);

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(fakeEbid))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType(bundle.getRequestType().getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromAuthRequestBadMacFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY);

        // Mess up with mac
        byte[] mac = new byte[32];
        System.arraycopy(bundle.getMac(), 0, mac, 0, bundle.getMac().length);
        mac[3] = (byte)(mac[3] ^ 0x4);

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(mac))
                .setRequestType(bundle.getRequestType().getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromAuthRequestMacWithBadRequestTypeFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.UNREGISTER);

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType(DigestSaltEnum.DELETE_HISTORY.getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromAuthRequestEpochIdsDoNotMatchFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY);

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId() + 1)
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType(bundle.getRequestType().getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromAuthRequestUnknownRequestTypeFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY);

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType((byte)0x7) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromAuthRequestNegativeTimeFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY);

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(0 - bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType(bundle.getRequestType().getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromAuthRequestUnknownIdFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();

        byte[] modifiedId = new byte[5];
        System.arraycopy(clientIdentifierBundle.get().getId(),
                0,
                modifiedId,
                0,
                clientIdentifierBundle.get().getId().length);

        // Modify ID slightly
        modifiedId[4] = (byte)(modifiedId[4] ^ 0x4);

        AuthRequestBundle bundle = generateAuthRequestBundle(
                modifiedId,
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY);

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType(bundle.getRequestType().getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromAuthWithEbidEncodedWithPreviousKSSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundleWithTimeDeltaAndOtherKS(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY,
                0L,
                OtherKSEnum.PREVIOUS);

        if (bundle.getEpochId() >= MAX_EPOCH_DOUBLE_KS_CHECK) {
            log.warn("Outside of K_S patch period ({}); current epoch: {}",
                    MAX_EPOCH_DOUBLE_KS_CHECK,
                    bundle.getEpochId());
            return;
        }

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType(bundle.getRequestType().getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
    }


    @Test
    void testGetIdFromAuthWithEbidEncodedWithFutureKSFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundleWithTimeDeltaAndOtherKS(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY,
                0L,
                OtherKSEnum.NEXT);

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType(bundle.getRequestType().getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
    }

    @Test
    void testGetIdFromAuthWithEbidEncodedWithPreviousKSAfterGracePeriodSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundleWithTimeDeltaAndOtherKS(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.DELETE_HISTORY,
                -270000L,
                OtherKSEnum.NONE);

        // Given
        GetIdFromAuthRequest request = GetIdFromAuthRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setRequestType(bundle.getRequestType().getValue()) // Select a request type
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromAuthResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromAuth(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
    }

    @Test
    void testDeleteIdSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.UNREGISTER);

        // Given
        DeleteIdRequest request = DeleteIdRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        DeleteIdResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.deleteId(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
    }

    @Test
    void testDeleteIdUnknownIdFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();

        byte[] modifiedId = new byte[5];
        System.arraycopy(clientIdentifierBundle.get().getId(),
                0,
                modifiedId,
                0,
                clientIdentifierBundle.get().getId().length);

        // Modify ID slightly
        modifiedId[4] = (byte)(modifiedId[4] ^ 0x4);

        AuthRequestBundle bundle = generateAuthRequestBundle(
                modifiedId,
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.UNREGISTER);

        // Given
        DeleteIdRequest request = DeleteIdRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        DeleteIdResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.deleteId(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
    }

    @Test
    void testDeleteIdFakeEBIDFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();

        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.UNREGISTER);

        byte[] fakeEbid = new byte[8];
        new SecureRandom().nextBytes(fakeEbid);

        // Given
        DeleteIdRequest request = DeleteIdRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(fakeEbid))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        DeleteIdResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.deleteId(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
    }

    @Test
    void testDeleteIdBadMacFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();

        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.UNREGISTER);

        // Mess up with mac
        byte[] mac = new byte[32];
        System.arraycopy(bundle.getMac(), 0, mac, 0, bundle.getMac().length);
        mac[3] = (byte)(mac[3] ^ 0x4);

        // Given
        DeleteIdRequest request = DeleteIdRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(mac))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        DeleteIdResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.deleteId(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
    }

    @Test
    void testDeleteIdEpochIdsDoNotMatchFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.UNREGISTER);

        // Given
        DeleteIdRequest request = DeleteIdRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId() + 1)
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        DeleteIdResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.deleteId(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testDeleteIdNegativeTimeFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.UNREGISTER);

        // Given
        DeleteIdRequest request = DeleteIdRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(0 - bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        DeleteIdResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.deleteId(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void tesDeleteIdWithEbidEncodedWithPreviousKSSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundleWithTimeDeltaAndOtherKS(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.UNREGISTER,
                0L,
                OtherKSEnum.PREVIOUS);

        if (bundle.getEpochId() >= MAX_EPOCH_DOUBLE_KS_CHECK) {
            log.warn("Outside of K_S patch period ({}); current epoch: {}",
                    MAX_EPOCH_DOUBLE_KS_CHECK,
                    bundle.getEpochId());
            return;
        }

        // Given
        DeleteIdRequest request = DeleteIdRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        DeleteIdResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.deleteId(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
    }

    @Test
    void testDeleteIdWithEbidEncodedWithFutureKSFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundleWithTimeDeltaAndOtherKS(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.UNREGISTER,
                0L,
                OtherKSEnum.NEXT);

        // Given
        DeleteIdRequest request = DeleteIdRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        DeleteIdResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.deleteId(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
    }

    @Test
    void testGetIdFromStatusSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.STATUS);

        byte[][] serverKeys = generateRandomServerKeys();

        when(this.cryptographicStorageService.getServerKeys(this.currentEpochId,
                this.serverConfigurationService.getServiceTimeStart(),
                4))
                .thenReturn(serverKeys);

        // Given
        GetIdFromStatusRequest request = GetIdFromStatusRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setFromEpochId(bundle.getEpochId())
                .setNumberOfDaysForEpochBundles(NUMBER_OF_DAYS_FOR_BUNDLES)
                .setServerCountryCode(ByteString.copyFrom(SERVER_COUNTRY_CODE))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromStatusResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromStatus(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
        assertTrue(checkTuples(response.getIdA().toByteArray(), response.getTuples().toByteArray(), this.currentEpochId, serverKeys));
    }

    private byte[][] generateRandomServerKeys() {
        byte[][] serverKeys = new byte[4][24];
        new SecureRandom().nextBytes(serverKeys[0]);
        new SecureRandom().nextBytes(serverKeys[1]);
        new SecureRandom().nextBytes(serverKeys[2]);
        new SecureRandom().nextBytes(serverKeys[3]);
        return serverKeys;
    }

    @Test
    void testGetIdFromStatusRequestWithOlderEBIDAndEpochSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundleWithTimeDeltaAndOtherKS(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.STATUS,
                900 * 3,
                OtherKSEnum.NONE); // ebid will be 3-epochs old

        byte[][] serverKeys = generateRandomServerKeys();
        when(this.cryptographicStorageService.getServerKeys(
                bundle.getEpochId(),
                this.serverConfigurationService.getServiceTimeStart(),
                4)).thenReturn(serverKeys);

        // Given
        GetIdFromStatusRequest request = GetIdFromStatusRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setFromEpochId(bundle.getEpochId())
                .setNumberOfDaysForEpochBundles(NUMBER_OF_DAYS_FOR_BUNDLES)
                .setServerCountryCode(ByteString.copyFrom(SERVER_COUNTRY_CODE))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromStatusResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromStatus(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
    }

    @Test
    void testGetIdFromStatusFakeEBIDFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.STATUS);

        byte[] fakeEbid = new byte[8];
        new SecureRandom().nextBytes(fakeEbid);

        // Given
        GetIdFromStatusRequest request = GetIdFromStatusRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(fakeEbid))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromStatusResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromStatus(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromStatusBadMacFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.STATUS);

        // Mess up with mac
        byte[] mac = new byte[32];
        System.arraycopy(bundle.getMac(), 0, mac, 0, bundle.getMac().length);
        mac[3] = (byte)(mac[3] ^ 0x4);

        // Given
        GetIdFromStatusRequest request = GetIdFromStatusRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(mac))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromStatusResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromStatus(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromStatusEpochIdsDoNotMatchFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.STATUS);

        // Given
        GetIdFromStatusRequest request = GetIdFromStatusRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId() + 1)
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromStatusResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromStatus(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromStatusNegativeTimeFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundle(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.STATUS);

        // Given
        GetIdFromStatusRequest request = GetIdFromStatusRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(0 - bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromStatusResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromStatus(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
        assertNull(response);
    }

    @Test
    void testGetIdFromStatusWithEbidEncodedWithPreviousKSSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundleWithTimeDeltaAndOtherKS(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.STATUS,
                0L,
                OtherKSEnum.PREVIOUS);

        if (bundle.getEpochId() >= MAX_EPOCH_DOUBLE_KS_CHECK) {
            log.warn("Outside of K_S patch period ({}); current epoch: {}",
                    MAX_EPOCH_DOUBLE_KS_CHECK,
                    bundle.getEpochId());
            return;
        }

        byte[][] serverKeys = generateRandomServerKeys();

        when(this.cryptographicStorageService.getServerKeys(this.currentEpochId,
                this.serverConfigurationService.getServiceTimeStart(),
                4))
                .thenReturn(serverKeys);

        // Given
        GetIdFromStatusRequest request = GetIdFromStatusRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setFromEpochId(bundle.getEpochId())
                .setNumberOfDaysForEpochBundles(NUMBER_OF_DAYS_FOR_BUNDLES)
                .setServerCountryCode(ByteString.copyFrom(SERVER_COUNTRY_CODE))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromStatusResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromStatus(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
        assertTrue(checkTuples(response.getIdA().toByteArray(), response.getTuples().toByteArray(), this.currentEpochId, serverKeys));
    }

    @Test
    void testGetIdFromStatusWithEbidEncodedWithFutureKSFails() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        AuthRequestBundle bundle = generateAuthRequestBundleWithTimeDeltaAndOtherKS(
                clientIdentifierBundle.get().getId(),
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.STATUS,
                0L,
                OtherKSEnum.NEXT);

        byte[][] serverKeys = generateRandomServerKeys();

        when(this.cryptographicStorageService.getServerKeys(this.currentEpochId,
                this.serverConfigurationService.getServiceTimeStart(),
                4))
                .thenReturn(serverKeys);

        // Given
        GetIdFromStatusRequest request = GetIdFromStatusRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setEpochId(bundle.getEpochId())
                .setTime(bundle.getTime())
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setFromEpochId(bundle.getEpochId())
                .setNumberOfDaysForEpochBundles(NUMBER_OF_DAYS_FOR_BUNDLES)
                .setServerCountryCode(ByteString.copyFrom(SERVER_COUNTRY_CODE))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetIdFromStatusResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getIdFromStatus(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
    }

    @AllArgsConstructor
    @NoArgsConstructor
    @Builder
    @Getter
    private static class HelloMessageBundle {
        private byte[] ebid;
        private byte[] ecc;
        private byte[] mac;
        private int timeSent;
        private long timeReceived;
    }

    private HelloMessageBundle generateHelloMessage(byte[] id,
                                                    byte[][] serverKeys,
                                                    byte[] keyForMac,
                                                    DigestSaltEnum digestSalt,
                                                    int delta,
                                                    OtherKSEnum otherKSEnum) {

        final LocalDateTime ldt = LocalDateTime.of(2020, 6, 1, 00, 00);
        final ZonedDateTime zdt = ldt.atZone(ZoneId.of("UTC"));
        long otherTimeStart = TimeUtils.convertUnixMillistoNtpSeconds(zdt.toInstant().toEpochMilli());

        long time = getCurrentTimeNTPSeconds() - delta;
        int epochId = TimeUtils.getNumberOfEpochsBetween(otherTimeStart, time);

        byte[] ks = ByteUtils.generateRandom(24);
        byte[] ksPrevious = ByteUtils.generateRandom(24);
        byte[] ksNext = ByteUtils.generateRandom(24);

        doReturn(ks).when(this.cryptographicStorageService)
                .getServerKey(epochId,
                        this.serverConfigurationService.getServiceTimeStart(),
                        false);
        doReturn(ksNext).when(this.cryptographicStorageService)
                .getServerKey(epochId + 1,
                        this.serverConfigurationService.getServiceTimeStart(),
                        false);
        doReturn(ksPrevious).when(this.cryptographicStorageService)
                .getServerKey(epochId -1,
                        this.serverConfigurationService.getServiceTimeStart(),
                        false);
        doReturn(ksPrevious).when(this.cryptographicStorageService)
                .getServerKey(epochId,
                        this.serverConfigurationService.getServiceTimeStart(),
                        true);

        byte[] serverKey;
        switch(otherKSEnum) {
            case PREVIOUS:
                serverKey = ksPrevious;
                break;
            case NEXT:
                serverKey = ksNext;
                break;
            case NONE:
            default:
                serverKey = ks;
                break;
        }

        byte[] ebid = generateEbid(id, epochId, serverKey);

        //when(this.cryptographicStorageService.getServerKeys(epochId, time, 4)).thenReturn(serverKeys);
//        when(this.cryptographicStorageService.getServerKey(epochId, time, false)).thenReturn(serverKeys[2]);
//        when(this.cryptographicStorageService.getServerKey(epochId, time, true)).thenReturn(serverKeys[1]);
        when(this.cryptographicStorageService.getFederationKey()).thenReturn(this.federationKey);


        byte[] mac;
        byte[] ecc;
        try {
            byte[] hello = new byte[16];
            ecc = this.cryptoService.encryptCountryCode(
                    new CryptoAESECB(this.cryptographicStorageService.getFederationKey()),
                    ebid,
                    SERVER_COUNTRY_CODE[0]);
            System.arraycopy(ecc, 0, hello, 0, 1);
            System.arraycopy(ebid, 0, hello, 1, ebid.length);
            System.arraycopy(ByteUtils.longToBytes(time), 6, hello, 1 + ebid.length, 2);
            mac = this.cryptoService.generateMACHello(new CryptoHMACSHA256(keyForMac), hello);

        } catch (RobertServerCryptoException e) {
            return null;
        }

        return HelloMessageBundle.builder()
                .ebid(ebid)
                .ecc(ecc)
                .timeReceived(time + 1)
                .timeSent((int)time)
                .mac(mac)
                .build();
    }

    @Test
    void testGetInfoFromHelloMessageSucceeds() {
        byte[][] serverKeys = new byte[4][24];
        new SecureRandom().nextBytes(serverKeys[0]);
        new SecureRandom().nextBytes(serverKeys[1]);
        new SecureRandom().nextBytes(serverKeys[2]);
        new SecureRandom().nextBytes(serverKeys[3]);

        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        HelloMessageBundle bundle = generateHelloMessage(
                clientIdentifierBundle.get().getId(),
                serverKeys,
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.HELLO,
                3000,
                OtherKSEnum.NONE);

        // Given
        GetInfoFromHelloMessageRequest request = GetInfoFromHelloMessageRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setTimeReceived(bundle.getTimeReceived())
                .setTimeSent(bundle.getTimeSent())
                .setEcc(ByteString.copyFrom(bundle.getEcc()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetInfoFromHelloMessageResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getInfoFromHelloMessage(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(response.getCountryCode().toByteArray(), SERVER_COUNTRY_CODE));
    }

    @Test
    void testGetInfoFromHelloMessageBadMacFails() {
        byte[][] serverKeys = new byte[1][24];
        new SecureRandom().nextBytes(serverKeys[0]);

        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        HelloMessageBundle bundle = generateHelloMessage(
                clientIdentifierBundle.get().getId(),
                serverKeys,
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.HELLO,
                5000,
                OtherKSEnum.NONE);

        // Mess up with mac
        byte[] mac = new byte[32];
        System.arraycopy(bundle.getMac(), 0, mac, 0, bundle.getMac().length);
        mac[3] = (byte)(mac[3] ^ 0x4);

        // Given
        GetInfoFromHelloMessageRequest request = GetInfoFromHelloMessageRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setMac(ByteString.copyFrom(mac))
                .setTimeReceived(bundle.getTimeReceived())
                .setTimeSent(bundle.getTimeSent())
                .setEcc(ByteString.copyFrom(bundle.getEcc()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetInfoFromHelloMessageResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getInfoFromHelloMessage(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
    }

    @Test
    void testGetInfoFromHelloMessageFakeEbidFails() {
        byte[][] serverKeys = new byte[1][24];
        new SecureRandom().nextBytes(serverKeys[0]);

        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        HelloMessageBundle bundle = generateHelloMessage(
                clientIdentifierBundle.get().getId(),
                serverKeys,
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.HELLO,
                5000,
                OtherKSEnum.NONE);

        byte[] fakeEbid = new byte[8];
        new SecureRandom().nextBytes(fakeEbid);

        // Given
        GetInfoFromHelloMessageRequest request = GetInfoFromHelloMessageRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(fakeEbid))
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setTimeReceived(bundle.getTimeReceived())
                .setTimeSent(bundle.getTimeSent())
                .setEcc(ByteString.copyFrom(bundle.getEcc()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetInfoFromHelloMessageResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getInfoFromHelloMessage(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
    }

    @Test
    void testGetInfoFromHelloMessageWithEbidEncodedWithPreviousKSSucceeds() {
        byte[][] serverKeys = new byte[4][24];
        new SecureRandom().nextBytes(serverKeys[0]);
        new SecureRandom().nextBytes(serverKeys[1]);
        new SecureRandom().nextBytes(serverKeys[2]);
        new SecureRandom().nextBytes(serverKeys[3]);

        int delta = 5000;
        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        HelloMessageBundle bundle = generateHelloMessage(
                clientIdentifierBundle.get().getId(),
                serverKeys,
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.HELLO,
                delta,
                OtherKSEnum.PREVIOUS);
    
        final LocalDateTime ldt = LocalDateTime.of(2020, 6, 1, 00, 00);
        final ZonedDateTime zdt = ldt.atZone(ZoneId.of("UTC"));
        long otherTimeStart = TimeUtils.convertUnixMillistoNtpSeconds(zdt.toInstant().toEpochMilli());

        long time = getCurrentTimeNTPSeconds() - delta;
        int epochId = TimeUtils.getNumberOfEpochsBetween(otherTimeStart, time);

        if (epochId >= MAX_EPOCH_DOUBLE_KS_CHECK) {
            log.warn("Outside of K_S patch period ({}); current epoch: {}",
                    MAX_EPOCH_DOUBLE_KS_CHECK,
                    epochId);
            return;
        }


        // Given
        GetInfoFromHelloMessageRequest request = GetInfoFromHelloMessageRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setTimeReceived(bundle.getTimeReceived())
                .setTimeSent(bundle.getTimeSent())
                .setEcc(ByteString.copyFrom(bundle.getEcc()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetInfoFromHelloMessageResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getInfoFromHelloMessage(req, observer),
                        (t) -> fail(),
                        res);
        assertTrue(!res.isError());
        assertTrue(ByteUtils.isNotEmpty(response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(clientIdentifierBundle.get().getId(), response.getIdA().toByteArray()));
        assertTrue(Arrays.equals(response.getCountryCode().toByteArray(), SERVER_COUNTRY_CODE));

    }

    @Test
    void testGetInfoFromHelloMessageWithEbidEncodedWithFutureKSFails() {
        byte[][] serverKeys = new byte[4][24];
        new SecureRandom().nextBytes(serverKeys[0]);
        new SecureRandom().nextBytes(serverKeys[1]);
        new SecureRandom().nextBytes(serverKeys[2]);
        new SecureRandom().nextBytes(serverKeys[3]);

        Optional<ClientIdentifierBundle> clientIdentifierBundle = createId();
        HelloMessageBundle bundle = generateHelloMessage(
                clientIdentifierBundle.get().getId(),
                serverKeys,
                clientIdentifierBundle.get().getKeyForMac(),
                DigestSaltEnum.HELLO,
                3000,
                OtherKSEnum.NEXT);

        // Given
        GetInfoFromHelloMessageRequest request = GetInfoFromHelloMessageRequest
                .newBuilder()
                .setEbid(ByteString.copyFrom(bundle.getEbid()))
                .setMac(ByteString.copyFrom(bundle.getMac()))
                .setTimeReceived(bundle.getTimeReceived())
                .setTimeSent(bundle.getTimeSent())
                .setEcc(ByteString.copyFrom(bundle.getEcc()))
                .build();

        ObserverExecutionResult res = new ObserverExecutionResult(false);
        GetInfoFromHelloMessageResponse response =
                sendCryptoRequest(
                        request,
                        (stub, req, observer) -> stub.getInfoFromHelloMessage(req, observer),
                        (t) -> {},
                        res);
        assertTrue(res.isError());
    }

    @AllArgsConstructor
    @NoArgsConstructor
    @Getter
    @Setter
    @Builder
    static class ObserverExecutionResult {
        boolean error;
    }

    interface StubExecution<T,U> {
        void execute(CryptoGrpcServiceImplStub stub, T t, StreamObserver<U> u);
    }

    interface HandleError {
        void execute(Throwable t);
    }

    <T, U> U sendCryptoRequest(T request, StubExecution<T, U> stubExecution, HandleError handleError, ObserverExecutionResult res) {
        try {
            CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(this.inProcessChannel);

            final List<U> response = new ArrayList<>();

            final CountDownLatch latch = new CountDownLatch(1);

            StreamObserver<U> responseObserver =
                    new StreamObserver<U>() {
                @Override
                public void onNext(U value) {
                    response.add(value);
                }

                @Override
                public void onError(Throwable t) {
                    handleError.execute(t);
                    res.setError(true);
                }

                @Override
                public void onCompleted() {
                    latch.countDown();
                }
            };

            stubExecution.execute(stub, request, responseObserver);
            // When
            //stub.createRegistration(request, responseObserver);

            if (res.isError()) {
                return null;
            }

            // Then
            assertTrue(latch.await(1, TimeUnit.SECONDS));
            assertEquals(1, response.size());

            return response.get(0);
        } catch (InterruptedException e) {
            fail(UNEXPECTED_FAILURE_MESSAGE);
            return null;
        }
    }

    public class MockClientKeyStorageService implements IClientKeyStorageService {

        private final HashMap<ByteArray, ClientIdentifierBundle> idKeyHashMap = new HashMap<>();

        private final static int MAX_ID_CREATION_ATTEMPTS = 10;

        private byte[] generateRandomIdentifier() {
            byte[] id;
            int i = 0;
            do {
                id = generateKey(5);
                i++;
            } while (this.idKeyHashMap.containsKey(id) && i < MAX_ID_CREATION_ATTEMPTS);
            return i == MAX_ID_CREATION_ATTEMPTS ? null : id;
        }

        public byte [] generateRandomKey() {
            byte [] ka = null;

            try {
                KeyGenerator keyGen = KeyGenerator.getInstance("HmacSHA256");

                //Creating a SecureRandom object
                SecureRandom secRandom = new SecureRandom();

                //Initializing the KeyGenerator
                keyGen.init(secRandom);

                //Creating/Generating a key
                Key key = keyGen.generateKey();
                ka = key.getEncoded();
            } catch (NoSuchAlgorithmException e) {
                log.error("Could not generate 256-bit key");
            }
            return ka;
        }

        private byte[] generateKey(final int nbOfbytes) {
            byte[] rndBytes = new byte[nbOfbytes];
            SecureRandom sr = new SecureRandom();
            sr.nextBytes(rndBytes);
            return rndBytes;
        }

        @Override
        public Optional<ClientIdentifierBundle> createClientIdUsingKeys(byte[] kaMac, byte[] kaTuples) {
            byte[] id = generateRandomIdentifier();

            ClientIdentifierBundle clientBundle = ClientIdentifierBundle.builder()
                    .id(id)
                    .keyForMac(kaMac)
                    .keyForTuples(kaTuples)
                    .build();
            this.idKeyHashMap.put(new ByteArray(id), clientBundle);
            return Optional.of(clientBundle);
        }

        @Override
        public Optional<ClientIdentifierBundle> findKeyById(byte[] id) {
            ClientIdentifierBundle bundle = this.idKeyHashMap.get(new ByteArray(id));
            if (Objects.isNull(bundle)) {
                return Optional.empty();
            }

            return Optional.of(bundle);
        }

        @Override
        public void deleteClientId(byte[] id) {
            this.idKeyHashMap.remove(new ByteArray(id));
        }

        private class ByteArray {
            public final byte[] bytes;
            public ByteArray(byte[] bytes) {
                this.bytes = bytes;
            }
            @Override
            public boolean equals(Object rhs) {
                return rhs != null && rhs instanceof ByteArray
                        && Arrays.equals(bytes, ((ByteArray)rhs).bytes);
            }
            @Override
            public int hashCode() {
                return Arrays.hashCode(bytes);
            }
        }
    }


}
