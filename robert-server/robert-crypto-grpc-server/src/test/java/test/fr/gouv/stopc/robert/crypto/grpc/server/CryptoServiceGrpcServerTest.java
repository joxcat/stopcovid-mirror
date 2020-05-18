package test.fr.gouv.stopc.robert.crypto.grpc.server;

import java.io.IOException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import lombok.extern.slf4j.Slf4j;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.CryptoServiceGrpcServer;
import fr.gouv.stopc.robert.crypto.grpc.server.request.DecryptCountryCodeRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.DecryptEBIDRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.EncryptCountryCodeRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.EphemeralTupleRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.GenerateEBIDRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacEsrValidationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacHelloGenerationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacHelloValidationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacValidationForTypeRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.response.DecryptCountryCodeResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.EBIDResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.EncryptCountryCodeResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.EphemeralTupleResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.MacHelloGenerationResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.MacValidationResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.service.ICryptoServerConfigurationService;
import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.CryptoGrpcServiceBaseImpl;
import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.CryptoGrpcServiceImplGrpc;
import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplImplBase;
import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplStub;
import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.CryptoServerConfigurationServiceImpl;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.service.impl.CryptoServiceImpl;
import io.grpc.ManagedChannel;
import io.grpc.inprocess.InProcessChannelBuilder;
import io.grpc.inprocess.InProcessServerBuilder;
import io.grpc.stub.StreamObserver;
import io.grpc.testing.GrpcCleanupRule;

import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assertions.assertEquals;

@Slf4j
@ExtendWith(SpringExtension.class)
public class CryptoServiceGrpcServerTest {

	public final GrpcCleanupRule grpcCleanup = new GrpcCleanupRule();
	private ManagedChannel inProcessChannel;

	private CryptoServiceGrpcServer server;

	private CryptoGrpcServiceImplImplBase service;

	private ICryptoServerConfigurationService serverConfigurationService;

	private CryptoService cryptoService;

	@BeforeEach
	public void beforeEach() throws IOException {
		serverConfigurationService = new CryptoServerConfigurationServiceImpl();

		cryptoService=  new CryptoServiceImpl();

		service = new CryptoGrpcServiceBaseImpl(serverConfigurationService, cryptoService);

		String serverName = InProcessServerBuilder.generateName();

		server = new CryptoServiceGrpcServer(
				InProcessServerBuilder.forName(serverName)
				.directExecutor()
				, 0, service);
		server.start();
		inProcessChannel = grpcCleanup.register(
				InProcessChannelBuilder.forName(serverName).directExecutor().build());

	}

	@AfterEach
	public void tearDown() throws Exception {
		server.stop();
	}

	@Test
	public void testGenerateEphemeralTuple()  {

		try {
			// Given
			EphemeralTupleRequest request = EphemeralTupleRequest.newBuilder()
					.setIdA(ByteString.copyFrom(generateKey(5)))
					.setCountryCode(ByteString.copyFrom(generateKey(1)))
					.setCurrentEpochID(2100)
					.setNumberOfEpochsToGenerate(1)
					.build();
			CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(inProcessChannel);

			final List<EphemeralTupleResponse> response = new ArrayList<>();
			final CountDownLatch latch = new CountDownLatch(1);

			StreamObserver<EphemeralTupleResponse> responseObserver =
					new StreamObserver<EphemeralTupleResponse>() {
				@Override
				public void onNext(EphemeralTupleResponse value) {
					response.add(value);
				}

				@Override
				public void onError(Throwable t) {
					fail();
				}

				@Override
				public void onCompleted() {
					latch.countDown();
				}
			};

			// When
			stub.generateEphemeralTuple(request, responseObserver);

			// Then
			assertTrue(latch.await(1, TimeUnit.SECONDS));
			assertEquals(1, response.size());
		} catch (InterruptedException e) {
			fail(e.getMessage());
		}
	}

	@Test
	public void testGenerateEBID() {
		try {
			// Given
			GenerateEBIDRequest request = GenerateEBIDRequest
					.newBuilder()
					.setIdA(ByteString.copyFrom(generateKey(5))).build();

			CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(inProcessChannel);

			final List<EBIDResponse> response = new ArrayList<EBIDResponse>();

			final CountDownLatch latch = new CountDownLatch(1);

			StreamObserver<EBIDResponse> responseObserver =
					new StreamObserver<EBIDResponse>() {
				@Override
				public void onNext(EBIDResponse value) {
					response.add(value);
				}

				@Override
				public void onError(Throwable t) {
					fail();
				}

				@Override
				public void onCompleted() {
					latch.countDown();
				}
			};

			// When 
			stub.generateEBID(request, responseObserver);

			// Then
			assertTrue(latch.await(1, TimeUnit.SECONDS));
			assertEquals(1, response.size());
			assertTrue(ByteUtils.isNotEmpty(response.get(0).getEbid().toByteArray()));
		} catch (InterruptedException e) {
			fail(e.getMessage());
		}
	}

