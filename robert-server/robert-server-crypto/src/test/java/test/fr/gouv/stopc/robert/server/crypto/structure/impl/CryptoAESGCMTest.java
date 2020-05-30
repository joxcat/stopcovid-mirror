package test.fr.gouv.stopc.robert.server.crypto.structure.impl;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESGCM;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.security.SecureRandom;
import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.*;

@Slf4j
@ExtendWith(SpringExtension.class)
public class CryptoAESGCMTest {
    @Test
    public void testCryptoAESGCMEncryptDecryptSucceeds() throws RobertServerCryptoException {
        byte[] key = new byte[32];
        byte[] plainText = "plaintexttoencrypt".getBytes();
        new SecureRandom().nextBytes(key);
        CryptoAESGCM cryptoToEncrypt = new CryptoAESGCM(key);
        byte[] cipherText = cryptoToEncrypt.encrypt(plainText);

        assertTrue(cipherText.length == plainText.length + 12 + 16);

        CryptoAESGCM cryptoToDecrypt = new CryptoAESGCM(key);
        byte[] decryptedText = cryptoToDecrypt.decrypt(cipherText);
        assertTrue(Arrays.equals(plainText, decryptedText));
    }

    @Test
    public void testCryptoAESGCMEncryptDecryptBadIVFails() throws RobertServerCryptoException {
        byte[] key = new byte[32];
        byte[] plainText = "plaintexttoencrypt".getBytes();
        new SecureRandom().nextBytes(key);
        CryptoAESGCM cryptoToEncrypt = new CryptoAESGCM(key);
        byte[] cipherText = cryptoToEncrypt.encrypt(plainText);

        assertTrue(cipherText.length == plainText.length + 12 + 16);

        // Change a bit from the IV
        cipherText[3] = (byte)(cipherText[3] ^ 0x8);

        CryptoAESGCM cryptoToDecrypt = new CryptoAESGCM(key);
        Assertions.assertThrows(RobertServerCryptoException.class, () -> cryptoToDecrypt.decrypt(cipherText));
    }

    @Test
    public void testCryptoAESGCMEncryptDecryptBadTagFails() throws RobertServerCryptoException {
        byte[] key = new byte[32];
        byte[] plainText = "plaintexttoencrypt".getBytes();
        new SecureRandom().nextBytes(key);
        CryptoAESGCM cryptoToEncrypt = new CryptoAESGCM(key);
        byte[] cipherText = cryptoToEncrypt.encrypt(plainText);

        assertTrue(cipherText.length == plainText.length + 12 + 16);

        // Change a bit from the IV
        int indexToMessWith = plainText.length + 12 + 5;
        cipherText[indexToMessWith] = (byte)(cipherText[indexToMessWith] ^ 0x8);

        CryptoAESGCM cryptoToDecrypt = new CryptoAESGCM(key);
        Assertions.assertThrows(RobertServerCryptoException.class, () -> cryptoToDecrypt.decrypt(cipherText));
    }
}
