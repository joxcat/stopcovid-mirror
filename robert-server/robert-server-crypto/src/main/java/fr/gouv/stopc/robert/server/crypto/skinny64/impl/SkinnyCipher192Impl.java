/* 
* Copyright (C) Inria, 2020 
*/
package fr.gouv.stopc.robert.server.crypto.skinny64.impl;

import fr.gouv.stopc.robert.server.crypto.skinny64.Skinny64Key;
import fr.gouv.stopc.robert.server.crypto.skinny64.SkinnyCipher192;

/**
 * Skinny block cipher 'simplified' with key of 192 bits size implementation
 */
public class SkinnyCipher192Impl implements SkinnyCipher192 {

    /**
     * Write the first 2 bytes (16 bits) value in the buffer ptr[offset]
     *
     * @param ptr    buffer of bytes
     * @param offset offset
     * @param value  first 2 bytes of value are used
     */
    final private void writeWord16(final byte[] ptr, final int offset, final int value) {

        ptr[offset] = (byte) value;
        ptr[offset + 1] = (byte) (value >> 8);
    }

    /**
     * Apply LFSR2 to x_32u
     *
     * @param x_32u first 32 bits input
     * @return first 32 bits output
     */
    final private int lfsr2(final int x_32u) {
        return (((x_32u << 1) & 0xEEEEEEEE) ^ (((x_32u >> 3) ^ (x_32u >> 2)) & 0x11111111));
    }

    /**
     * Apply LFSR3 to x_32u
     *
     * @param x_32u first 32 bits input
     * @return first 32 bits output
     */
    final private int lfsr3(final int x_32u) {
        return (((x_32u >> 1) & 0x77777777) ^ ((x_32u ^ (x_32u << 3)) & 0x88888888));
    }

    /**
     * Permute tk cells
     *
     * @param tk Skinny64Key cells
     */
    final private void permuteTk(final Skinny64Key.Cells tk) {
        final int row2 = tk.get16(2);
        int row3 = tk.get16(3);
        tk.set16(tk.get16(0), 2);
        tk.set16(tk.get16(1), 3);
        row3 = (row3 << 8) | (row3 >> 8);
        int tmprow = ((row2 << 4) & 0x00F0) | ((row2 << 8) & 0xF000) | (row3 & 0x0F0F);
        tk.set16(tmprow, 0);
        tmprow = ((row2 >> 8) & 0x00F0) | (row2 & 0x0F00) | ((row3 >> 4) & 0x000F) | (row3 & 0xF000);
        tk.set16(tmprow, 1);
    }

    /**
     * Initializes the key schedule with TK1
     *
     * @param ks       Skinny64 block ciphers
     * @param key      Key of cryption
     * @param index    index of cells buffer
     */
    final private void setTk1(final Skinny64Key ks, final byte[] key, final int index) {
        final Skinny64Key.Cells tk = new Skinny64Key.Cells();
        int idx;
        int rc = 0;

        /* Unpack the key */
        tk.setWord16(0, key, index);
        tk.setWord16(1, key, index + 2);
        tk.setWord16(2, key, index + 4);
        tk.setWord16(3, key, index + 6);

        /* Generate the key schedule words for all rounds */
        for (idx = 0; idx < SKINNY64_MAX_ROUNDS; ++idx) {
            /* Determine the subkey to use at this point in the key schedule */
            ks.schedule[idx].set16(tk.get16(0), 0);
            ks.schedule[idx].set16(tk.get16(1), 1);

            /*
             * XOR in the round constants for the first two rows. The round constants for
             * the 3rd and 4th rows are fixed and will be applied during encrypt/decrypt
             */
            rc = (rc << 1) ^ ((rc >> 5) & 0x01) ^ ((rc >> 4) & 0x01) ^ 0x01;
            rc &= 0x3F;
            ks.schedule[idx].xor16(((rc & 0x0F) << 4), 0);
            ks.schedule[idx].xor16((rc & 0x30), 1);

            /* Permute TK1 for the next round */
            permuteTk(tk);
        }
    }

    /**
     * XOR the key schedule with TK2
     *
     * @param ks       Skinny64 block ciphers
     * @param key      Key of cryption
     * @param index    index of cells buffer
     */
    final private void setTk2(final Skinny64Key ks, final byte[] key, final int index) {
        final Skinny64Key.Cells tk = new Skinny64Key.Cells();
        int idx;

        /* Unpack the key */
        tk.setWord16(0, key, index);
        tk.setWord16(1, key, index + 2);
        tk.setWord16(2, key, index + 4);
        tk.setWord16(3, key, index + 6);

        /* Generate the key schedule words for all rounds */
        for (idx = 0; idx < SKINNY64_MAX_ROUNDS; ++idx) {
            /* Determine the subkey to use at this point in the key schedule */
            ks.schedule[idx].xor32(tk.get32(0), 0);

            /* Permute TK2 for the next round */
            permuteTk(tk);

            /* Apply LFSR2 to the first two rows of TK2 */
            tk.set32(lfsr2(tk.get32(0)));
        }
    }