	@Test
	public void testDecryptEBID() {

		try {
			// Given
			DecryptEBIDRequest request = DecryptEBIDRequest.newBuilder()
					.setEbid(ByteString.copyFrom(generateKey(8))).build();

			CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(inProcessChannel);

			List<EBIDResponse> response = new ArrayList<EBIDResponse>();

			final CountDownLatch latch = new CountDownLatch(1);

			StreamObserver<EBIDResponse> responseObserver =
					new StreamObserver<EBIDResponse>() {
				@Override
				public void onNext(EBIDResponse value) {
					response.add(value);
				}

				@Override
				public void onError(Throwable t) {
					fail();
				}

				@Override
				public void onCompleted() {
					latch.countDown();
				}
			};

			// When
			stub.decryptEBID(request, responseObserver);

			// Then
			assertTrue(latch.await(1, TimeUnit.SECONDS));
			assertEquals(1, response.size());
			assertTrue(ByteUtils.isNotEmpty(response.get(0).getEbid().toByteArray()));
		} catch (InterruptedException e) {
			fail(e.getMessage());
		}

	}

	@Test
	public void testEncryptCountryCode() {

		try {
			// Given
			EncryptCountryCodeRequest request = EncryptCountryCodeRequest.newBuilder()
					.setEbid(ByteString.copyFrom(generateKey(8)))
					.setCountryCode(ByteString.copyFrom(generateKey(1))).build();

			CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(inProcessChannel);

			List<EncryptCountryCodeResponse> response = new ArrayList<EncryptCountryCodeResponse>();

			final CountDownLatch latch = new CountDownLatch(1);

			StreamObserver<EncryptCountryCodeResponse> responseObserver =
					new StreamObserver<EncryptCountryCodeResponse>() {
				@Override
				public void onNext(EncryptCountryCodeResponse value) {
					response.add(value);
				}

				@Override
				public void onError(Throwable t) {
					fail();
				}

				@Override
				public void onCompleted() {
					latch.countDown();
				}
			};

			// When
			stub.encryptCountryCode(request, responseObserver);

			// Then
			assertTrue(latch.await(1, TimeUnit.SECONDS));
			assertEquals(1, response.size());
			assertTrue(ByteUtils.isNotEmpty(response.get(0).getEncryptedCountryCode().toByteArray()));
		} catch (InterruptedException e) {
			fail(e.getMessage());
		}


	}

	@Test
	public void testDecryptCountryCode() {

		// Then
		try {
			// Given
			DecryptCountryCodeRequest request = DecryptCountryCodeRequest.newBuilder()
					.setEbid(ByteString.copyFrom(generateKey(8)))
					.setEncryptedCountryCode(ByteString.copyFrom(generateKey(1)))
					.build();

			CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(inProcessChannel);

			List<DecryptCountryCodeResponse> response = new ArrayList<DecryptCountryCodeResponse>();

			final CountDownLatch latch = new CountDownLatch(1);


			StreamObserver<DecryptCountryCodeResponse> responseObserver =
					new StreamObserver<DecryptCountryCodeResponse>() {
				@Override
				public void onNext(DecryptCountryCodeResponse value) {
					response.add(value);
				}

				@Override
				public void onError(Throwable t) {
					fail();
				}

				@Override
				public void onCompleted() {
					latch.countDown();
				}
			};

			// When
			stub.decryptCountryCode(request, responseObserver);

			// Then
			assertEquals(1, response.size());
			assertTrue(ByteUtils.isNotEmpty(response.get(0).getCountryCode().toByteArray()));
			assertTrue(latch.await(1, TimeUnit.SECONDS));

		} catch (InterruptedException e) {
			fail(e.getMessage());
		}
	}

	@Test
	public void testGenerateMacHello() {

		try {
			// Given
			MacHelloGenerationRequest request  = MacHelloGenerationRequest.newBuilder()
					.setKa(ByteString.copyFrom(generateKey(16)))
					.setHelloMessage(ByteString.copyFrom(generateKey(16)))
					.build();

			CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(inProcessChannel);

			List<MacHelloGenerationResponse> response = new ArrayList<>();

			final CountDownLatch latch = new CountDownLatch(1);


			StreamObserver<MacHelloGenerationResponse> responseObserver =
					new StreamObserver<MacHelloGenerationResponse>() {
				@Override
				public void onNext(MacHelloGenerationResponse value) {
					response.add(value);
				}

				@Override
				public void onError(Throwable t) {
					fail();
				}

				@Override
				public void onCompleted() {
					latch.countDown();
				}
			};

			// When
			stub.generateMacHello(request, responseObserver);

			// Then
			assertTrue(latch.await(1, TimeUnit.SECONDS));
			assertEquals(1, response.size());
			assertTrue(ByteUtils.isNotEmpty(response.get(0).getMacHelloMessage().toByteArray()));

		} catch (InterruptedException e) {
			fail(e.getMessage());
		}
	}


