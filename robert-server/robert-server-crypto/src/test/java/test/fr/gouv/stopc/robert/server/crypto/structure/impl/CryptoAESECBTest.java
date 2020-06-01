package test.fr.gouv.stopc.robert.server.crypto.structure.impl;


import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESECB;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESOFB;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.security.SecureRandom;
import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

@Slf4j
@ExtendWith(SpringExtension.class)
public class CryptoAESECBTest {
    @Test
    public void testCryptoAESECBEncryptDecryptSucceeds() throws RobertServerCryptoException {
        byte[] key = new byte[32];
        byte[] plainText = "1234567800000000".getBytes();
        new SecureRandom().nextBytes(key);

        CryptoAESECB cryptoToEncrypt = new CryptoAESECB(key);
        byte[] cipherText = cryptoToEncrypt.encrypt(plainText);
        assertTrue(cipherText.length == plainText.length);

        CryptoAESECB cryptoToDecrypt = new CryptoAESECB(key);
        byte[] decryptedText = cryptoToDecrypt.decrypt(cipherText);
        assertTrue(Arrays.equals(plainText, decryptedText));
    }

    @Test
    public void testCryptoAESECBCompareEncryptedSamples() throws RobertServerCryptoException {
        byte[] key = new byte[32];
        byte[] plainText = "1234567800000000".getBytes();
        byte[] plainTextModified = "0123456700000000".getBytes();
        new SecureRandom().nextBytes(key);

        CryptoAESECB cryptoToEncrypt = new CryptoAESECB(key);
        byte[] cipherText = cryptoToEncrypt.encrypt(plainText);
        assertTrue(cipherText.length == plainText.length);

        CryptoAESECB cryptoToEncryptModified = new CryptoAESECB(key);
        byte[] cipherTextModified = cryptoToEncryptModified.encrypt(plainTextModified);
        assertFalse(Arrays.equals(cipherText, cipherTextModified));
    }
}
