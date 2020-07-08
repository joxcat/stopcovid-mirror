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
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

import javax.crypto.spec.SecretKeySpec;

import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import fr.gouv.stopc.robert.crypto.grpc.server.storage.cryptographic.service.ICryptographicStorageService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import lombok.extern.slf4j.Slf4j;
import sun.security.pkcs11.SunPKCS11;

@Slf4j
@Service
public class CryptographicStorageServiceImpl implements ICryptographicStorageService {


    private static final int SERVER_KEY_SIZE = 24;

    // Because Java does not know Skinny64, specify AES instead
    private static final String KEYSTORE_KG_ALGONAME = "AES";

    //private static final String ALIAS_SERVER_ECDH_PUBLIC_KEY = "server-ecdh-key";
    private static final String ALIAS_SERVER_ECDH_PRIVATE_KEY = "register-key"; // ECDH
    //private static final String ALIAS_SERVER_KEK = "server-key-encryption-key;
    private static final String ALIAS_CLIENT_KEK = "key-encryption-key"; // KEK
    private static final String ALIAS_FEDERATION_KEY = "federation-key"; // K_G
    private static final String ALIAS_SERVER_KEY_PREFIX = "server-key-"; // K_S

    private static final String KEYSTORE_TYPE = "PKCS11";

    private KeyPair keyPair;

    // Cache for K_S keys
    private Map<String, byte[]> serverKeyCache;

    // Cache for KEK keys
    private Map<String, Key> kekCache;

    private Provider provider;
    private KeyStore keyStore;

    private Key federationKeyCached;

    @Override
    public void init(String password, String configFile) {

        if (!StringUtils.hasText(password) || !StringUtils.hasText(configFile)) {
            throw new IllegalArgumentException("The init argument cannot be empty");
        }

        boolean hsmLoadSuccessful = this.loadSecurityProvider(password, configFile);
        if (!hsmLoadSuccessful) {
            throw new RuntimeException("Could not add security provider");
        }

        serverKeyCache = new HashMap<>();
        kekCache = new HashMap<>();
    }

    private boolean loadSecurityProvider(String password, String configFile) {
        try {

            // Required for JDK 1.8
            this.provider = new SunPKCS11(configFile);
            if (-1 == Security.addProvider(this.provider)) {
                return false;
            }

            // For JDK 1.9+, uncomment line below and delete code above
            //this.provider = Security.getProvider("SunPKCS11").configure(configFile);

            char[] keyStorePassword = password.toCharArray();
            this.keyStore = KeyStore.getInstance(KEYSTORE_TYPE, this.provider);
            this.keyStore.load(null, keyStorePassword);
        } catch (KeyStoreException | NoSuchAlgorithmException | CertificateException | IOException | ProviderException  e) {

            log.error("An expected error occurred when trying to initialize the keyStore {} due to {}", e.getClass(), e.getMessage());
            return false;
        }
        return true;
    }

    @Override
    public boolean contains(String alias) {

        synchronized (protectHsmReload) {
            try {
                return this.keyStore.containsAlias(alias);
            } catch (KeyStoreException e) {
                log.info("An expected error occurred when trying to check if keystore contains the alias {} due to {}", alias, e.getMessage());
            }
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
        } else {
            synchronized (protectHsmReload) {
                if (this.keyPair == null) {
                    try {
                        PrivateKey privateKey = (PrivateKey) this.keyStore.getKey(ALIAS_SERVER_ECDH_PRIVATE_KEY, null);
                        PublicKey publicKey = this.keyStore.getCertificate(ALIAS_SERVER_ECDH_PRIVATE_KEY).getPublicKey();

                        this.keyPair = new KeyPair(publicKey, privateKey);
                        return Optional.ofNullable(this.keyPair);
                    } catch (KeyStoreException | UnrecoverableKeyException | NoSuchAlgorithmException e) {
                        log.error("Unable to retrieve the server key pair due to {}", e.getMessage());
                    }
                } else {
                    return Optional.of(this.keyPair);
                }
            }
        }

        return Optional.empty();
    }

