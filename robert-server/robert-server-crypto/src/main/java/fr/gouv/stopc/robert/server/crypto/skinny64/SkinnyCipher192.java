/* 
* Copyright (C) Inria, 2020 
*/
package fr.gouv.stopc.robert.server.crypto.skinny64;


/**
 * Skinny block cipher 'simplified' translates in Java a part of the reference
 * code Skinny-C
 *
 * @see https://github.com/rweather/skinny-c
 *
 */
public interface SkinnyCipher192 {

    int SKINNY64_BLOCK_SIZE = 8;
    int SKINNY64_KEY_SIZE = 3 * SKINNY64_BLOCK_SIZE;
    int SKINNY64_MAX_ROUNDS = 40;

    /**
     * Set a Skinny64 block ciphers
     *
     * @param ks       Skinny64 block ciphers
     * @param key      Key of cryption of size SKINNY64_KEY_SIZE bytes
     * @throws IllegalArgumentException
     */
    void setKey(final Skinny64Key ks, final byte[] key);

    /**
     * Clear a Skinny64 block ciphers
     *
     * @param ks       Skinny64 block ciphers
     * @throws IllegalArgumentException
     */
    void clearKey(final Skinny64Key ks);


    /**
     * Encrypt a input plain text
     *
     * @param output The output buffer (SKINNY64_BLOCK_SIZE bytes) for the message crypted
     * @param input  The input buffer (SKINNY64_BLOCK_SIZE bytes) for the message to be crypted
     * @param ks     Skinny64 block ciphers
     * @throws IllegalArgumentException
     */
    void encrypt(final byte [] output, final byte [] input, final Skinny64Key ks);

    /**
     * Decrypt an input cypher text
     *
     * @param output The output buffer (SKINNY64_BLOCK_SIZE bytes) for the message decrypted
     * @param input  The output buffer (SKINNY64_BLOCK_SIZE bytes) for the message to be decrypted
     * @param ks     Skinny64 block ciphers
     * @throws IllegalArgumentException
     */
    void decrypt(final byte [] output, final byte [] input, final Skinny64Key ks);
}