    /**
     * XOR the key schedule with TK3
     *
     * @param ks       Skinny64 block ciphers
     * @param key      Key of cryption
     * @param index    Index of cells buffer
     */
    final private void setTk3(final Skinny64Key ks, final byte[] key, final int index) {
        final Skinny64Key.Cells tk = new Skinny64Key.Cells();
        int idx;

        /* Unpack the key */
        tk.setWord16(0, key, index);
        tk.setWord16(1, key, index + 2);
        tk.setWord16(2, key, index + 4);
        tk.setWord16(3, key, index + 6);

        /* Generate the key schedule words for all rounds */
        for (idx = 0; idx < SKINNY64_MAX_ROUNDS; ++idx) {
            /* Determine the subkey to use at this point in the key schedule */
            ks.schedule[idx].xor32(tk.get32(0), 0);

            /* Permute TK3 for the next round */
            permuteTk(tk);

            /* Apply LFSR3 to the first two rows of TK3 */
            tk.set32(lfsr3(tk.get32(0)));
        }
    }

    @Override
    final public void setKey(final Skinny64Key ks, final byte[] key) {
        /* Validate the parameters */
        if ( ( ks == null) || (key == null) ) {
            throw new IllegalArgumentException("setKey: Skinny64Key or key must be set");
        }

        if ( key.length != SKINNY64_KEY_SIZE ) {
            throw new IllegalArgumentException("setKey: key length is not valid");
        }

        setTk1(ks, key, 0);
        setTk2(ks, key, SKINNY64_BLOCK_SIZE);
        setTk3(ks, key, SKINNY64_BLOCK_SIZE * 2);
    }

    @Override
    final public void clearKey(final Skinny64Key ks) {
        /* Validate the parameters */
        if ( ( ks == null)  ) {
            throw new IllegalArgumentException("clearKey: Skinny64Key must be set");
        }

        ks.clear();
    }

    /**
     * Bit right rotation
     *
     * @param x_16u   First 16 bits to be rotated
     * @param count_u Count of rotation
     * @return
     */
    final private int rotateRight(final int x_16u, final int count_u) {
        return ((x_16u >> count_u) | (x_16u << (16 - count_u)));
    }

    /**
     * Sbox shift
     *
     * @param x_32u first 32 bits input
     * @return output of the Sbox shift
     */
    final private int sbox32(int x_32u) {
        /*
         * Original version from the specification is equivalent to:
         *
         * #define SBOX_MIX(x) (((~((((x) >> 1) | (x)) >> 2)) & 0x11111111U) ^ (x))
         * #define SBOX_SHIFT(x) ((((x) << 1) & 0xEEEEEEEEU) | (((x) >> 3) &
         * 0x11111111U))
         *
         * x = SBOX_MIX(x); x = SBOX_SHIFT(x); x = SBOX_MIX(x); x = SBOX_SHIFT(x); x =
         * SBOX_MIX(x); x = SBOX_SHIFT(x); return SBOX_MIX(x);
         *
         * However, we can mix the bits in their original positions and then delay the
         * SBOX_SHIFT steps to be performed with one final rotation. This reduces the
         * number of required shift operations from 14 to 10.
         *
         * It is possible to reduce the number of shifts and AND's even further as shown
         * in the 64-bit version of skinny64_sbox() above. However on 32-bit platforms
         * this causes extra register spills which slows down the implementation more
         * than the improvement gained by reducing the number of bit operations.
         *
         * We can further reduce the number of NOT operations from 4 to 2 using the
         * technique from https://github.com/kste/skinny_avx to convert NOR-XOR
         * operations into AND-XOR operations by converting the S-box into its
         * NOT-inverse.
         */
        x_32u = ~x_32u;
        x_32u = (((x_32u >> 3) & (x_32u >> 2)) & 0x11111111) ^ x_32u;
        x_32u = (((x_32u << 1) & (x_32u << 2)) & 0x88888888) ^ x_32u;
        x_32u = (((x_32u << 1) & (x_32u << 2)) & 0x44444444) ^ x_32u;
        x_32u = (((x_32u >> 2) & (x_32u << 1)) & 0x22222222) ^ x_32u;
        x_32u = ~x_32u;
        return ((x_32u >> 1) & 0x77777777) | ((x_32u << 3) & 0x88888888);
    }

    /**
     * Sbox shift inv
     *
     * @param x_32u first 32 bits input
     * @return output of the Sbox shift inv
     */
    final private int invSbox32(int x_32u) {
        /*
         * Original version from the specification is equivalent to:
         *
         * #define SBOX_MIX(x) (((~((((x) >> 1) | (x)) >> 2)) & 0x11111111U) ^ (x))
         * #define SBOX_SHIFT_INV(x) ((((x) >> 1) & 0x77777777U) | (((x) << 3) &
         * 0x88888888U))
         *
         * x = SBOX_MIX(x); x = SBOX_SHIFT_INV(x); x = SBOX_MIX(x); x =
         * SBOX_SHIFT_INV(x); x = SBOX_MIX(x); x = SBOX_SHIFT_INV(x); return
         * SBOX_MIX(x);
         */
        x_32u = ~x_32u;
        x_32u = (((x_32u >> 3) & (x_32u >> 2)) & 0x11111111) ^ x_32u;
        x_32u = (((x_32u << 1) & (x_32u >> 2)) & 0x22222222) ^ x_32u;
        x_32u = (((x_32u << 1) & (x_32u << 2)) & 0x44444444) ^ x_32u;
        x_32u = (((x_32u << 1) & (x_32u << 2)) & 0x88888888) ^ x_32u;
        x_32u = ~x_32u;
        return ((x_32u << 1) & 0xEEEEEEEE) | ((x_32u >> 3) & 0x11111111);
    }

