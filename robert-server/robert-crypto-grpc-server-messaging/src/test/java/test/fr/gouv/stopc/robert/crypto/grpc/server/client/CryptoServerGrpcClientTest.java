package test.fr.gouv.stopc.robert.crypto.grpc.server.client;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;

import java.security.SecureRandom;
import java.util.Arrays;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.impl.CryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.client.service.impl.CryptoServerGrpcClient.TestHelper;
import fr.gouv.stopc.robert.crypto.grpc.server.request.DecryptCountryCodeRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.DecryptEBIDRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.EphemeralTupleRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacEsrValidationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacHelloValidationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacValidationForTypeRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.response.DecryptCountryCodeResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.EBIDResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.EphemeralTupleResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.MacValidationResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplImplBase;
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

	@Test
	public void testGenerateEphemeraTuple() {

		// Given
		EphemeralTupleRequest request = EphemeralTupleRequest.newBuilder()
				.setCountryCode(ByteString.copyFrom(generateKey(1)))
				.setCurrentEpochID(2100)
				.setIdA(ByteString.copyFrom(generateKey(5)))
				.setNumberOfEpochsToGenerate(1)
				.build();

		EphemeralTupleResponse response = EphemeralTupleResponse
				.newBuilder()
				.setEbid(ByteString.copyFrom(generateKey(8)))
				.setEcc(ByteString.copyFrom(generateKey(1)))
				.setEpochId(2102)
				.build();

		CryptoGrpcServiceImplImplBase generateEphemeralTuple = new CryptoGrpcServiceImplImplBase() {

			@Override
			public void generateEphemeralTuple(EphemeralTupleRequest request,
					StreamObserver<EphemeralTupleResponse> responseObserver) {

				responseObserver.onNext(response);

				responseObserver.onCompleted();
			}

		};

		serviceRegistry.addService(generateEphemeralTuple);

		// When
		List<EphemeralTupleResponse> ephTuples = client.generateEphemeralTuple(request);

		// Then
		assertFalse(CollectionUtils.isEmpty(ephTuples));
		verify(testHelper).onMessage(response);
	}

	@Test
	public void testDecryptEBID() {

		// Given
		DecryptEBIDRequest request = DecryptEBIDRequest.newBuilder()
				.setEbid(ByteString.copyFrom(generateKey(8))).build();

		EBIDResponse response = EBIDResponse.newBuilder()
				.setEbid(ByteString.copyFrom(generateKey(8)))
				.build();

		CryptoGrpcServiceImplImplBase decryptEBID = new CryptoGrpcServiceImplImplBase() {
			@Override
			public void decryptEBID(DecryptEBIDRequest request,
					StreamObserver<EBIDResponse> responseObserver) {
				responseObserver.onNext(response);

				responseObserver.onCompleted();
			}

		};

		serviceRegistry.addService(decryptEBID);

		// When
		byte[] decryptedEbid = client.decryptEBID(request);

		// Then
		assertNotNull(decryptedEbid);
		assertTrue(Arrays.equals(decryptedEbid, response.getEbid().toByteArray()));
		verify(testHelper).onMessage(response);
	}

	@Test
	public void testValidateMacEsr() {

		// Given
		MacEsrValidationRequest request = MacEsrValidationRequest.newBuilder()
				.setKa(ByteString.copyFrom(generateKey(16)))
				.setDataToValidate(ByteString.copyFrom(generateKey(12)))
				.setMacToMatchWith(ByteString.copyFrom(generateKey(16)))
				.build();

		MacValidationResponse response = MacValidationResponse.newBuilder()
				.setIsValid(true)
				.build();

		CryptoGrpcServiceImplImplBase validateMacEsr = new CryptoGrpcServiceImplImplBase() {
			@Override
			public void validateMacEsr(MacEsrValidationRequest request,
					StreamObserver<MacValidationResponse> responseObserver) {
				responseObserver.onNext(response);

				responseObserver.onCompleted();
			}

		};

		serviceRegistry.addService(validateMacEsr);

		// When
		boolean isMacValid = client.validateMacEsr(request);

		// Then
		assertTrue(isMacValid);
		verify(testHelper).onMessage(response);
	}

	@Test
	public void testValidateMacForType() {

		// Given
		MacValidationForTypeRequest request = MacValidationForTypeRequest.newBuilder()
				.setKa(ByteString.copyFrom(generateKey(16)))
				.setDataToValidate(ByteString.copyFrom(generateKey(12)))
				.setMacToMatchWith(ByteString.copyFrom(generateKey(16)))
				.setPrefixe(ByteString.copyFrom(generateKey(1)))
				.build();

		MacValidationResponse response = MacValidationResponse.newBuilder()
				.setIsValid(true)
				.build();

		CryptoGrpcServiceImplImplBase validateMacForType = new CryptoGrpcServiceImplImplBase() {
			@Override
			public void validateMacForType(MacValidationForTypeRequest request,
					StreamObserver<MacValidationResponse> responseObserver) {
				responseObserver.onNext(response);

				responseObserver.onCompleted();
			}

		};

		serviceRegistry.addService(validateMacForType);

		// When
		boolean isMacValid = client.validateMacForType(request);

		// Then
		assertTrue(isMacValid);
		verify(testHelper).onMessage(response);
	}

	@Test
	public void testValidateMacHello() {

		// Given
		MacHelloValidationRequest request = MacHelloValidationRequest.newBuilder()
				.setKa(ByteString.copyFrom(generateKey(16)))
				.setDataToValidate(ByteString.copyFrom(generateKey(16)))
				.build();

		MacValidationResponse response = MacValidationResponse.newBuilder()
				.setIsValid(true)
				.build();

		CryptoGrpcServiceImplImplBase validateMacHello = new CryptoGrpcServiceImplImplBase() {
			@Override
			public void validateMacHello(MacHelloValidationRequest request,
					StreamObserver<MacValidationResponse> responseObserver) {
				responseObserver.onNext(response);

				responseObserver.onCompleted();
			}

		};

		serviceRegistry.addService(validateMacHello);

		// When
		boolean isMacValid = client.validateMacHello(request);

		// Then
		assertTrue(isMacValid);
		verify(testHelper).onMessage(response);
	}

	@Test
	public void testDecryptCountryCode() {

		// Given
		DecryptCountryCodeRequest request = DecryptCountryCodeRequest.newBuilder()
				.setEbid(ByteString.copyFrom(generateKey(8)))
				.setEncryptedCountryCode(ByteString.copyFrom(generateKey(1)))
				.build();

		DecryptCountryCodeResponse response = DecryptCountryCodeResponse.newBuilder()
				.setCountryCode(ByteString.copyFrom(new byte[] {(byte) 0x2f}))
				.build();

		CryptoGrpcServiceImplImplBase decryptCountryCode = new CryptoGrpcServiceImplImplBase() {
			@Override
			public void decryptCountryCode(DecryptCountryCodeRequest request,
					StreamObserver<DecryptCountryCodeResponse> responseObserver) {
				responseObserver.onNext(response);

				responseObserver.onCompleted();
			}
		};

		serviceRegistry.addService(decryptCountryCode);

		// When
		byte countryCode = this.client.decryptCountryCode(request);

		// Then
		assertNotEquals(0, countryCode);
		assertEquals((byte) 0x2f, countryCode);
		verify(testHelper).onMessage(response);
	}

	public byte[] generateKey(final int nbOfbytes) {
		byte[] rndBytes = new byte[nbOfbytes];
		SecureRandom sr = new SecureRandom();
		sr.nextBytes(rndBytes);
		return rndBytes;
	}
}
