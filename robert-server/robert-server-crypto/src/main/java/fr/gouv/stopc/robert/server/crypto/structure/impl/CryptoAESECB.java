package fr.gouv.stopc.robert.server.crypto.structure.impl;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.structure.CryptoAES;
import lombok.extern.slf4j.Slf4j;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.security.InvalidKeyException;
import java.security.Key;

@Slf4j
public class CryptoAESECB extends CryptoAES {

    private static final String AES_ENCRYPTION_CIPHER_SCHEME = "AES/ECB/NoPadding";

    public CryptoAESECB(byte[] key) {
        super(AES_ENCRYPTION_CIPHER_SCHEME, new SecretKeySpec(key, CryptoAES.AES_ENCRYPTION_KEY_SCHEME));
    }

    public CryptoAESECB(Key key) {
        super(AES_ENCRYPTION_CIPHER_SCHEME, key);
    }

    @Override
    public byte[] encrypt(byte[] plainText) throws RobertServerCryptoException {
        return super.encrypt(plainText);
    }

    @Override
    public byte[] decrypt(byte[] cipherText) throws RobertServerCryptoException {
        try {
            this.getDecryptCypher().init(Cipher.DECRYPT_MODE, this.getSecretKey());
        } catch (InvalidKeyException e ) {
            log.error(e.getMessage(), e);
            throw new RobertServerCryptoException(e.getMessage());
        }
        return super.decrypt(cipherText);
    }
}
