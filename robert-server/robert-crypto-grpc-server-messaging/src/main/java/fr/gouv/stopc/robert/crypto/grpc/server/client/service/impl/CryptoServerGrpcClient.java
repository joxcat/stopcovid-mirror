package fr.gouv.stopc.robert.crypto.grpc.server.client.service.impl;

import java.util.Objects;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.google.common.annotations.VisibleForTesting;
import com.google.protobuf.Message;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CryptoGrpcServiceImplGrpc;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplBlockingStub;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.DecryptCountryCodeRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.DecryptCountryCodeResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.DecryptEBIDRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.EBIDResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.EphemeralTupleRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.EphemeralTupleResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.MacEsrValidationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.MacHelloValidationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.MacValidationForTypeRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.MacValidationResponse;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import io.grpc.StatusRuntimeException;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class CryptoServerGrpcClient implements ICryptoServerGrpcClient {

    private ManagedChannel channel;
    private CryptoGrpcServiceImplBlockingStub blockingStub;
    private TestHelper testHelper;

    private final static String ERROR_MESSAGE = "RPC failed: {}";

    public CryptoServerGrpcClient(){}

    public CryptoServerGrpcClient(String host, int port) {
        this(ManagedChannelBuilder.forAddress(host, port).usePlaintext());
    }

    public CryptoServerGrpcClient(ManagedChannelBuilder<?> channelBuilder) {
        this.channel = channelBuilder.build();
        this.blockingStub = CryptoGrpcServiceImplGrpc.newBlockingStub(this.channel);
    }

    public CryptoServerGrpcClient(ManagedChannel channel) {
        this.channel =  channel;
        this.blockingStub = CryptoGrpcServiceImplGrpc.newBlockingStub(channel);
    }

    @Override
    public void init(String host, int port) {
        this.channel = ManagedChannelBuilder.forAddress(host, port).usePlaintext().build();
        this.blockingStub = CryptoGrpcServiceImplGrpc.newBlockingStub(this.channel);
    }

    @Override
    public Optional<EphemeralTupleResponse> generateEphemeralTuple(EphemeralTupleRequest request) {
        try {

            EphemeralTupleResponse response = this.blockingStub.generateEphemeralTuple(request);

            if (this.testHelper != null) {
                this.testHelper.onMessage(response);
            }

            if(Objects.nonNull(response)) {
                return Optional.of(response);
            }
        } catch (StatusRuntimeException e) {
            log.warn(ERROR_MESSAGE, e.getStatus());
        }
        return Optional.empty();
    }

    @Override
    public byte[] decryptEBID(DecryptEBIDRequest request) {
        try {

            EBIDResponse response = this.blockingStub.decryptEBID(request);

            if (this.testHelper != null) {
                this.testHelper.onMessage(response);
            }

            if(Objects.nonNull(response)) {
                return response.getEbid().toByteArray();
            }
        } catch (StatusRuntimeException ex) {
            log.error(ERROR_MESSAGE, ex.getStatus());
        }
        return null;
    }

    @Override
    public boolean validateMacEsr(MacEsrValidationRequest request) {

        try {

            MacValidationResponse response = blockingStub.validateMacEsr(request);

            if (this.testHelper != null) {
                this.testHelper.onMessage(response);
            }

            if(Objects.nonNull(response)) {
                return response.getIsValid();
            }
        } catch (StatusRuntimeException ex) {
            log.error(ERROR_MESSAGE, ex.getStatus());
        }
        return false;
    }


    @Override
    public boolean validateMacForType(MacValidationForTypeRequest request) {

        try {

            MacValidationResponse response = this.blockingStub.validateMacForType(request);

            if (this.testHelper != null) {
                this.testHelper.onMessage(response);
            }

            if(Objects.nonNull(response)) {
                return response.getIsValid();
            }
        } catch (StatusRuntimeException ex) {
            log.error(ERROR_MESSAGE, ex.getStatus());
        }
        return false;
    }


    @Override
    public boolean validateMacHello(MacHelloValidationRequest request) {

        try {

            MacValidationResponse response = this.blockingStub.validateMacHello(request);

            if (this.testHelper != null) {
                this.testHelper.onMessage(response);
            }

            if(Objects.nonNull(response)) {
                return response.getIsValid();
            }
        } catch (StatusRuntimeException ex) {
            log.error(ERROR_MESSAGE, ex.getStatus());
        }
        return false;
    }

    @Override
    public byte decryptCountryCode(DecryptCountryCodeRequest request) {

        try {

            DecryptCountryCodeResponse response = this.blockingStub.decryptCountryCode(request);

            if (this.testHelper != null) {
                this.testHelper.onMessage(response);
            }

            if(Objects.nonNull(response)) {
                return response.getCountryCode().toByteArray()[0];
            }
        } catch (StatusRuntimeException ex) {
            log.error(ERROR_MESSAGE, ex.getStatus());
        }
        return 0;
    }

    /**
     * Only used for helping unit test.
     */
    @VisibleForTesting
    public interface TestHelper {
        /**
         * Used for verify/inspect message received from server.
         */
        void onMessage(Message message);

        /**
         * Used for verify/inspect error received from server.
         */
        void onRpcError(Throwable exception);
    }

    @VisibleForTesting
    public
    void setTestHelper(TestHelper testHelper) {
        this.testHelper = testHelper;
    }

}
