package test.fr.gouv.stopc.robertserver.batch.utils;

import java.security.SecureRandom;

public final class ProcessorTestUtils {
    private ProcessorTestUtils() {
        throw new AssertionError();
    }

    public static byte[] generateIdA() {
        return generateRandomByteArrayOfSize(5);
    }

    public static byte[] generateRandomByteArrayOfSize(int size) {
        byte[] rndBytes = new byte[size];
        SecureRandom sr = new SecureRandom();
        sr.nextBytes(rndBytes);

        return rndBytes;
    }
}