    @Override
    public byte[] getEntry(String alias) {

        synchronized (protectHsmReload) {
            try {
                if (this.contains(alias)) {
                    return this.keyStore.getKey(alias, null).getEncoded();
                }
            } catch (KeyStoreException | UnrecoverableKeyException | NoSuchAlgorithmException e) {
                log.error("An expected error occurred when trying to get the entry {} due to {}", alias, e.getMessage());
            }
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
        } else {
            synchronized (protectHsmReload) {
                if (!this.kekCache.containsKey(alias)) {
                    try {

                        Key key = this.keyStore.getKey(alias, null);
                        this.kekCache.put(alias, key);
                        return key;
                    } catch (KeyStoreException | NoSuchAlgorithmException | UnrecoverableKeyException | IllegalStateException e) {
                        log.error(errorMessage);
                    }
                } else {
                    return this.kekCache.get(alias);
                }
            }
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
                serverKey = this.serverKeyCache.get(alias);
            }
            else {
                synchronized (protectHsmReload) {
                    if (!this.serverKeyCache.containsKey(alias)) {
                        if (!this.keyStore.containsAlias(alias)) {
                            log.error("Key store does not contain key for alias {}", alias);
                        } else {
                            Key key = this.keyStore.getKey(alias, null);
                            serverKey = key.getEncoded();
                            this.serverKeyCache.put(alias, serverKey);
                        }
                    } else {
                        serverKey = this.serverKeyCache.get(alias);
                    }
                }
            }
        } catch (Exception e) {
            log.error("An expected error occurred when trying to get the alias {} due to {}", dateFromEpoch, e.getMessage());
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
                synchronized (protectHsmReload) {
                    if (this.federationKeyCached == null) {
                        if (this.keyStore.containsAlias(ALIAS_FEDERATION_KEY)) {
                            log.info("Fetching and caching federation key from keystore");
                            Key federationKeyFromHSM = this.keyStore.getKey(ALIAS_FEDERATION_KEY, null);

                            // TODO: review this and create issue tracking this behaviour
                            // Copy key content in new key to prevent any delegation to HSM and perform encryption in Java
                            this.federationKeyCached = new SecretKeySpec(federationKeyFromHSM.getEncoded(), KEYSTORE_KG_ALGONAME);
                        }
                    }
                }
            }
        } catch (KeyStoreException | NoSuchAlgorithmException | UnrecoverableKeyException e) {
            log.error("Could not retrieve federation key from keystore");
        }
        return this.federationKeyCached;
    }

    private final Object protectHsmReload = new Object();

    @Override
    public boolean reloadHSM(String pin, String configName) {
        log.info("HSM reload requested");
        synchronized (protectHsmReload) {
            log.info("Removing security provider");
            Security.removeProvider(provider.getName());

            // Flush keys
            this.serverKeyCache.clear();
            this.keyPair = null;
            this.kekCache.clear();
            log.info("Flushed cached keys");

            boolean reloadResult = this.loadSecurityProvider(pin, configName);

            if (!reloadResult) {
                log.error("Could not reload Security Provider for HSM");
            } else {
                // Pre-warm cache
                this.prewarmCache();
                log.info("HSM reload successful");
            }

            return reloadResult;
        }
    }

    private void prewarmCache() {
        log.info("Pre-warming cache");

        log.info("Caching federation key");
        this.getFederationKey();

        log.info("Caching key encryption key");
        this.getKeyForEncryptingClientKeys();

        log.info("Caching server key pair");
        this.getServerKeyPair();

        // Cache current and future keys
        LocalDate dateForCachedServerKey = LocalDate.now(ZoneId.of("UTC"));
        byte[] res;
        do {
            log.info("Caching future server key for {}", dateForCachedServerKey);
            res = this.getServerKey(dateForCachedServerKey);
            dateForCachedServerKey = dateForCachedServerKey.plusDays(1);
        } while (res != null);

        // Cache previous keys
        dateForCachedServerKey = LocalDate.now(ZoneId.of("UTC")).minusDays(1);
        do {
            log.info("Caching past server key for {}", dateForCachedServerKey);
            res = this.getServerKey(dateForCachedServerKey);
            dateForCachedServerKey = dateForCachedServerKey.minusDays(1);
        } while (res != null);
    }

    @Override
    public List<String> getHSMCacheStatus() {
        ArrayList<String> aliases = new ArrayList<>();

        if (!Objects.isNull(this.keyPair)) {
            if (!Objects.isNull(this.keyPair.getPublic())) {
                aliases.add(String.format("Server Public ECDH Key '%s'", ALIAS_SERVER_ECDH_PRIVATE_KEY));
            }
            if (!Objects.isNull(this.keyPair.getPrivate())) {
                aliases.add(String.format("Server Private ECDH Key '%s'", ALIAS_SERVER_ECDH_PRIVATE_KEY));
            }
        }

        if (!CollectionUtils.isEmpty(this.kekCache)) {
            aliases.addAll(this.kekCache.keySet().stream().map(elt -> String.format("Key Encryption Key '%s'", elt)).collect(Collectors.toList()));
        }

        if (!Objects.isNull(this.federationKeyCached)) {
            aliases.add(String.format("Federation Key '%s'", ALIAS_FEDERATION_KEY));
        }

        if (!CollectionUtils.isEmpty(this.serverKeyCache)) {
            aliases.addAll(this.serverKeyCache.keySet().stream().map(elt -> String.format("Server Key '%s'", elt)).collect(Collectors.toList()));
        }

        if (aliases.size() == 0) {
            log.warn("HSM Cache Status yielded 0 keys");
        } else {
            log.info("HSM Cache Status yielded {} keys ", aliases.size());
        }
        aliases.sort(Comparator.naturalOrder());
        return aliases;
    }
}
