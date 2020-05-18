package fr.gouv.stopc.robert.server.crypto.structure.impl;

import java.security.NoSuchAlgorithmException;

import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import fr.gouv.stopc.robert.server.crypto.structure.CryptoCipherStructureAbstract;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class CryptoAES extends CryptoCipherStructureAbstract {

    private static final String AES_ENCRYPTION_KEY_SCHEME = "AES";

    private static final String AES_ENCRYPTION_CIPHER_SCHEME = "AES/OFB/NoPadding";

    /**
     * IV here is not constant it is reassign every encryption or decryption by ebid parameter
     */
    private IvParameterSpec iv;

    private final Cipher cipher;

    private final SecretKey key;

    /**
     * @param federationKey key shared between multiple countries
     */
    public CryptoAES(byte[] federationKey) {
        Cipher cipher = null;
        SecretKey key = null;
        try {

            // Generate encryption key with server federate key.
            key = new SecretKeySpec(federationKey, AES_ENCRYPTION_KEY_SCHEME);

            // Create cipher with AES encryption scheme.
            cipher = Cipher.getInstance(AES_ENCRYPTION_CIPHER_SCHEME);

        } catch (NoSuchAlgorithmException | NoSuchPaddingException e) {
            log.error(String.format("Algorithm %s is not available", AES_ENCRYPTION_CIPHER_SCHEME));
        } finally {
            this.cipher = cipher;
            this.key = key;
        }
    }

    @Override
    public Cipher getCipher() {
        return this.cipher;
    }

    @Override
    public SecretKey getSecretKey() {
        return this.key;
    }

    @Override
    public IvParameterSpec getIv() {
        return this.iv;
    }

    @Override
    public byte[] decrypt(byte[] ebid) throws RobertServerCryptoException {
        // as written in specification : reassign iv with ebid
        this.iv = new IvParameterSpec(ebid);
        return super.decrypt(ebid);
    }

    @Override
    public byte[] encrypt(byte[] ebid) throws RobertServerCryptoException {
        // as written in specification : reassign iv with ebid
        this.iv = new IvParameterSpec(ebid);
        return super.encrypt(ebid);
    }
}
