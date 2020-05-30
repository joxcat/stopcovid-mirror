package fr.gouv.stopc.robert.crypto.grpc.server.client.service.impl;

import java.util.Objects;
import java.util.Optional;

import fr.gouv.stopc.robert.crypto.grpc.server.messaging.*;
import org.springframework.stereotype.Service;

import com.google.common.annotations.VisibleForTesting;
import com.google.protobuf.Message;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplBlockingStub;
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
    public Optional<GetIdFromStatusResponse> getIdFromStatus(GetIdFromStatusRequest request) {
        try {
            GetIdFromStatusResponse response = this.blockingStub.getIdFromStatus(request);
            if (Objects.nonNull(this.testHelper)) {
                this.testHelper.onMessage(response);
            }

            return Optional.ofNullable(response);
        } catch (StatusRuntimeException ex) {
            log.error(ERROR_MESSAGE, ex.getMessage());
        }
        return Optional.empty();
    }

    @Override
    public Optional<GetIdFromAuthResponse> getIdFromAuth(GetIdFromAuthRequest request) {
        try {
            GetIdFromAuthResponse response = this.blockingStub.getIdFromAuth(request);
            if (Objects.nonNull(this.testHelper)) {
                this.testHelper.onMessage(response);
            }

            return Optional.ofNullable(response);
        } catch (StatusRuntimeException ex) {
            log.error(ERROR_MESSAGE, ex.getMessage());
        }
        return Optional.empty();
    }

    @Override
    public Optional<CreateRegistrationResponse> createRegistration(CreateRegistrationRequest request) {
        try {
            CreateRegistrationResponse response = this.blockingStub.createRegistration(request);
            if (Objects.nonNull(this.testHelper)) {
                this.testHelper.onMessage(response);
            }

            return Optional.ofNullable(response);
        } catch (StatusRuntimeException ex) {
            log.error(ERROR_MESSAGE, ex.getMessage());
        }
        return Optional.empty();
    }

    @Override
    public Optional<GetInfoFromHelloMessageResponse> getInfoFromHelloMessage(GetInfoFromHelloMessageRequest request) {
        try {
            GetInfoFromHelloMessageResponse response = this.blockingStub.getInfoFromHelloMessage(request);
            if (Objects.nonNull(this.testHelper)) {
                this.testHelper.onMessage(response);
            }

            return Optional.ofNullable(response);
        } catch (StatusRuntimeException ex) {
            log.error(ERROR_MESSAGE, ex.getMessage());
        }
        return Optional.empty();
    }

    @Override
    public Optional<DeleteIdResponse> deleteId(DeleteIdRequest request) {
        try {
            DeleteIdResponse response = this.blockingStub.deleteId(request);
            if (Objects.nonNull(this.testHelper)) {
                this.testHelper.onMessage(response);
            }

            return Optional.ofNullable(response);
        } catch (StatusRuntimeException ex) {
            log.error(ERROR_MESSAGE, ex.getMessage());
        }
        return Optional.empty();
    }

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
