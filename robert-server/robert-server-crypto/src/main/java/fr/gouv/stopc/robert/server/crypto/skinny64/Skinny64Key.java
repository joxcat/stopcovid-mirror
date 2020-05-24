/* 
* Copyright (C) Inria, 2020 
*/
package fr.gouv.stopc.robert.server.crypto.skinny64;

/**
 * Key schedule for Skinny64 block ciphers.
 *
 */
public final class Skinny64Key {

    /* All words of the key schedule */
    public Cells[] schedule = new Cells[SkinnyCipher192.SKINNY64_MAX_ROUNDS];

    /*
     * Constructor
     *
     */
    public Skinny64Key() {
        for (int idx = 0; idx < SkinnyCipher192.SKINNY64_MAX_ROUNDS; idx++) {
            this.schedule[idx] = new Cells();
        }
    }

    /*
     * Clear attributes
     *
     */
    public void clear() {
        for (int idx = 0; idx < SkinnyCipher192.SKINNY64_MAX_ROUNDS; idx++) {
            this.schedule[idx].llrow = 0;
        }
    }

    /*
     * Describes a 32bit 2x4 array of cells or 64-bit 4x4 array of cells.
     *
     */
    public static class Cells {

        /* Cells are saved in a long (64 bits = 8 bytes) */
        public long llrow;

        /**
         * Set 16 bits from buffer ptr[offset] to Cells (saved in a long : 8 bytes)
         *
         * @param index  index of 16 bits portion to be written in Cells (0 = first 16
         *               bits, 1 = 16 bits following, up to 4)
         * @param ptr    buffer of bytes
         * @param offset offset indexing the buffer of bytes
         */
        public void setWord16(int index, byte[] ptr, int offset) {
            int value = (ptr[offset] & (0x000000FF)) | ((ptr[offset + 1] << 8) & (0x0000FF00));
            this.set16(value, index);
        }

        /**
         * Get a byte from Cells
         *
         * @param index of byte extracted from Cells saved in a long (8 bytes)
         * @return byte extracted
         */
        public byte getByte(int index) {
            byte res;
            res = (byte) ((this.llrow >>> (8 * index)) & 0xFF);
            return res;
        }

        /**
         * Set a byte on Cells saved in a long
         *
         * @param value Byte value
         * @param index index byte on Cells
         */
        public void setByte(byte value, int index) {
            this.llrow = this.llrow | (this.llrow << (8 * index));
        }

        /**
         * Get 16 bits (2 bytes) from Cells
         *
         * @param index of byte extracted from Cells saved in a long (8 bytes)
         * @return First 16 bits are relevant
         */
        public int get16(int index) {
            int res;
            res = (int) ((this.llrow >>> (16 * index)) & 0xFFFF);
            return res;
        }

        /**
         * Apply a bit XOR filter on 16 bits of Cells
         *
         * @param filter bits filter
         * @param index  index of 16 bits extracted from Cells saved in a long (8 bytes)
         *               to be filtered (0 to 3)
         */
        public void xor16(int filter, int index) {
            int v;
            v = get16(index);
            v ^= filter;
            set16(v, index);
        }

        /*
         * Set a 16 bits on Cells saved in a long
         *
         * @param value Only first 16 bits value are relevant
         *
         * @param index index byte on Cells (0 to 3)
         */
        public void set16(int value, int index) {
            long filter = 0;
            long lvalue = (long) value;

            if (index == 0) {
                filter = 0xFFFFFFFFFFFF0000L;
            } else if (index == 1) {
                filter = 0xFFFFFFFF0000FFFFL;
            } else if (index == 2) {
                filter = 0xFFFF0000FFFFFFFFL;
            } else if (index == 3) {
                filter = 0x0000FFFFFFFFFFFFL;
            }
            this.llrow = (this.llrow & filter) | ((lvalue << (16 * index) & ~filter));
        }

        /**
         * Get 32 bits (4 bytes) from Cells
         *
         * @param index of byte extracted from Cells saved in a long (8 bytes)
         * @return First 32 bits are relevant
         */
        public int get32(int index) {
            long res;
            res = (this.llrow >>> (32 * index)) & 0xFFFFFFFF;
            return (int) res;
        }

        /**
         * Get the first 32 bits (4 bytes) from Cells. Equivalent to get32(0)
         *
         * @return First 32 bits are relevant
         */
        public int get32() {
            int res;
            res = (int) (this.llrow & 0xFFFFFFFF);
            return res;
        }

        /**
         * Apply a bit XOR filter on 32 bits of Cells
         *
         * @param filter bits filter
         * @param index  index of 32 bits extracted from Cells saved in a long (8 bytes)
         *               to be filtered (0 or 1)
         */
        public void xor32(int filter, int index) {
            int v;
            v = get32(index);
            v ^= filter;
            set32(v, index);
        }

        /*
         * Set a 32 bits on Cells saved in a long
         *
         * @param value Only first 32 bits value are relevant
         * @param index index byte on Cells (0 to 1)
         */
        public void set32(int value, int index) {

            long filter = 0;
            long lvalue = (long) value;

            if (index == 0) {
                filter = 0xFFFFFFFF00000000L;
            } else if (index == 1) {
                filter = 0x00000000FFFFFFFFL;
            }
            this.llrow = (this.llrow & filter) | ((lvalue << (32 * index) & ~filter));
        }

        /*
         * Set first 32 bits Cells saved in a long. Equivalent to set32(value, 0)
         *
         * @param value Only first 32 bits value are relevant
         */
        public void set32(int value) {
            this.set32(value, 0);
        }

    }

}
