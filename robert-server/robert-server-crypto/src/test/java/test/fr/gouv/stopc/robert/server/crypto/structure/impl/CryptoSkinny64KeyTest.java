package test.fr.gouv.stopc.robert.server.crypto.structure.impl;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.doThrow;

import java.util.Arrays;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoSkinny64;

@ExtendWith(SpringExtension.class)
public class CryptoSkinny64KeyTest {

	/**
	 * 192-bit key
	 */
	private final byte[] key1 = {
			(byte) 0xed, (byte) 0x00, (byte) 0xc8, (byte) 0x5b, (byte) 0x12, (byte) 0x0d, (byte) 0x68, (byte) 0x61,
			(byte) 0x87, (byte) 0x53, (byte) 0xe2, (byte) 0x4b, (byte) 0xfd, (byte) 0x90, (byte) 0x8f, (byte) 0x60,
			(byte) 0xb2, (byte) 0xdb, (byte) 0xb4, (byte) 0x1b, (byte) 0x42, (byte) 0x2d, (byte) 0xfc, (byte) 0xd0};

	/**
	 * 192-bit key
	 */
	private final byte[] key2 = {
			(byte) 0xc8, (byte) 0x5b, (byte) 0x12, (byte) 0x0d, (byte) 0x68, (byte) 0xe2, (byte) 0x4b, (byte) 0xfd,
			(byte) 0x90, (byte) 0x61, (byte) 0x87, (byte) 0x53, (byte) 0x8f, (byte) 0x60, (byte) 0xb2, (byte) 0xdb,
			(byte) 0xb4, (byte) 0x1b, (byte) 0x42, (byte) 0x2d, (byte) 0xfc, (byte) 0xd0, (byte) 0xed, (byte) 0x00};

	/**
	 * Payload to encrypt
	 */
	private final byte[] plainText = {
			(byte) 0x53, (byte) 0x0c, (byte) 0x61, (byte) 0xd3,
			(byte) 0x5e, (byte) 0x86, (byte) 0x63, (byte) 0xc3};

	/**
	 * Pre-processed encryption result of plainText with key1
	 */
	private final byte[] cipherTextWithKey1 = {
			(byte) 0xdd, (byte) 0x2c, (byte) 0xf1, (byte) 0xa8,
			(byte) 0xf3, (byte) 0x30, (byte) 0x30, (byte) 0x3c};

	/**
	 * Pre-processed encryption result of plainText with key2
	 */
	private final byte[] cipherTextWithKey2 = {
			(byte) 0x4b, (byte) 0xdc, (byte) 0xaf, (byte) 0xff,
			(byte) 0x46, (byte) 0x7a, (byte) 0x80, (byte) 0x29};

	@Test
	public void testDecryptKey1Succeeds() throws RobertServerCryptoException {
		// GIVEN

		CryptoSkinny64 crypto = new CryptoSkinny64(key1);

		// WHEN
		byte[] result = crypto.decrypt(cipherTextWithKey1);

		// THEN
		assertTrue(Arrays.equals(plainText, result));
	}

	@Test
	public void testDecryptKey2Succeeds() throws RobertServerCryptoException {
		// GIVEN
		CryptoSkinny64 crypto = new CryptoSkinny64(key2);

		// WHEN
		byte[] result = crypto.decrypt(cipherTextWithKey2);

		// THEN
		assertTrue(Arrays.equals(plainText, result));
	}

	@Test
	public void testEncryptKey1Succeeds() throws RobertServerCryptoException {
		// GIVEN
		CryptoSkinny64 crypto = new CryptoSkinny64(key1);

		// WHEN
		byte[] result = crypto.encrypt(plainText);

		// THEN
		assertTrue(Arrays.equals(cipherTextWithKey1, result));
	}

	@Test
	public void testEncryptKey2Succeeds() throws RobertServerCryptoException {
		// GIVEN
		CryptoSkinny64 crypto = new CryptoSkinny64(key2);

		// WHEN
		byte[] result = crypto.encrypt(plainText);

		// THEN
		assertTrue(Arrays.equals(cipherTextWithKey2, result));
	}

	@Test
	public void testEncryptDecryptBijectionSucceeds() throws RobertServerCryptoException {
		CryptoSkinny64 crypto = new CryptoSkinny64(key1);
		byte[] cipher = crypto.encrypt(plainText);
		byte[] result = crypto.decrypt(cipher);

		assertTrue(Arrays.equals(result, plainText));
	}

	@Test
	public void testEncryptNullPlainTextFails() {
		CryptoSkinny64 crypto = new CryptoSkinny64(key1);

		IllegalArgumentException thrown = assertThrows(
				IllegalArgumentException.class,
				() -> crypto.encrypt(null),
				"Expected Skinny64 encrypt to throw, but it didn't"
		);

		assertNotEquals(null, thrown);
	}

	@Test
	public void testDecryptNullPlainTextFails() {
		CryptoSkinny64 crypto = new CryptoSkinny64(key1);

		IllegalArgumentException thrown = assertThrows(
				IllegalArgumentException.class,
				() -> crypto.decrypt(null),
				"Expected Skinny64 decrypt to throw, but it didn't"
		);

		assertNotEquals(null, thrown);
	}

	@Test
	public void testCipherInitNullKeyFails() {
		IllegalArgumentException thrown = assertThrows(
				IllegalArgumentException.class,
				() -> {
					CryptoSkinny64 crypto = new CryptoSkinny64(null);
				},
				"Expected Skinny64 init to throw, but it didn't"
		);

		assertNotEquals(null, thrown);
	}

	@Test
	public void testCipherInitImproperKeySizeFails() {
		IllegalArgumentException thrown = assertThrows(
				IllegalArgumentException.class,
				() -> {
					CryptoSkinny64 crypto = new CryptoSkinny64(Arrays.copyOf(key1, key1.length - 1));
				},
				"Expected Skinny64 init to throw, but it didn't"
		);

		assertNotEquals(null, thrown);
	}

}
