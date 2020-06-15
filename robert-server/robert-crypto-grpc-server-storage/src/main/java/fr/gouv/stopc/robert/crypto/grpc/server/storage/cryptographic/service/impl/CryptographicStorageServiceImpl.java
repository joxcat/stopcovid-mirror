package fr.gouv.stopc.robert.crypto.grpc.server.storage.cryptographic.service.impl;

import java.io.IOException;
import java.security.Key;
import java.security.KeyPair;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.Provider;
import java.security.ProviderException;
import java.security.PublicKey;
import java.security.Security;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAmount;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

import javax.crypto.spec.SecretKeySpec;

import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import fr.gouv.stopc.robert.crypto.grpc.server.storage.cryptographic.service.ICryptographicStorageService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import lombok.extern.slf4j.Slf4j;
import sun.security.pkcs11.SunPKCS11;

@Slf4j
@Service
public class CryptographicStorageServiceImpl implements ICryptographicStorageService {

    private KeyStore keyStore;

    private static final int SERVER_KEY_SIZE = 24;

    // Because Java does not know Skinny64, specify AES instead
    private static final String KEYSTORE_SKINNY64_ALGONAME = "AES";
    private static final String KEYSTORE_KEK_ALGONAME = "AES";
    private static final String KEYSTORE_KG_ALGONAME = "AES";
    private static final String SERVER_KEY_CERTIFICATE_CN = "CN=stopcovid.gouv.fr";
    private static final String ECDH_ALGORITHM = "EC";

    //private static final String ALIAS_SERVER_ECDH_PUBLIC_KEY = "server-ecdh-key";
    private static final String ALIAS_SERVER_ECDH_PRIVATE_KEY = "register-key"; // ECDH
    //private static final String ALIAS_SERVER_KEK = "server-key-encryption-key;
    private static final String ALIAS_CLIENT_KEK = "key-encryption-key"; // KEK
    private static final String ALIAS_FEDERATION_KEY = "federation-key"; // K_G
    private static final String ALIAS_SERVER_KEY_PREFIX = "server-key-"; // K_S

    private KeyPair keyPair;

    // Cache for K_S keys
    private Map<String, byte[]> serverKeyCache;

    // Cache for KEK keys
    private Map<String, Key> kekCache;

    private Provider provider;

    private PublicKey publicKey;

    private Key federationKeyCached;

    @Override
    public void init(String password, String configFile) {

        if (!StringUtils.hasText(password) || !StringUtils.hasText(configFile)) {
            throw new IllegalArgumentException("The init argument cannot be empty");
        }

        try {
            this.provider = new SunPKCS11(configFile);

            if (-1 == Security.addProvider(provider)) {
                throw new RuntimeException("could not add security provider");
            }

            char[] keyStorePassword = password.toCharArray();
            this.keyStore = KeyStore.getInstance("PKCS11", provider);
            this.keyStore.load(null, keyStorePassword);
        } catch (KeyStoreException | NoSuchAlgorithmException | CertificateException | IOException | ProviderException  e) {

            log.error("An expected error occured when trying to initialize the keyStore {} due to {}", e.getClass(), e.getMessage());
            throw new RuntimeException("could not add security provider");
        } 

        serverKeyCache = new HashMap<>();
        kekCache = new HashMap<>();
    }

    @Override
    public boolean contains(String alias) {

        try {
            return this.keyStore.containsAlias(alias);
        } catch (KeyStoreException e) {
            log.info("An expected error occured when trying to check containing the alias {} due to {}", alias, e.getMessage());
        }
        return false;
    }

    /**
     * Register key
     * @return
     */
    @Override
    public Optional<KeyPair> getServerKeyPair() {

        // Cache the keypair
        if (this.keyPair != null) {
            return Optional.of(this.keyPair);
        }
        try {
            PrivateKey privateKey = (PrivateKey) this.keyStore.getKey(ALIAS_SERVER_ECDH_PRIVATE_KEY, null);
            PublicKey publicKey = this.keyStore.getCertificate(ALIAS_SERVER_ECDH_PRIVATE_KEY).getPublicKey();
            
            this.keyPair  = new KeyPair(publicKey, privateKey);
            return Optional.ofNullable(this.keyPair);
        } catch (KeyStoreException | UnrecoverableKeyException | NoSuchAlgorithmException e) {
            log.error("Unable to retrieve the server key pair due to {}", e.getMessage());
        }

        return Optional.empty();
    }

