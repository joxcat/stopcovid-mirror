package test.fr.gouv.stopc.robert.crypto.grpc.server.client;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;

import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.impl.CryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.client.service.impl.CryptoServerGrpcClient.TestHelper;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplImplBase;
import io.grpc.ManagedChannel;
import io.grpc.inprocess.InProcessChannelBuilder;
import io.grpc.inprocess.InProcessServerBuilder;
import io.grpc.stub.StreamObserver;
import io.grpc.testing.GrpcCleanupRule;
import io.grpc.util.MutableHandlerRegistry;

@ExtendWith(SpringExtension.class)
public class CryptoServerGrpcClientTest {

    private CryptoServerGrpcClient client;

    public final GrpcCleanupRule grpcCleanup = new GrpcCleanupRule();

    private final MutableHandlerRegistry serviceRegistry = new MutableHandlerRegistry();

    private ManagedChannel inProcessChannel;

    @Mock
    private TestHelper testHelper;
    @BeforeEach
    public void setUp() throws Exception {
        // Generate a unique in-process server name.
        String serverName = InProcessServerBuilder.generateName();
        // Use a mutable service registry for later registering the service impl for each test case.
        grpcCleanup.register(InProcessServerBuilder.forName(serverName)
                .fallbackHandlerRegistry(serviceRegistry).directExecutor().build().start());

        inProcessChannel = grpcCleanup.register(
                InProcessChannelBuilder.forName(serverName).directExecutor().build());

        client = new CryptoServerGrpcClient(inProcessChannel);
        client.setTestHelper(testHelper);
    }

//    @Test
//    public void testDecryptEBID() {
//
//        // Given
//        DecryptEBIDRequest request = DecryptEBIDRequest.newBuilder()
//                .setEbid(ByteString.copyFrom(generate(8))).build();
//
//        EBIDResponse response = EBIDResponse.newBuilder()
//                .setEbid(ByteString.copyFrom(generate(8)))
//                .build();
//
//
//        CryptoGrpcServiceImplImplBase decryptEBID = new CryptoGrpcServiceImplImplBase() {
//            @Override
//            public void decryptEBID(DecryptEBIDRequest request,
//                    StreamObserver<EBIDResponse> responseObserver) {
//                responseObserver.onNext(response);
//
//                responseObserver.onCompleted();
//            }
//
//        };
//
//        serviceRegistry.addService(decryptEBID);
//
//        // When
//        byte[] decryptedEbid = client.decryptEBID(request);
//
//        // Then
//        assertNotNull(decryptedEbid);
//        assertTrue(Arrays.equals(decryptedEbid, response.getEbid().toByteArray()));
//        verify(testHelper).onMessage(response);
//    }
//
//    @Test
//    public void testValidateMacEsr() {
//
//        // Given
//        MacEsrValidationRequest request = MacEsrValidationRequest.newBuilder()
//                .setKa(ByteString.copyFrom(generate(16)))
//                .setDataToValidate(ByteString.copyFrom(generate(12)))
//                .setMacToMatchWith(ByteString.copyFrom(generate(16)))
//                .build();
//
//        MacValidationResponse response = MacValidationResponse.newBuilder()
//                .setIsValid(true)
//                .build();
//
//        CryptoGrpcServiceImplImplBase validateMacEsr = new CryptoGrpcServiceImplImplBase() {
//            @Override
//            public void validateMacEsr(MacEsrValidationRequest request,
//                    StreamObserver<MacValidationResponse> responseObserver) {
//                responseObserver.onNext(response);
//
//                responseObserver.onCompleted();
//            }
//
//        };
//
//        serviceRegistry.addService(validateMacEsr);
//
//        // When
//        boolean isMacValid = client.validateMacEsr(request);
//
//        // Then
//        assertTrue(isMacValid);
//        verify(testHelper).onMessage(response);
//    }
//
//    @Test
//    public void testValidateMacForType() {
//
//        // Given
//        MacValidationForTypeRequest request = MacValidationForTypeRequest.newBuilder()
//                .setKa(ByteString.copyFrom(generate(16)))
//                .setDataToValidate(ByteString.copyFrom(generate(12)))
//                .setMacToMatchWith(ByteString.copyFrom(generate(16)))
//                .setPrefixe(ByteString.copyFrom(generate(1)))
//                .build();
//
//        MacValidationResponse response = MacValidationResponse.newBuilder()
//                .setIsValid(true)
//                .build();
//
//        CryptoGrpcServiceImplImplBase validateMacForType = new CryptoGrpcServiceImplImplBase() {
//            @Override
//            public void validateMacForType(MacValidationForTypeRequest request,
//                    StreamObserver<MacValidationResponse> responseObserver) {
//                responseObserver.onNext(response);
//
//                responseObserver.onCompleted();
//            }
//
//        };
//
//        serviceRegistry.addService(validateMacForType);
//
//        // When
//        boolean isMacValid = client.validateMacForType(request);
//
//        // Then
//        assertTrue(isMacValid);
//        verify(testHelper).onMessage(response);
//    }
//
//    @Test
//    public void testValidateMacHello() {
//
//        // Given
//        MacHelloValidationRequest request = MacHelloValidationRequest.newBuilder()
//                .setKa(ByteString.copyFrom(generate(16)))
//                .setDataToValidate(ByteString.copyFrom(generate(16)))
//                .build();
//
//        MacValidationResponse response = MacValidationResponse.newBuilder()
//                .setIsValid(true)
//                .build();
//
//        CryptoGrpcServiceImplImplBase validateMacHello = new CryptoGrpcServiceImplImplBase() {
//            @Override
//            public void validateMacHello(MacHelloValidationRequest request,
//                    StreamObserver<MacValidationResponse> responseObserver) {
//                responseObserver.onNext(response);
//
//                responseObserver.onCompleted();
//            }
//
//        };
//
//        serviceRegistry.addService(validateMacHello);
//
//        // When
//        boolean isMacValid = client.validateMacHello(request);
//
//        // Then
//        assertTrue(isMacValid);
//        verify(testHelper).onMessage(response);
//    }
//
//    @Test
//    public void testDecryptCountryCode() {
//
//        // Given
//        DecryptCountryCodeRequest request = DecryptCountryCodeRequest.newBuilder()
//                .setEbid(ByteString.copyFrom(generate(8)))
//                .setEncryptedCountryCode(ByteString.copyFrom(generate(1)))
//                .build();
//
//        DecryptCountryCodeResponse response = DecryptCountryCodeResponse.newBuilder()
//                .setCountryCode(ByteString.copyFrom(new byte[] {(byte) 0x2f}))
//                .build();
//
//        CryptoGrpcServiceImplImplBase decryptCountryCode = new CryptoGrpcServiceImplImplBase() {
//            @Override
//            public void decryptCountryCode(DecryptCountryCodeRequest request,
//                    StreamObserver<DecryptCountryCodeResponse> responseObserver) {
//                responseObserver.onNext(response);
//
//                responseObserver.onCompleted();
//            }
//        };
//
//        serviceRegistry.addService(decryptCountryCode);
//
//        // When
//        byte countryCode = this.client.decryptCountryCode(request);
//
//        // Then
//        assertNotEquals(0, countryCode);
//        assertEquals((byte) 0x2f, countryCode);
//        verify(testHelper).onMessage(response);
//    }
//
//    @Test
//    public void testGenerateIdentity() {
//
//        // Given
//        GenerateIdentityRequest request = GenerateIdentityRequest.newBuilder()
//                .setClientPublicKey(ByteString.copyFrom(generate(91)))
//                .build();
//
//        GenerateIdentityResponse response = GenerateIdentityResponse.newBuilder()
//                .setIdA(ByteString.copyFrom(generate(5)))
//                .setEncryptedSharedKey(ByteString.copyFrom(generate(32)))
//                .setServerPublicKeyForKey(ByteString.copyFrom(generate(32)))
//                .build();
//
//        CryptoGrpcServiceImplImplBase genereateIdentity = new CryptoGrpcServiceImplImplBase() {
//            @Override
//            public void generateIdentity(GenerateIdentityRequest request,
//                    StreamObserver<GenerateIdentityResponse> responseObserver) {
//                responseObserver.onNext(response);
//
//                responseObserver.onCompleted();
//            }
//        };
//
//        serviceRegistry.addService(genereateIdentity);
//
//        // When
//        Optional<GenerateIdentityResponse> expectedResponse = this.client.generateIdentity(request);
//
//        // Then
//        assertTrue(expectedResponse.isPresent());
//        assertEquals(expectedResponse.get(), response);
//        verify(testHelper).onMessage(response);
//
//    }
//
//    @Test
//    public void testGenerateEncryptedEphemeralTuple() {
//
//        // Given
//        EncryptedEphemeralTupleBundleRequest request = EncryptedEphemeralTupleBundleRequest.newBuilder()
//                .setClientPublicKey(ByteString.copyFrom(generate(32)))
//                .setIdA(ByteString.copyFrom(generate(5)))
//                .setCountryCode(ByteString.copyFrom(generate(1)))
//                .setFromEpoch(2100)
//                .setNumberOfEpochsToGenerate(1)
//                .build();
//
//        EncryptedEphemeralTupleBundleResponse response = EncryptedEphemeralTupleBundleResponse.newBuilder()
//                .setEncryptedTuples(ByteString.copyFrom(generate(52)))
//                .setServerPublicKeyForTuples(ByteString.copyFrom(generate(32)))
//                .build();
//
//        CryptoGrpcServiceImplImplBase genereateIdentity = new CryptoGrpcServiceImplImplBase() {
//            @Override
//            public void generateEncryptedEphemeralTuple(EncryptedEphemeralTupleBundleRequest request,
//                    StreamObserver<EncryptedEphemeralTupleBundleResponse> responseObserver) {
//                responseObserver.onNext(response);
//
//                responseObserver.onCompleted();
//            }
//        };
//
//        serviceRegistry.addService(genereateIdentity);
//
//        // When
//        Optional<EncryptedEphemeralTupleBundleResponse> expectedResponse = this.client.generateEncryptedEphemeralTuple(request);
//
//        // Then
//        assertTrue(expectedResponse.isPresent());
//        assertEquals(expectedResponse.get(), response);
//        verify(testHelper).onMessage(response);
//
//    }

    public byte[] generate(final int nbOfbytes) {
        byte[] rndBytes = new byte[nbOfbytes];
        SecureRandom sr = new SecureRandom();
        sr.nextBytes(rndBytes);
        return rndBytes;
    }
}
