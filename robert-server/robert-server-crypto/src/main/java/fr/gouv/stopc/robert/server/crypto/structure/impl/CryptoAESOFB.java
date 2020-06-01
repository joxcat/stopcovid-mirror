package fr.gouv.stopc.robert.server.crypto.structure.impl;

import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.util.Objects;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.structure.CryptoAES;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class CryptoAESOFB extends CryptoAES {

    private static final String AES_ENCRYPTION_CIPHER_SCHEME = "AES/OFB/NoPadding";

    public CryptoAESOFB(byte[] key) {
        super(AES_ENCRYPTION_CIPHER_SCHEME, new SecretKeySpec(key, CryptoAES.AES_ENCRYPTION_KEY_SCHEME));
    }

    @Override
    public byte[] encrypt(byte[] plainText) throws RobertServerCryptoException {
        this.algorithmParameterSpec = new IvParameterSpec(plainText);
        return super.encrypt(plainText);
    }

    @Override
    public byte[] decrypt(byte[] cipherText) throws RobertServerCryptoException {
        if (Objects.isNull(this.algorithmParameterSpec)) {
            throw new RobertServerCryptoException("IV must be set before decryption");
        }
        try {
            this.getDecryptCypher().init(Cipher.DECRYPT_MODE, this.getSecretKey(), this.algorithmParameterSpec);
        } catch (InvalidKeyException | InvalidAlgorithmParameterException e ) {
            log.error(e.getMessage(), e);
            throw new RobertServerCryptoException(e.getMessage());
        }
        return super.decrypt(cipherText);
    }

    public void setIvForDecryption(byte[] iv) {
        this.algorithmParameterSpec = new IvParameterSpec(iv);
    }
}
