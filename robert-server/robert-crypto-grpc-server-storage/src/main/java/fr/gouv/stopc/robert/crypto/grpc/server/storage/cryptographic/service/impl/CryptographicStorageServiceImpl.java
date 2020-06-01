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

//    // TODO: Remove this if keys are already available in HSM (Java code should not create it)
//    public void addKekKeysIfNotExist(byte[] kekForKa, byte[] kekForKs) {
//        try {
//            if (!this.contains(ALIAS_CLIENT_KEK)) {
//                this.keyStore.setKeyEntry(ALIAS_CLIENT_KEK, new SecretKeySpec(kekForKa, KEYSTORE_KEK_ALGONAME), null, null);
//            }
////            if (!this.contains(ALIAS_SERVER_KEK)) {
////                this.keyStore.setKeyEntry(ALIAS_SERVER_KEK, new SecretKeySpec(kekForKs, KEYSTORE_KEK_ALGONAME), null, null);
////            }
//        } catch (KeyStoreException e) {
//            log.error("An expected error occurred when trying to store the kek keys in HSM due to {}", e.getMessage());
//        }
//    }

//    // TODO: Remove this if keys are already available in HSM (Java code should not create it)
//    @Override
//    public void addECDHKeys(String serverPublicKey, String serverPrivateKey) {
//
//        try {
//            EncodedKeySpec privateKeySpec = new PKCS8EncodedKeySpec(Base64.decode(serverPrivateKey));
//            KeyFactory generator = KeyFactory.getInstance(ECDH_ALGORITHM);
//            PrivateKey privateKey = generator.generatePrivate(privateKeySpec);
//
//            EncodedKeySpec publicKeySpec = new X509EncodedKeySpec(Base64.decode(serverPublicKey));
//            this.publicKey = generator.generatePublic(publicKeySpec);
//            KeyPair keyPair = new KeyPair(publicKey, privateKey);
//
//            generateCertificate(keyPair).ifPresent(x509Certificate -> {
//
//                X509Certificate[] chain = new X509Certificate[1];
//                chain[0] = x509Certificate;
//                try {
//                    if (!this.contains(ALIAS_SERVER_ECDH_PRIVATE_KEY)) {
//                        this.keyStore.setKeyEntry(ALIAS_SERVER_ECDH_PRIVATE_KEY, privateKey, null, chain);
//                        log.warn("Storing ECDH server key");
//                    }
//                    else {
//                        log.info("Server ECDH key already stored");
//                    }
//                } catch (KeyStoreException e) {
//                    log.error("An expected error occured when trying to store the server public/private key due to {}", e.getMessage());
//                    throw new RuntimeException("Unoble to store the private key of the server");
//                }
//            });
//
//        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
//            log.error("An expected error occured when trying to convert the server public/private key due to {}", e.getMessage());
//        }
//
//    }

//    private boolean isServerKeyAlias(String alias) {
//        return Stream.of(ALIAS_SERVER_ECDH_PUBLIC_KEY, ALIAS_SERVER_ECDH_PRIVATE_KEY).anyMatch(item -> item.equals(alias));
//    }

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

//    // TODO: remove
//    private Optional<X509Certificate> generateCertificate(KeyPair keyPair) {
//        try {
//            // TODO: insert proper certificate info
//            X509v3CertificateBuilder certBuilder = new X509v3CertificateBuilder(
//                    new X500Name(SERVER_KEY_CERTIFICATE_CN), BigInteger.valueOf(System.currentTimeMillis()),
//                    new Date(System.currentTimeMillis() - 50000), new Date(System.currentTimeMillis() + 50000),
//                    new X500Name(SERVER_KEY_CERTIFICATE_CN), SubjectPublicKeyInfo.getInstance(keyPair.getPublic().getEncoded()));
//            JcaContentSignerBuilder builder = new JcaContentSignerBuilder("SHA512withECDSA");
//            ContentSigner signer = builder.build(keyPair.getPrivate());
//
//            byte[] certBytes = certBuilder.build(signer).getEncoded();
//            CertificateFactory certificateFactory = CertificateFactory.getInstance("X.509");
//            X509Certificate certificate = (X509Certificate)certificateFactory.generateCertificate(new ByteArrayInputStream(certBytes));
//            return Optional.ofNullable(certificate);
//
//        } catch (Exception e) {
//
//            log.error("An error occured when trying to generate the certificate: {} due to {}", e.getClass(), e.getMessage());
//        }
//        return Optional.empty();
//    }

    @Override
    public Provider getProvider() {

        return this.provider;
    }

    // TODO: use for encrypting K_S keys that would be stored in Postgre (instead of HSM) or remove
//    @Override
//    public Key getKeyForEncryptingServerKeys() {
//        return getKeyForEncryptingKeys(ALIAS_SERVER_KEK,
//                "Unable to retrieve key for encrypting keys (KEK) for server from HSM");
//    }

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
    public byte[] getServerKey(int epochId, long serviceTimeStart) {

        LocalDate dateFromEpoch = TimeUtils.getDateFromEpoch(epochId, serviceTimeStart);
        if (Objects.isNull(dateFromEpoch) ) {
            log.error("The date from epoch {} from the time start {} is null", epochId, serviceTimeStart);
            return null;
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

//                // TODO: FIX-FOR-PROD this should be done by an external process to work with many cryptoBE and their HSM
//                log.info("Creating new server key with alias {}", alias);
//                serverKey = ByteUtils.generateRandom(SERVER_KEY_SIZE);
//                this.keyStore.setKeyEntry(alias, new SecretKeySpec(serverKey, KEYSTORE_SKINNY64_ALGONAME), null, null);
//                this.serverKeyCache.put(alias, serverKey);
//                return serverKey;
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
