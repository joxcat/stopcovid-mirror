package test.fr.gouv.stopc.robertserver.dataset.injector.utils;

import lombok.extern.slf4j.Slf4j;

import javax.crypto.KeyGenerator;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;

@Slf4j
public class GenerateIdUtils {

    private GenerateIdUtils() {
        throw new AssertionError();
    }

    public static byte[] generateIdA() {
        return generateRandomByteArrayOfSize(5);
    }

    public static byte[] getKeyMacFor(byte[] idA) {
        return generateRandomByteArrayOfSize(32);
    }

    public static byte[] generateRandomByteArrayOfSize(int size) {
        byte[] rndBytes = new byte[size];
        SecureRandom sr = new SecureRandom();
        sr.nextBytes(rndBytes);

        return rndBytes;
    }

    public static byte [] generateRandomKey() {
        byte [] ka = null;

        try {
            KeyGenerator keyGen = KeyGenerator.getInstance("HmacSHA256");

            //Creating a SecureRandom object
            SecureRandom secRandom = new SecureRandom();

            //Initializing the KeyGenerator
            keyGen.init(secRandom);

            //Creating/Generating a key
            Key key = keyGen.generateKey();
            ka = key.getEncoded();
        } catch (NoSuchAlgorithmException e) {
            log.error("Could not generate 256-bit key");
        }
        return ka;
    }
}