    @Override
    final public void encrypt(final byte[] output, final byte[] input, final Skinny64Key ks) {
        final Skinny64Key.Cells state = new Skinny64Key.Cells();
        Skinny64Key.Cells schedule = new Skinny64Key.Cells();
        int index;
        int temp_32u;

        if (ks == null) {
            throw new IllegalArgumentException("Encrypt: Skinny64Key must be valid");
        }
        if ( output.length != SKINNY64_BLOCK_SIZE ) {
            throw new IllegalArgumentException("Encrypt: Output buffer size not valid");
        }
        if ( input.length != SKINNY64_BLOCK_SIZE ) {
            throw new IllegalArgumentException("Encrypt: Inputbuffer size not valid");
        }


        /* Read the input buffer and convert little-endian to host-endian */
        state.setWord16(0, input, 0);
        state.setWord16(1, input, 2);
        state.setWord16(2, input, 4);
        state.setWord16(3, input, 6);

        /* Perform all encryption rounds */
        int idx = 0;
        for (index = SKINNY64_MAX_ROUNDS; index > 0; --index, ++idx) {
            schedule = ks.schedule[idx];
            /* Apply the S-box to all bytes in the state */
            state.set32(sbox32(state.get32(0)), 0);
            state.set32(sbox32(state.get32(1)), 1);
            /* Apply the subkey for this round */
            state.xor32(schedule.get32(), 0);
            state.xor16(0x20, 2);

            /* Shift the rows */
            state.set16(rotateRight(state.get16(1), 4), 1);
            state.set16(rotateRight(state.get16(2), 8), 2);
            state.set16(rotateRight(state.get16(3), 12), 3);

            /* Mix the columns */
            state.xor16(state.get16(2), 1);
            state.xor16(state.get16(0), 2);
            temp_32u = state.get16(3) ^ state.get16(2);
            state.set16(state.get16(2), 3);
            state.set16(state.get16(1), 2);
            state.set16(state.get16(0), 1);
            state.set16(temp_32u, 0);
        }

        writeWord16(output, 0, state.get16(0));
        writeWord16(output, 2, state.get16(1));
        writeWord16(output, 4, state.get16(2));
        writeWord16(output, 6, state.get16(3));

    }

    @Override
    final public void decrypt(final byte[] output, final byte[] input, final Skinny64Key ks) {
        final Skinny64Key.Cells state = new Skinny64Key.Cells();
        Skinny64Key.Cells schedule = new Skinny64Key.Cells();
        int index;
        int temp_32u;

        if (ks == null) {
            throw new IllegalArgumentException("Decrypt: Skinny64Key must be valid");
        }
        if ( output.length != SKINNY64_BLOCK_SIZE ) {
            throw new IllegalArgumentException("Decrypt: Output buffer size not valid");
        }
        if ( input.length != SKINNY64_BLOCK_SIZE ) {
            throw new IllegalArgumentException("Decrypt: Input buffer size not valid");
        }

        /* Read the input buffer and convert little-endian to host-endian */
        state.setWord16(0, input, 0);
        state.setWord16(1, input, 2);
        state.setWord16(2, input, 4);
        state.setWord16(3, input, 6);

        /* Perform all decryption rounds */
        int idx = SKINNY64_MAX_ROUNDS - 1;
        for (index = SKINNY64_MAX_ROUNDS; index > 0; --index, --idx) {
            schedule = ks.schedule[idx];
            /* Inverse mix of the columns */
            temp_32u = state.get16(3);
            state.set16(state.get16(0), 3);
            state.set16(state.get16(1), 0);
            state.set16(state.get16(2), 1);
            state.xor16(temp_32u, 3);
            state.set16(temp_32u ^ state.get16(0), 2);
            state.xor16(state.get16(2), 1);

            /* Inverse shift of the rows */
            state.set16(rotateRight(state.get16(1), 12), 1);
            state.set16(rotateRight(state.get16(2), 8), 2);
            state.set16(rotateRight(state.get16(3), 4), 3);

            /* Apply the subkey for this round */
            state.xor32(schedule.get32(), 0);
            state.xor16(0x20, 2);

            /* Apply the inverse of the S-box to all bytes in the state */
            state.set32(invSbox32(state.get32(0)), 0);
            state.set32(invSbox32(state.get32(1)), 1);
        }

        /* Convert host-endian back into little-endian in the output buffer */
        writeWord16(output, 0, state.get16(0));
        writeWord16(output, 2, state.get16(1));
        writeWord16(output, 4, state.get16(2));
        writeWord16(output, 6, state.get16(3));
    }
}