package fr.gouv.stopc.robert.crypto.grpc.server.service.impl;

import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.ProviderException;
import java.security.PublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.X509EncodedKeySpec;
import java.util.Objects;
import java.util.Optional;

import javax.crypto.KeyAgreement;
import javax.inject.Inject;

import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.crypto.grpc.server.service.IECDHKeyService;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.cryptographic.service.ICryptographicStorageService;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.model.ClientIdentifierBundle;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class ECDHKeyServiceImpl implements IECDHKeyService {

    private final static String HASH_MAC = "mac";
    private final static String HASH_TUPLES = "tuples";

    private ICryptographicStorageService cryptographicStorageService;

    @Inject
    public ECDHKeyServiceImpl(ICryptographicStorageService cryptographicStorageService) {
        this.cryptographicStorageService = cryptographicStorageService;
    }

    private byte[] deriveKeyForMacFromClientPublicKey(byte[] sharedSecret) throws RobertServerCryptoException {
        CryptoHMACSHA256 sha256Mac = new CryptoHMACSHA256(sharedSecret);
        return sha256Mac.encrypt(HASH_MAC.getBytes());
    }

    private byte[] deriveKeyForTuplesFromClientPublicKey(byte[] sharedSecret) throws RobertServerCryptoException {
        CryptoHMACSHA256 sha256Mac = new CryptoHMACSHA256(sharedSecret);
        return sha256Mac.encrypt(HASH_TUPLES.getBytes());
    }


    private byte[] generateSharedSecret(byte[] clientPublicKey) {
        Optional<KeyPair> serverKeyPair = this.cryptographicStorageService.getServerKeyPair();

        if (!serverKeyPair.isPresent()) {
            log.error("Could not retrieve server key pair");
            return null;
        }

        PrivateKey serverPrivateKey = serverKeyPair.get().getPrivate();

        try {
            KeyAgreement keyAgreement = KeyAgreement.getInstance("ECDH");
            keyAgreement.init(serverPrivateKey);
            X509EncodedKeySpec pkSpec = new X509EncodedKeySpec(clientPublicKey);
            KeyFactory kf = KeyFactory.getInstance("EC");
            PublicKey clientPublicKeyAsKey = kf.generatePublic(pkSpec);
            keyAgreement.doPhase(clientPublicKeyAsKey, true);
            return keyAgreement.generateSecret();
        } catch (NoSuchAlgorithmException | InvalidKeySpecException
                | InvalidKeyException | IllegalStateException | ProviderException e) {
            log.error("Unable to generate ECDH Keys due to {}", e.getMessage());
        }

        return null;
    }

    /**
     * @param clientPublicKey
     * @return keys generated from shared secret and the server public key
     * @throws RobertServerCryptoException
     */
    @Override
    public Optional<ClientIdentifierBundle> deriveKeysFromClientPublicKey(byte[] clientPublicKey)
            throws RobertServerCryptoException {
        byte[] sharedSecret = this.generateSharedSecret(clientPublicKey);

        if (Objects.isNull(sharedSecret)) {
            return Optional.empty();
        }

        byte[] kaMac = deriveKeyForMacFromClientPublicKey(sharedSecret);
        byte[] kaTuples = deriveKeyForTuplesFromClientPublicKey(sharedSecret);

        if (Objects.isNull(kaMac) || Objects.isNull(kaTuples)) {
            return Optional.empty();
        }

        return Optional.of(ClientIdentifierBundle.builder()
                .keyForMac(kaMac)
                .keyForTuples(kaTuples)
                .build());
    }

}