    @Override
    public byte[] getEntry(String alias) {

        try {
            if (this.contains(alias)) {
                return this.keyStore.getKey(alias, null).getEncoded();
            }
        } catch (KeyStoreException | UnrecoverableKeyException | NoSuchAlgorithmException e) {
            log.error("An expected error occured when trying to get the entry {} due to {}", alias, e.getMessage());
        }
        return null;
    }

    @Override
    public Provider getProvider() {

        return this.provider;
    }

    @Override
    public Key getKeyForEncryptingClientKeys() {
        return getKeyForEncryptingKeys(ALIAS_CLIENT_KEK,
                "Unable to retrieve key for encrypting keys (KEK) for client from HSM");
    }

    private Key getKeyForEncryptingKeys(String alias, String errorMessage) {
        
        if (this.kekCache.containsKey(alias)) {
            return this.kekCache.get(alias);
        }
        try {
            Key key = this.keyStore.getKey(alias, null);
            this.kekCache.put(alias, key);
            return key;
        } catch (KeyStoreException | NoSuchAlgorithmException | UnrecoverableKeyException | IllegalStateException e) {
            log.error(errorMessage);
        }

        return null;
    }

    @Override
    public byte[] getServerKey(int epochId, long serviceTimeStart, boolean takePreviousDaysKey) {

        LocalDate dateFromEpoch = TimeUtils.getDateFromEpoch(epochId, serviceTimeStart);
        if (Objects.isNull(dateFromEpoch) ) {
            log.error("The date from epoch {} from the time start {} is null", epochId, serviceTimeStart);
            return null;
        }

        if (takePreviousDaysKey) {
            dateFromEpoch = dateFromEpoch.minusDays(1);
        }

        return getServerKey(dateFromEpoch);
    }

    private byte[] getServerKey(LocalDate dateFromEpoch) {
        byte[] serverKey = null;
        try {
            DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyyMMdd");

            String alias = String.format("%s%s", ALIAS_SERVER_KEY_PREFIX, dateFromEpoch.format(dateFormatter));
            if (this.serverKeyCache.containsKey(alias)) {
                return this.serverKeyCache.get(alias);
            }
            if (!this.keyStore.containsAlias(alias)) {
                log.error("Key store does not contain key for alias {}", alias);
            } else {
                Key key = this.keyStore.getKey(alias, null);
                serverKey = key.getEncoded();
                this.serverKeyCache.put(alias, serverKey);
            }
        } catch (Exception e) {
            log.error("An expected error occured when trying to store the alias {} due to {}", dateFromEpoch, e.getMessage());
        }

        return serverKey;
    }

    @Override
    public byte[][] getServerKeys(int epochId, long timeStart, int nbDays) {

        LocalDate dateFromEpoch = TimeUtils.getDateFromEpoch(epochId, timeStart);
        if(Objects.isNull(dateFromEpoch) ) {
            log.error("The date from epoch {} and the time start {} is null", epochId, timeStart);
            return null;
        }

        byte[][] keyMap = new byte[nbDays][SERVER_KEY_SIZE];
        for(int i = 0; i < nbDays; i++) {
            keyMap[i] = this.getServerKey(dateFromEpoch.plusDays(i));
        }
        return keyMap;

    }

    @Override
    public Key getFederationKey() {
        try {
            if (this.federationKeyCached == null) {
                if (this.keyStore.containsAlias(ALIAS_FEDERATION_KEY)) {
                    log.info("Fetching and caching federation key from keystore");
                    Key federationKeyFromHSM = this.keyStore.getKey(ALIAS_FEDERATION_KEY, null);

                    // TODO: review this and create issue tracking this behaviour
                    // Copy key content in new key to prevent any delegation to HSM and perform encryption in Java
                    this.federationKeyCached = new SecretKeySpec(federationKeyFromHSM.getEncoded(), KEYSTORE_KG_ALGONAME);
                }
            }
        } catch (KeyStoreException | NoSuchAlgorithmException | UnrecoverableKeyException e) {
            log.error("Could not retrieve federation key from keystore");
        }
        return this.federationKeyCached;
    }
}
