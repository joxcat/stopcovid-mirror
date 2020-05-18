package fr.gouv.stopc.robert.server.crypto.structure;

import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public abstract class CryptoCipherStructureAbstract implements ICryptoStructure, ICipherStructure {

    /**
     * @param payloadToEncrypt arguments[0] should be byte[] to encrypt
     * @return the arguments[0] encrypted with TripleDES algo
     */
    @Override
    public byte[] encrypt(byte[] payloadToEncrypt) throws RobertServerCryptoException {
        try {
            this.getCipher().init(Cipher.ENCRYPT_MODE, this.getSecretKey(), this.getIv());

            return this.getCipher().doFinal(payloadToEncrypt);
        } catch (InvalidKeyException | InvalidAlgorithmParameterException | IllegalBlockSizeException | BadPaddingException e) {
            log.error(e.getMessage(), e);
            throw new RobertServerCryptoException(e.getMessage());
        }
    }

    /**
     * @param payloadToEncrypt argument should be byte[] to decrypt
     * @return payloadToEncrypted depending the {@link #getCipher()} and {@link #getSecretKey()} provided by implemented algo
     */
    @Override
    public byte[] decrypt(byte[] payloadToEncrypt) throws RobertServerCryptoException {
        try {
            this.getCipher().init(Cipher.DECRYPT_MODE, this.getSecretKey(), this.getIv());

            return this.getCipher().doFinal(payloadToEncrypt);
        } catch (InvalidKeyException | InvalidAlgorithmParameterException | IllegalBlockSizeException | BadPaddingException e) {
            log.error(e.getMessage(), e);
            throw new RobertServerCryptoException(e.getMessage());
        }
    }

}
