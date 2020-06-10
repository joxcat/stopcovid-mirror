package fr.gouv.stopc.robert.crypto.grpc.server.service.impl;

import java.security.Key;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

import javax.inject.Inject;

import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CreateRegistrationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CreateRegistrationResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplImplBase;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.DeleteIdRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.DeleteIdResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromAuthRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromAuthResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromStatusRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromStatusResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetInfoFromHelloMessageRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetInfoFromHelloMessageResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.service.ICryptoServerConfigurationService;
import fr.gouv.stopc.robert.crypto.grpc.server.service.IECDHKeyService;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.cryptographic.service.ICryptographicStorageService;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.model.ClientIdentifierBundle;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.service.IClientKeyStorageService;
import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robert.server.crypto.callable.TupleGenerator;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESECB;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESGCM;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoSkinny64;
import io.grpc.stub.StreamObserver;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class CryptoGrpcServiceBaseImpl extends CryptoGrpcServiceImplImplBase {

    private final ICryptoServerConfigurationService serverConfigurationService;
    private final CryptoService cryptoService;
    private final IECDHKeyService keyService;
    private final IClientKeyStorageService clientStorageService;
    private final ICryptographicStorageService cryptographicStorageService;

    @Inject
    public CryptoGrpcServiceBaseImpl(final ICryptoServerConfigurationService serverConfigurationService,
                                     final CryptoService cryptoService,
                                     final IECDHKeyService keyService,
                                     final IClientKeyStorageService clientStorageService,
                                     final ICryptographicStorageService cryptographicStorageService) {

        this.serverConfigurationService = serverConfigurationService;
        this.cryptoService = cryptoService;
        this.keyService = keyService;
        this.clientStorageService = clientStorageService;
        this.cryptographicStorageService = cryptographicStorageService;
    }

    @Override
    public void createRegistration(CreateRegistrationRequest request,
                                   StreamObserver<CreateRegistrationResponse> responseObserver) {

        try {
            // Derive K_A and K_A_Tuples from client public key for the new registration
            Optional<ClientIdentifierBundle> clientIdentifierBundleWithPublicKey = this.keyService.deriveKeysFromClientPublicKey(request.getClientPublicKey().toByteArray());

            if (!clientIdentifierBundleWithPublicKey.isPresent()) {
                responseObserver.onError(new RobertServerCryptoException("Unable to create keys for registration"));
                return;
            }

            Optional<ClientIdentifierBundle> clientIdentifierBundleFromDb = this.clientStorageService.createClientIdUsingKeys(
                    clientIdentifierBundleWithPublicKey.get().getKeyForMac(),
                    clientIdentifierBundleWithPublicKey.get().getKeyForTuples());

            if(!clientIdentifierBundleFromDb.isPresent()) {
                responseObserver.onError(new RobertServerCryptoException("Unable to create a registration"));
                return;
            }

            Optional<TuplesGenerationResult> encryptedTuples = generateEncryptedTuples(
                    clientIdentifierBundleFromDb.get().getKeyForTuples(),
                    clientIdentifierBundleFromDb.get().getId(),
                    request.getFromEpochId(),
                    request.getNumberOfDaysForEpochBundles(),
                    request.getServerCountryCode().byteAt(0));

            if (!encryptedTuples.isPresent()) {
                responseObserver.onError(new RobertServerCryptoException("Unhandled exception while creating registration"));
                return;
            }

            CreateRegistrationResponse response = CreateRegistrationResponse
                    .newBuilder()
                    .setIdA(ByteString.copyFrom(clientIdentifierBundleFromDb.get().getId()))
                    .setTuples(ByteString.copyFrom(encryptedTuples.get().getEncryptedTuples()))
                    .build();

            responseObserver.onNext(response);
            responseObserver.onCompleted();
        } catch (RobertServerCryptoException e) {
            responseObserver.onError(new RobertServerCryptoException("Unhandled exception while creating registration"));
        }
    }

    @Override
    public void getIdFromAuth(GetIdFromAuthRequest request,
                              StreamObserver<GetIdFromAuthResponse> responseObserver) {
        DigestSaltEnum digestSalt = DigestSaltEnum.valueOf((byte)request.getRequestType());

        if (Objects.isNull(digestSalt)) {
            String errorMessage = String.format("Unknown request type %d", request.getRequestType());
            log.warn(errorMessage);
            responseObserver.onError(new RobertServerCryptoException(errorMessage));
            return;
        }

        Optional<AuthRequestValidationResult> validationResult = validateAuthRequest(
                request.getEbid().toByteArray(),
                request.getEpochId(),
                request.getTime(),
                request.getMac().toByteArray(),
                digestSalt);

        if (!validationResult.isPresent()) {
            responseObserver.onError(new RobertServerCryptoException("Could not validate auth request"));
            return;
        }

        responseObserver.onNext(GetIdFromAuthResponse.newBuilder()
                .setIdA(ByteString.copyFrom(validationResult.get().getId()))
                .setEpochId(validationResult.get().getEpochId())
                .build());
        responseObserver.onCompleted();
    }

    @Override
    public void getIdFromStatus(GetIdFromStatusRequest request,
                                StreamObserver<GetIdFromStatusResponse> responseObserver) {
        Optional<AuthRequestValidationResult> validationResult = validateAuthRequest(
                request.getEbid().toByteArray(),
                request.getEpochId(),
                request.getTime(),
                request.getMac().toByteArray(),
                DigestSaltEnum.STATUS);

        if (!validationResult.isPresent()) {
            responseObserver.onError(new RobertServerCryptoException("Could not validate auth request"));
            return;
        }

        Optional<ClientIdentifierBundle> clientIdentifierBundle = this.clientStorageService.findKeyById(validationResult.get().getId());
        if (!clientIdentifierBundle.isPresent()) {
            responseObserver.onError(new RobertServerCryptoException("Unknown id"));
            return;
        }

        Optional<TuplesGenerationResult> encryptedTuples = generateEncryptedTuples(
                clientIdentifierBundle.get().getKeyForTuples(),
                clientIdentifierBundle.get().getId(),
                request.getFromEpochId(),
                request.getNumberOfDaysForEpochBundles(),
                request.getServerCountryCode().byteAt(0));

        if (!encryptedTuples.isPresent()) {
            responseObserver.onError(new RobertServerCryptoException("Unhandled exception while creating registration"));
            return;
        }

        responseObserver.onNext(GetIdFromStatusResponse.newBuilder()
                .setIdA(ByteString.copyFrom(validationResult.get().getId()))
                .setEpochId(validationResult.get().getEpochId())
                .setTuples(ByteString.copyFrom(encryptedTuples.get().getEncryptedTuples()))
                .build());
        responseObserver.onCompleted();
    }

    @Override
    public void getInfoFromHelloMessage(GetInfoFromHelloMessageRequest request,
                                        StreamObserver<GetInfoFromHelloMessageResponse> responseObserver) {
        byte[] idA;
        int epochId;
        byte[] cc;
        try {
            // Decrypt EBID
            EbidContent ebidContent = decryptEBIDWithTimeReceived(request.getEbid().toByteArray(), request.getTimeReceived());

            if (Objects.isNull(ebidContent)) {
                responseObserver.onError(new RobertServerCryptoException("Could not decrypt EBID"));
                return;
            }

            idA = ebidContent.getIdA();
            epochId = ebidContent.getEpochId();
        } catch (RobertServerCryptoException e) {
            responseObserver.onError(new RobertServerCryptoException("Could not decrypt EBID"));
            return;
        }

        // Check MAC
        try {
            Optional<ClientIdentifierBundle> clientIdentifierBundle = this.clientStorageService.findKeyById(idA);
            if (!clientIdentifierBundle.isPresent()) {
                String errorMessage = "Could not find keys for id";
                log.warn(errorMessage);
                responseObserver.onError(new RobertServerCryptoException(errorMessage));
                return;
            }
            boolean macValid = this.cryptoService.macHelloValidation(new CryptoHMACSHA256(clientIdentifierBundle.get().getKeyForMac()),
                    generateHelloFromHelloMessageRequest(request));

            if (!macValid) {
                String errorMessage = "MAC is invalid";
                log.warn(errorMessage);
                responseObserver.onError(new RobertServerCryptoException(errorMessage));
                return;
            }
        } catch (RobertServerCryptoException e) {
            String errorMessage = "Could not validate MAC";
            log.warn(errorMessage);
            responseObserver.onError(new RobertServerCryptoException(errorMessage));
            return;
        }

        try {
            // Decrypt ECC
            cc = decryptECC(request.getEbid().toByteArray(), request.getEcc().byteAt(0));
        } catch (RobertServerCryptoException e) {
            String errorMessage = "Could not decrypt ECC";
            log.warn(errorMessage);
            responseObserver.onError(new RobertServerCryptoException(errorMessage));
            return;
        }

        GetInfoFromHelloMessageResponse response = GetInfoFromHelloMessageResponse.newBuilder()
                .setIdA(ByteString.copyFrom(idA))
                .setEpochId(epochId)
                .setCountryCode(ByteString.copyFrom(cc))
                .build();

        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }

    @Override
    public void deleteId(DeleteIdRequest request,
                         StreamObserver<DeleteIdResponse> responseObserver) {
        Optional<AuthRequestValidationResult> validationResult = validateAuthRequest(
                request.getEbid().toByteArray(),
                request.getEpochId(),
                request.getTime(),
                request.getMac().toByteArray(),
                DigestSaltEnum.UNREGISTER);

        if (!validationResult.isPresent()) {
            responseObserver.onError(new RobertServerCryptoException("Could not validate auth request"));
            return;
        }

        this.clientStorageService.deleteClientId(validationResult.get().getId());

        responseObserver.onNext(DeleteIdResponse.newBuilder()
                .setIdA(ByteString.copyFrom(validationResult.get().getId()))
                .build());
        responseObserver.onCompleted();
    }

    private Optional<AuthRequestValidationResult> validateAuthRequest(byte[] encryptedEbid,
                                                                      int epochId,
                                                                      long time,
                                                                      byte[] mac,
                                                                      DigestSaltEnum type) {
        try {
            EbidContent ebidContent = decryptEBIDAndCheckEpoch(encryptedEbid, epochId);

            if (Objects.isNull(ebidContent)) {
                log.warn("Could not decrypt ebid content");
                return Optional.empty();
            }

            Optional<ClientIdentifierBundle> clientIdentifierBundle = this.clientStorageService.findKeyById(ebidContent.getIdA());
            if (!clientIdentifierBundle.isPresent()) {
                log.warn("Could not find id");
                return Optional.empty();
            }
            boolean valid = this.cryptoService.macValidationForType(
                                new CryptoHMACSHA256(clientIdentifierBundle.get().getKeyForMac()),
                                addEbidComponents(encryptedEbid, epochId, time),
                                mac,
                                type);
            if (valid) {
                return Optional.of(AuthRequestValidationResult.builder()
                        .epochId(ebidContent.getEpochId())
                        .id(ebidContent.getIdA())
                        .build());
            }
        } catch (RobertServerCryptoException e) {
            log.error("Error validating authenticated request");
            return Optional.empty();
        }
        log.error("Invalid authenticated request");
        return Optional.empty();
    }

    @Builder
    @Getter
    @AllArgsConstructor
    private static class AuthRequestValidationResult {
        private byte[] id;
        private int epochId;
    }

    @Builder
    @Getter
    @AllArgsConstructor
    private static class TuplesGenerationResult {
        byte[] encryptedTuples;
    }

    // The two following classes are used to serialize to a JSON string that complies with the API Spec
    @AllArgsConstructor
    @NoArgsConstructor
    @Builder
    @Getter
    @Setter
    public static class EphemeralTupleJson {
        private int epochId;
        private EphemeralTupleEbidEccJson key;
    }

    @AllArgsConstructor
    @NoArgsConstructor
    @Builder
    @Getter
    @Setter
    public static class EphemeralTupleEbidEccJson {
        private byte[] ebid;
        private byte[] ecc;
    }

    @Builder
    @AllArgsConstructor
    @Getter
    private static class EbidContent {
        byte[] idA;
        int epochId;
    }

    // TODO: handle edge cases at edges of an epoch (start and finish) by trying and previous K_S
    /**
     * Decrypt the provided ebid and check the authRequestEpoch it contains the provided one or the next/previous
     * @param ebid
     * @param authRequestEpoch
     * @param adjacentEpochMatchEnum
     * @return
     * @throws RobertServerCryptoException
     */
    private EbidContent decryptEBIDAndCheckEpoch(byte[] ebid, int authRequestEpoch, AdjacentEpochMatchEnum adjacentEpochMatchEnum)
            throws RobertServerCryptoException {

        byte[] serverKey = this.cryptographicStorageService.getServerKey(
                authRequestEpoch,
                this.serverConfigurationService.getServiceTimeStart());

        if (Objects.isNull(serverKey)) {
            log.warn("Cannot retrieve server key for {}", authRequestEpoch);
            //return manageEBIDDecryptRetry(ebid, authRequestEpoch, adjacentEpochMatchEnum);
            return null;
        }

        byte[] decryptedEbid = this.cryptoService.decryptEBID(new CryptoSkinny64(serverKey), ebid);
        byte[] idA = getIdFromDecryptedEBID(decryptedEbid);
        int ebidEpochId = getEpochIdFromDecryptedEBID(decryptedEbid);

        if (ebidEpochId < 0) {
            log.warn("Epoch from EBID is negative");
            return manageEBIDDecryptRetry(ebid, authRequestEpoch, adjacentEpochMatchEnum);
        } else if (authRequestEpoch != ebidEpochId) {
            log.warn("Epoch from EBID and accompanying authRequestEpoch do not match: ebid authRequestEpoch = {} vs auth request authRequestEpoch = {}", ebidEpochId, authRequestEpoch);
            return manageEBIDDecryptRetry(ebid, authRequestEpoch, adjacentEpochMatchEnum);
        }

        return EbidContent.builder().epochId(ebidEpochId).idA(idA).build();
    }

    /**
     * Decrypt the provided ebid and check the epoch it contains matches exactly the provided one
     * @param ebid
     * @param epoch
     * @return
     * @throws RobertServerCryptoException
     */
    private EbidContent decryptEBIDAndCheckEpoch(byte[] ebid, int epoch) throws RobertServerCryptoException {
        return decryptEBIDAndCheckEpoch(ebid, epoch, AdjacentEpochMatchEnum.NONE);
    }

    private EbidContent manageEBIDDecryptRetry(byte[] ebid, int authRequestEpoch, AdjacentEpochMatchEnum adjacentEpochMatchEnum)
            throws RobertServerCryptoException {
        switch (adjacentEpochMatchEnum) {
            case PREVIOUS:
                log.warn("Retrying ebid decrypt with previous epoch");
                return decryptEBIDAndCheckEpoch(ebid, authRequestEpoch - 1, AdjacentEpochMatchEnum.NONE);
            case NEXT:
                log.warn("Retrying ebid decrypt with next epoch");
                return decryptEBIDAndCheckEpoch(ebid, authRequestEpoch + 1, AdjacentEpochMatchEnum.NONE);
            case NONE:
            default:
                return null;
        }
    }

    private final static int EPOCH_DURATION = 900;
    private EbidContent decryptEBIDWithTimeReceived(byte[] ebid, long timeReceived) throws RobertServerCryptoException {
        int epoch = TimeUtils.getNumberOfEpochsBetween(
                this.serverConfigurationService.getServiceTimeStart(),
                timeReceived);

        AdjacentEpochMatchEnum adjacentEpochMatch = AdjacentEpochMatchEnum.NONE;
        // TODO: replace local EPOCH_DURATION with common epoch duration constant
        if (timeReceived % EPOCH_DURATION < 5) {
            adjacentEpochMatch = AdjacentEpochMatchEnum.PREVIOUS;
        } else if (timeReceived % EPOCH_DURATION > EPOCH_DURATION - 5) {
            adjacentEpochMatch = AdjacentEpochMatchEnum.NEXT;
        }

        return decryptEBIDAndCheckEpoch(ebid, epoch, adjacentEpochMatch);
    }

    private enum AdjacentEpochMatchEnum {
        NONE,
        PREVIOUS,
        NEXT
    }

    private byte[] decryptECC(byte[] ebid, byte encryptedCountryCode) throws RobertServerCryptoException {
        return this.cryptoService.decryptCountryCode(
                new CryptoAESECB(this.cryptographicStorageService.getFederationKey()), ebid, encryptedCountryCode);
    }

    private byte[] generateHelloFromHelloMessageRequest(GetInfoFromHelloMessageRequest request) {
        byte[] hello = new byte[16];
        byte[] ecc = request.getEcc().toByteArray();
        byte[] ebid = request.getEbid().toByteArray();
        byte[] mac = request.getMac().toByteArray();
        System.arraycopy(ecc, 0, hello, 0, ecc.length);
        System.arraycopy(ebid, 0, hello, ecc.length, ebid.length);
        System.arraycopy(ByteUtils.intToBytes(request.getTimeSent()), 2, hello, ecc.length + ebid.length, 2);
        System.arraycopy(mac, 0, hello, ecc.length + ebid.length + 2, mac.length);
        return hello;
    }

    private byte[] addEbidComponents(byte[] encryptedEbid, int epochId, long time) {
        byte[] all = new byte[encryptedEbid.length + Integer.BYTES + Integer.BYTES];
        System.arraycopy(encryptedEbid, 0, all, 0, encryptedEbid.length);
        System.arraycopy(ByteUtils.intToBytes(epochId), 0, all, encryptedEbid.length, Integer.BYTES);
        System.arraycopy(
                ByteUtils.longToBytes(time),
                4,
                all,
                encryptedEbid.length + Integer.BYTES,
                Integer.BYTES);
        return all;
    }

    private java.util.List<EphemeralTupleJson> mapEphemeralTuples(Collection<EphemeralTuple> tuples) {
        ArrayList<EphemeralTupleJson> mappedTuples = new ArrayList<>();

        for (EphemeralTuple tuple : tuples) {
            mappedTuples.add(EphemeralTupleJson.builder()
                    .epochId(tuple.getEpochId())
                    .key(EphemeralTupleEbidEccJson.builder()
                            .ebid(tuple.getEbid())
                            .ecc(tuple.getEncryptedCountryCode())
                            .build())
                    .build());
        }
        return mappedTuples;
    }

    private final static int EPOCHS_PER_DAY = 4 * 24;
    private Optional<TuplesGenerationResult> generateEncryptedTuples(byte[] tuplesEncryptionKey,
                                                                     byte[] id,
                                                                     int epochId,
                                                                     int nbDays,
                                                                     byte serverCountryCode) {

        if (nbDays < 1) {
            log.error("Request number of epochs is invalid for tuple generation");
            return Optional.empty();
        }

        // TODO: limit generation to a max number of days ?

        // Generate tuples
        final byte[][] serverKeys = this.cryptographicStorageService.getServerKeys(
                epochId,
                this.serverConfigurationService.getServiceTimeStart(),
                nbDays);

        if (Objects.isNull(serverKeys)) {
            log.warn("Could not retrieve server keys for epoch span starting with: {}", epochId);
            return Optional.empty();
        }

        Collection<EphemeralTuple> ephemeralTuples = new ArrayList<>();
        final Key federationKey = this.cryptographicStorageService.getFederationKey();
        for (int i = 0; i < nbDays; i++) {
            if (serverKeys[i] != null) {
                final TupleGenerator tupleGenerator = new TupleGenerator(serverKeys[i], federationKey);
                try {
                    Collection<EphemeralTuple> tuplesForDay = tupleGenerator.exec(
                            id,
                            epochId + (i * EPOCHS_PER_DAY),
                            EPOCHS_PER_DAY,
                            serverCountryCode
                    );
                    tupleGenerator.stop();
                    ephemeralTuples.addAll(tuplesForDay);
                } catch (RobertServerCryptoException e) {
                    log.warn("Error generating tuples for day {}", i);
                    //return Optional.empty();
                }
            } else {
                log.warn("Cannot generating tuples for day {}, missing key", i);
            }
        }
        ephemeralTuples = ephemeralTuples.stream()
                .sorted(Comparator.comparingInt(EphemeralTuple::getEpochId))
                .collect(Collectors.toList());

        try {
            if (!CollectionUtils.isEmpty(ephemeralTuples)) {
                ObjectMapper objectMapper = new ObjectMapper();
                byte[] tuplesAsBytes = objectMapper.writeValueAsBytes(mapEphemeralTuples(ephemeralTuples));
                CryptoAESGCM cryptoAESGCM = new CryptoAESGCM(tuplesEncryptionKey);
                return Optional.of(TuplesGenerationResult.builder().encryptedTuples(cryptoAESGCM.encrypt(tuplesAsBytes)).build());
            }
            return Optional.empty();
        } catch (JsonProcessingException | RobertServerCryptoException e) {
            log.warn("Error serializing tuples to encrypted JSON");
            return Optional.empty();
        }
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

}
 
