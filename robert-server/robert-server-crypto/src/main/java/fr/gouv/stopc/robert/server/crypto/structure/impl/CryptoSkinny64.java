package fr.gouv.stopc.robert.server.crypto.structure.impl;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.skinny64.SkinnyCipher192;
import fr.gouv.stopc.robert.server.crypto.skinny64.Skinny64Key;
import fr.gouv.stopc.robert.server.crypto.skinny64.impl.SkinnyCipher192Impl;
import fr.gouv.stopc.robert.server.crypto.structure.CryptoCipherStructureAbstract;
import lombok.extern.slf4j.Slf4j;

import java.security.spec.AlgorithmParameterSpec;
import java.util.Objects;

@Slf4j
public class CryptoSkinny64 extends CryptoCipherStructureAbstract {

	private static final String SKINNY_ENCRYPTION_KEY_SCHEME = "SKINNY64";
	private static final int KEY_SIZE_64 = 8;

	private final Skinny64Key ks;
	private final SkinnyCipher192 cipher;

	/**
	 * @param key key to use for cipher
	 */
	public CryptoSkinny64(byte[] key) {
		Skinny64Key ks = null;
		SkinnyCipher192 cipher = null;

		if (Objects.isNull(key)) {
			throw new IllegalArgumentException("Key may not be null");
		}

		try {
			ks = new Skinny64Key();
			cipher = new SkinnyCipher192Impl();
			cipher.setKey(ks, key);
		} catch (IllegalArgumentException e) {
			log.error(String.format("Algorithm %s invalid Skinny64Key", SKINNY_ENCRYPTION_KEY_SCHEME));
			throw e;
		} finally {
			this.ks = ks;
			this.cipher = cipher;
		}
	}

	@Override
	public byte[] decrypt(byte[] cipherText) throws RobertServerCryptoException {
		byte[] output = new byte[KEY_SIZE_64];

		if (Objects.isNull(cipherText)) {
			throw new IllegalArgumentException("Cipher text may not be null");
		}

		try {
			cipher.decrypt(output, cipherText, ks);
		} catch (Exception e) {
            throw new RobertServerCryptoException(e.getMessage());
        }
		return output;
	}

	@Override
	public byte[] encrypt(byte[] plainText) throws RobertServerCryptoException {
		byte[] output = new byte[KEY_SIZE_64];

		if (Objects.isNull(plainText)) {
			throw new IllegalArgumentException("Plain text may not be null");
		}

		try {
			cipher.encrypt(output, plainText, ks);
		} catch (Exception e) {
            throw new RobertServerCryptoException(e.getMessage());
        }
		return output;
	}

	@Override
	public javax.crypto.Cipher getCipher() {
		return null;
	}

	@Override
	public SecretKey getSecretKey() {
		return null;
	}

	@Override
	public AlgorithmParameterSpec getAlgorithmParameterSpec() {
		return null;
	}

    @Override
    public Cipher getDecryptCypher() {
        return null;
    }
}
