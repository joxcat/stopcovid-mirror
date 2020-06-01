package fr.gouv.stopc.robert.server.crypto.structure;

import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.spec.AlgorithmParameterSpec;
import java.util.Objects;

import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public abstract class CryptoAES extends CryptoCipherStructureAbstract {

    public static final String AES_ENCRYPTION_KEY_SCHEME = "AES";

    protected AlgorithmParameterSpec algorithmParameterSpec;

    protected final Cipher cipher;

    protected  Cipher decryptCypher;

    protected final Key keySpec;

    /**
     * @param key to be used for cipher
     */
    public CryptoAES(byte[] key, String cipherScheme) {
        Cipher cipher = null;
        SecretKey keySpec = null;
        try {

            // Generate encryption keySpec with server federate keySpec.
            keySpec = new SecretKeySpec(key, AES_ENCRYPTION_KEY_SCHEME);

            // Create cipher with AES encryption scheme.
            cipher = Cipher.getInstance(cipherScheme);
            decryptCypher = Cipher.getInstance(cipherScheme);
            if (Objects.nonNull(getAlgorithmParameterSpec())) {
//                cipher.init(Cipher.ENCRYPT_MODE, keySpec, this.getAlgorithmParameterSpec());
                decryptCypher.init(Cipher.DECRYPT_MODE, keySpec, this.getAlgorithmParameterSpec());
            }
            else {
                cipher.init(Cipher.ENCRYPT_MODE, keySpec);
                decryptCypher.init(Cipher.DECRYPT_MODE, keySpec);
            }

        } catch (NoSuchAlgorithmException | NoSuchPaddingException | InvalidKeyException | InvalidAlgorithmParameterException e) {
            log.error(String.format("Algorithm %s is not available", cipherScheme));
        } finally {
            this.cipher = cipher;
            this.keySpec = keySpec;
        }
    }

    public CryptoAES(String cipherScheme, Key key) {
        Cipher cipher = null;
        this.keySpec = key;
        try {
            // Create cipher with AES encryption scheme.
            cipher = Cipher.getInstance(cipherScheme);
            decryptCypher = Cipher.getInstance(cipherScheme);
            if (Objects.nonNull(getAlgorithmParameterSpec())) {
                cipher.init(Cipher.ENCRYPT_MODE, key, this.getAlgorithmParameterSpec());
            }
            else {
                cipher.init(Cipher.ENCRYPT_MODE, key);
            }

        } catch (NoSuchAlgorithmException | NoSuchPaddingException | InvalidKeyException | InvalidAlgorithmParameterException e) {
            log.error(String.format("Algorithm %s is not available", cipherScheme));
        } finally {
            this.cipher = cipher;
        }
    }

    @Override
    public Cipher getCipher() {
        return this.cipher;
    }

    @Override
    public Key getSecretKey() {
        return this.keySpec;
    }

    @Override
    public AlgorithmParameterSpec getAlgorithmParameterSpec() {
        return this.algorithmParameterSpec;
    }

    @Override
    public Cipher getDecryptCypher() {
        return this.decryptCypher;
    }
}

