package fr.gouv.stopc.robert.server.crypto.structure.impl;

import java.security.NoSuchAlgorithmException;

import javax.crypto.Mac;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import fr.gouv.stopc.robert.server.crypto.structure.CryptoMacStructureAbstract;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class CryptoHMACSHA256 extends CryptoMacStructureAbstract {

    public static final String HMAC_SHA_256 = "HmacSHA256";


    private final SecretKey key;
    private final Mac mac;

    /**
     * @param applicationKey key shared between application and  server
     */
    public CryptoHMACSHA256(byte[] applicationKey) {
        Mac mac = null;
        SecretKey key = null;
        try {
            // Generate encryption key with server federate key.
            key = new SecretKeySpec(applicationKey, HMAC_SHA_256);

            // Create cipher with AES encryption scheme.
            mac = Mac.getInstance(HMAC_SHA_256);

        } catch (NoSuchAlgorithmException e) {
            log.error(String.format("Algorithm %s is not available", HMAC_SHA_256));
        } finally {
            this.mac = mac;
            this.key = key;
        }
    }


    @Override
    public SecretKey getSecretKey() {
        return this.key;
    }

    @Override
    public Mac getMac() {
        return this.mac;
    }
}
