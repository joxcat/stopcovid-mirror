package fr.gouv.stopc.robert.server.crypto.structure;

import javax.crypto.Cipher;
import javax.crypto.Mac;
import javax.crypto.SecretKey;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;

import java.security.Key;

/**
 * Interface abstracting encryption algorithms
 * TripleDES, AES, HMAC-SHA256
 * This is described in the ROBERT specification document :
 * {@see <a href="https://github.com/ROBERT-proximity-tracing/documents/blob/master/ROBERT-specification-EN-v1_0.pdf">ROBERT: ROBust and privacy-presERving-proximity Tracing</a>}
 * §4 - Generation of the Ephemeral Bluetooth Identifiers
 * §5 - Proximity Discovery
 */
public interface ICryptoStructure<C extends Cipher, M extends Mac> {

    Key getSecretKey();

    /**
     * Encryption method TripleDES, AES, HMAC-SHA256
     * @param arguments are the keys to be encrypted
     * @return encrypted arguments
     * @throws RobertServerCryptoException
     */
    byte[] encrypt(byte[] arguments) throws RobertServerCryptoException;

    /**
     * Decryption method TripleDES, AES
     * @param arguments are the keys to be encrypted
     * @return decrypted arguments
     * @throws RobertServerCryptoException
     */
    default byte[] decrypt(byte[] arguments) throws RobertServerCryptoException {
        throw new RobertServerCryptoException();
    }

}