	@Test
	public void testValidateMacHello() {

		try {
			// Given
			MacHelloValidationRequest request = MacHelloValidationRequest.newBuilder()
					.setKa(ByteString.copyFrom(generateKey(16)))
					.setDataToValidate(ByteString.copyFrom(generateKey(16)))
					.build();

			CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(inProcessChannel);

			List<MacValidationResponse> response = new ArrayList<>();

			final CountDownLatch latch = new CountDownLatch(1);


			StreamObserver<MacValidationResponse> responseObserver =
					new StreamObserver<MacValidationResponse>() {
				@Override
				public void onNext(MacValidationResponse value) {
					response.add(value);
				}

				@Override
				public void onError(Throwable t) {
					fail();
				}

				@Override
				public void onCompleted() {
					latch.countDown();
				}
			};

			// When
			stub.validateMacHello(request, responseObserver);

			//
			assertTrue(latch.await(1, TimeUnit.SECONDS));
			assertEquals(1, response.size());
			assertFalse(response.get(0).getIsValid());
		} catch (InterruptedException e) {
			fail(e.getMessage());
		}
	}

	@Test
	public void testValidateMacEsr() {

		try {
			// Given
			MacEsrValidationRequest request = MacEsrValidationRequest.newBuilder()
					.setKa(ByteString.copyFrom(generateKey(16)))
					.setDataToValidate(ByteString.copyFrom(generateKey(12)))
					.setMacToMatchWith(ByteString.copyFrom(generateKey(16)))
					.build();

			CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(inProcessChannel);

			List<MacValidationResponse> response = new ArrayList<>();

			final CountDownLatch latch = new CountDownLatch(1);


			StreamObserver<MacValidationResponse> responseObserver =
					new StreamObserver<MacValidationResponse>() {
				@Override
				public void onNext(MacValidationResponse value) {
					response.add(value);
				}

				@Override
				public void onError(Throwable t) {
					fail();
				}

				@Override
				public void onCompleted() {
					latch.countDown();
				}
			};

			// When
			stub.validateMacEsr(request, responseObserver);

			//
			assertTrue(latch.await(1, TimeUnit.SECONDS));
			assertEquals(1, response.size());
			assertFalse(response.get(0).getIsValid());
		} catch (InterruptedException e) {
			fail(e.getMessage());
		}
	}

	@Test
	public void testValidateMacForType() {

		try {
			// Given
			MacValidationForTypeRequest request = MacValidationForTypeRequest.newBuilder()
					.setKa(ByteString.copyFrom(generateKey(16)))
					.setDataToValidate(ByteString.copyFrom(generateKey(12)))
					.setMacToMatchWith(ByteString.copyFrom(generateKey(16)))
					.setPrefixe(ByteString.copyFrom(new byte[] { DigestSaltEnum.UNREGISTER.getValue() }))
					.build();

			CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(inProcessChannel);

			List<MacValidationResponse> response = new ArrayList<>();

			final CountDownLatch latch = new CountDownLatch(1);


			StreamObserver<MacValidationResponse> responseObserver =
					new StreamObserver<MacValidationResponse>() {
				@Override
				public void onNext(MacValidationResponse value) {
					response.add(value);
				}

				@Override
				public void onError(Throwable t) {
					fail();
				}

				@Override
				public void onCompleted() {
					latch.countDown();
				}
			};

			// When
			stub.validateMacForType(request, responseObserver);

			//
			assertTrue(latch.await(1, TimeUnit.SECONDS));
			assertEquals(1, response.size());
			assertFalse(response.get(0).getIsValid());
		} catch (InterruptedException e) {
			fail(e.getMessage());
		}
	}

	@Test
	public void testRejectInvalidDigestSalt() {
		List<MacValidationResponse> response = new ArrayList<>();

		// Given
		MacValidationForTypeRequest request = MacValidationForTypeRequest.newBuilder()
				.setKa(ByteString.copyFrom(generateKey(16)))
				.setDataToValidate(ByteString.copyFrom(generateKey(12)))
				.setMacToMatchWith(ByteString.copyFrom(generateKey(16)))
				.setPrefixe(ByteString.copyFrom(new byte[] { (byte)0xFF }))
				.build();

		CryptoGrpcServiceImplStub stub = CryptoGrpcServiceImplGrpc.newStub(inProcessChannel);


		final CountDownLatch latch = new CountDownLatch(1);

		StreamObserver<MacValidationResponse> responseObserver =
				new StreamObserver<MacValidationResponse>() {
					@Override
					public void onNext(MacValidationResponse value) {
						response.add(value);
					}

					@Override
					public void onError(Throwable t) {
						log.info("On error");
						assertNotNull(t);
						assertEquals(0, response.size());
					}

					@Override
					public void onCompleted() {
						latch.countDown();
					}
				};

			stub.validateMacForType(request, responseObserver);
	}

	private byte[] generateKey(final int nbOfbytes) {
		byte[] rndBytes = new byte[nbOfbytes];
		SecureRandom sr = new SecureRandom();
		sr.nextBytes(rndBytes);
		return rndBytes;
	}
}
