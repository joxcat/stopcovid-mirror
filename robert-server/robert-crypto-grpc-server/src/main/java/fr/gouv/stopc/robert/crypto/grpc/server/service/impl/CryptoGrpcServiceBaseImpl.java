package fr.gouv.stopc.robert.crypto.grpc.server.service.impl;

import java.util.Collection;
import java.util.Objects;

import javax.inject.Inject;

import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

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
import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplImplBase;
import fr.gouv.stopc.robert.server.crypto.callable.TupleGenerator;
import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.structure.impl.Crypto3DES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import io.grpc.stub.StreamObserver;

@Service
public class CryptoGrpcServiceBaseImpl extends CryptoGrpcServiceImplImplBase {


    private final ICryptoServerConfigurationService serverConfigurationService;
    private final CryptoService cryptoService;

    @Inject
    public CryptoGrpcServiceBaseImpl(final ICryptoServerConfigurationService serverConfigurationService,
                                     final CryptoService cryptoService) {

        this.serverConfigurationService = serverConfigurationService;
        this.cryptoService = cryptoService;
    }

    @Override
    public void generateEphemeralTuple(EphemeralTupleRequest request,
                                       StreamObserver<EphemeralTupleResponse> responseObserver) {

        final byte[] serverKey = this.serverConfigurationService.getServerKey();
        final byte[] federationKey = this.serverConfigurationService.getFederationKey();
        final TupleGenerator tupleGenerator = new TupleGenerator(serverKey, federationKey, 1);
        try {
            final Collection<EphemeralTuple> ephemeralTuples = tupleGenerator.exec(
                    request.getIdA().toByteArray(),
                    request.getCurrentEpochID(),
                    request.getNumberOfEpochsToGenerate(),
                    request.getCountryCode().byteAt(0)
            );
            tupleGenerator.stop();

            if (!CollectionUtils.isEmpty(ephemeralTuples)) {

                ephemeralTuples.stream()
                        .map(tuple -> EphemeralTupleResponse
                                .newBuilder()
                                .setEbid(ByteString.copyFrom(tuple.getEbid()))
                                .setEcc(ByteString.copyFrom(tuple.getEncryptedCountryCode()))
                                .setEpochId(tuple.getEpoch())
                                .build())
                        .forEach(response -> responseObserver.onNext(response));

            }
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(e);
        } finally {
            tupleGenerator.stop();
        }
    }

    @Override
    public void generateEBID(GenerateEBIDRequest request,
                             StreamObserver<EBIDResponse> responseObserver) {
        try {
            responseObserver.onNext(EBIDResponse.newBuilder()
                    .setEbid(ByteString.copyFrom(this.cryptoService.generateEBID(
                            new Crypto3DES(this.serverConfigurationService.getServerKey()),
                            request.getEpochId(),
                            request.getIdA().toByteArray())))
                    .build());
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(e);
        }
    }

    @Override
    public void decryptEBID(DecryptEBIDRequest request,
                            StreamObserver<EBIDResponse> responseObserver) {
        try {
            responseObserver.onNext(EBIDResponse.newBuilder()
                    .setEbid(ByteString.copyFrom(
                            this.cryptoService.decryptEBID(
                                    new Crypto3DES(this.serverConfigurationService.getServerKey()),
                                    request.getEbid().toByteArray())))
                    .build());
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(e);
        }
    }

    @Override
    public void encryptCountryCode(EncryptCountryCodeRequest request,
                                   StreamObserver<EncryptCountryCodeResponse> responseObserver) {
        try {
            responseObserver.onNext(EncryptCountryCodeResponse.newBuilder()
                    .setEncryptedCountryCode(ByteString.copyFrom(this.cryptoService.encryptCountryCode(
                            new CryptoAES(this.serverConfigurationService.getFederationKey()),
                            request.getEbid().toByteArray(),
                            request.getCountryCode().byteAt(0))))
                    .build());
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(e);
        }
    }

    @Override
    public void decryptCountryCode(DecryptCountryCodeRequest request,
                                   StreamObserver<DecryptCountryCodeResponse> responseObserver) {
        try {
            responseObserver.onNext(DecryptCountryCodeResponse.newBuilder()
                    .setCountryCode(ByteString.copyFrom(this.cryptoService.decryptCountryCode(
                            new CryptoAES(this.serverConfigurationService.getFederationKey()),
                            request.getEbid().toByteArray(),
                            request.getEncryptedCountryCode().byteAt(0))))
                    .build());
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(e);
        }
    }

    @Override
    public void generateMacHello(MacHelloGenerationRequest request,
                                 StreamObserver<MacHelloGenerationResponse> responseObserver) {
        try {

            responseObserver.onNext(MacHelloGenerationResponse.newBuilder()
                    .setMacHelloMessage(ByteString.copyFrom(this.cryptoService.generateMACHello(
                            new CryptoHMACSHA256(request.getKa().toByteArray()),
                            request.getHelloMessage().toByteArray()))).build());
            responseObserver.onCompleted();

        } catch (Exception e) {
            responseObserver.onError(e);
        }
    }

    @Override
    public void validateMacHello(MacHelloValidationRequest request,
                                 StreamObserver<MacValidationResponse> responseObserver) {
        try {

            responseObserver.onNext(MacValidationResponse.newBuilder()
                    .setIsValid(this.cryptoService.macHelloValidation(
                            new CryptoHMACSHA256(request.getKa().toByteArray()),
                            request.getDataToValidate().toByteArray())).build());
            responseObserver.onCompleted();

        } catch (Exception e) {
            responseObserver.onError(e);
        }
    }

    @Override
    public void validateMacEsr(MacEsrValidationRequest request,
                               StreamObserver<MacValidationResponse> responseObserver) {

        try {
            responseObserver.onNext(MacValidationResponse.newBuilder()
                    .setIsValid(this.cryptoService.macESRValidation(
                            new CryptoHMACSHA256(request.getKa().toByteArray()),
                            request.getDataToValidate().toByteArray(),
                            request.getMacToMatchWith().toByteArray())).build());
            responseObserver.onCompleted();
        } catch (Exception e) {
            responseObserver.onError(e);
        }

    }

    @Override
    public void validateMacForType(MacValidationForTypeRequest request,
                                   StreamObserver<MacValidationResponse> responseObserver) {

        try {
            DigestSaltEnum salt = DigestSaltEnum.valueOf(request.getPrefixe().byteAt(0));

            if (Objects.isNull(salt)) {
                responseObserver.onError(new RobertServerCryptoException("Invalid salt value"));
            } else {
                responseObserver.onNext(MacValidationResponse.newBuilder()
                        .setIsValid(this.cryptoService.macValidationForType(
                                new CryptoHMACSHA256(request.getKa().toByteArray()),
                                request.getDataToValidate().toByteArray(),
                                request.getMacToMatchWith().toByteArray(),
                                salt)).build());
                responseObserver.onCompleted();
            }
        } catch (Exception e) {
            responseObserver.onError(e);
        }

    }

}
