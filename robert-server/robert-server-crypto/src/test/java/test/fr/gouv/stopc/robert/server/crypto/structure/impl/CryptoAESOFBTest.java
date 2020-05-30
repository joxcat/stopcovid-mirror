package test.fr.gouv.stopc.robert.server.crypto.structure.impl;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESOFB;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.security.SecureRandom;
import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.*;

@Slf4j
@ExtendWith(SpringExtension.class)
public class CryptoAESOFBTest {
    @Test
    public void testCryptoAESOFBEncryptDecryptSucceeds() throws RobertServerCryptoException {
        byte[] key = new byte[32];
        byte[] plainText = "1234567800000000".getBytes();
        new SecureRandom().nextBytes(key);

        CryptoAESOFB cryptoToEncrypt = new CryptoAESOFB(key);
        byte[] cipherText = cryptoToEncrypt.encrypt(plainText);
        assertTrue(cipherText.length == plainText.length);

        CryptoAESOFB cryptoToDecrypt = new CryptoAESOFB(key);
        cryptoToDecrypt.setIvForDecryption(plainText);
        byte[] decryptedText = cryptoToDecrypt.decrypt(cipherText);
        assertTrue(Arrays.equals(plainText, decryptedText));
    }

    @Test
    public void testCryptoAESOFBEncryptDecryptBadIvFails() throws RobertServerCryptoException {
        byte[] key = new byte[32];
        byte[] plainText = "1234567800000000".getBytes();
        new SecureRandom().nextBytes(key);

        CryptoAESOFB cryptoToEncrypt = new CryptoAESOFB(key);
        byte[] cipherText = cryptoToEncrypt.encrypt(plainText);
        assertTrue(cipherText.length == plainText.length);

        CryptoAESOFB cryptoToDecrypt = new CryptoAESOFB(key);
        cryptoToDecrypt.setIvForDecryption("8765432100000000".getBytes());
        byte[] decryptedText = cryptoToDecrypt.decrypt(cipherText);
        assertFalse(Arrays.equals(plainText, decryptedText));
    }
}
