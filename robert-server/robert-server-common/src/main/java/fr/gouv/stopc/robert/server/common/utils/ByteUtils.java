package fr.gouv.stopc.robert.server.common.utils;

import java.nio.ByteBuffer;
import java.security.SecureRandom;

/**
 * Simplify conversion to/from numerical value to byte arrays
 */
public final class ByteUtils {

    public static byte[] longToBytes(long x) {
        ByteBuffer bufferLong = ByteBuffer.allocate(Long.BYTES);
        bufferLong.putLong(0, x);
        return bufferLong.array();
    }

    public static long bytesToLong(byte[] bytes) {
        ByteBuffer bufferLong = ByteBuffer.allocate(Long.BYTES);
        bufferLong.put(bytes, 0, bytes.length);
        bufferLong.flip();
        return bufferLong.getLong();
    }

    public static byte[] intToBytes(int x) {
        ByteBuffer bufferInt = ByteBuffer.allocate(Integer.BYTES);
        bufferInt.putInt(0, x);
        return bufferInt.array();
    }

    public static int bytesToInt(byte[] bytes) {
        ByteBuffer bufferInt = ByteBuffer.allocate(Integer.BYTES);
        bufferInt.put(bytes, 0, bytes.length);
        bufferInt.flip();
        return bufferInt.getInt();
    }

    public static int convertEpoch24bitsToInt(byte[] epoch24) {
        ByteBuffer buffer = ByteBuffer.allocate(Integer.BYTES);
        buffer.put((byte)0x0); // pad first byte
        buffer.put(epoch24, 0, epoch24.length);
        buffer.flip();
        return buffer.getInt();
    }

    public static byte[] addAll(byte[] a, byte[] b) {
        if (a == null) {
            byte[] copy = new byte[b.length];
            System.arraycopy(b, 0, copy, 0, b.length);
            return copy;
        } else if (b == null) {
            byte[] copy = new byte[a.length];
            System.arraycopy(a, 0, copy, 0, a.length);
            return copy;
        }

        byte[] res = new byte[a.length + b.length];
        System.arraycopy(a, 0, res, 0, a.length);
        System.arraycopy(b, 0, res, a.length, b.length);
        return res;
    }

    public static boolean isEmpty(byte[] array) {
        if (array == null || array.length == 0) {
            return true;
        }
        return false;
    }

    public static boolean isNotEmpty(byte[] array) {
        return !isEmpty(array);
    }

    public static byte[] EMPTY_BYTE_ARRAY = new byte[0];

    public static byte[] generateRandom(final int nbOfbytes) {
        byte[] rndBytes = new byte[nbOfbytes];
        SecureRandom sr = new SecureRandom();
        sr.nextBytes(rndBytes);
        return rndBytes;
    }
}

