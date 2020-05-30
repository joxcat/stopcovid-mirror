package fr.gouv.stopc.robert.server.crypto.service.impl;

import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.structure.CryptoCipherStructureAbstract;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class CryptoServiceImpl implements CryptoService {

    private static byte[] iv = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    @Override
    public EphemeralTuple generateEphemeralTuple(
            final CryptoCipherStructureAbstract cryptoForEBID,
            final CryptoCipherStructureAbstract cryptoForECC,
            final int epochId,
            final byte[] idA,
            final byte countryCode) throws RobertServerCryptoException {

        byte[] ebid =  this.generateEBID(cryptoForEBID, epochId, idA);

        // generate ECC 8-bits MSB method
        byte[] encryptedCountryCode = this.encryptCountryCode(cryptoForECC, ebid, countryCode);

        return  new EphemeralTuple(epochId, ebid, encryptedCountryCode);
    }

    @Override
    public byte[] generateEBID(final CryptoCipherStructureAbstract cryptoForEBID, final int epochId, final byte[] idA) throws RobertServerCryptoException {
        byte[] epoch =  ByteUtils.intToBytes(epochId);
        byte[] truncatedEpoch = new byte[] { epoch[epoch.length - 3], epoch[epoch.length - 2], epoch[epoch.length - 1] };
        this.assertLength("IDa", 40, idA);

        // concat epoch (truncate to 24 bits) and IDa (40 bits)
        byte[] bytesToEncrypt = ByteUtils.addAll(truncatedEpoch, idA);

        return cryptoForEBID.encrypt(bytesToEncrypt);
    }

    @Override
    public byte[] decryptEBID(final CryptoCipherStructureAbstract cryptoForEBID, final byte[] ebid) throws RobertServerCryptoException {

        this.assertLength("ebid", 64, ebid);
        return cryptoForEBID.decrypt(ebid);
    }

    @Override
    public byte[] encryptCountryCode(final CryptoCipherStructureAbstract cryptoForECC, final byte[] ebid, final byte countryCode) throws RobertServerCryptoException {
        this.assertLength("ebid", 64, ebid);
        this.assertLength("country code", 8, countryCode);

        // Pad to 128-bits
        byte[] payloadToEncrypt = Arrays.copyOf(ebid, 128 / 8);

        // AES Encryption of the payload to encrypt
        byte[] encryptedPayload = cryptoForECC.encrypt(payloadToEncrypt);

        // Truncate to 8 bits
        // Equivalent to MSB in ROBert spec
        byte truncatedEncryptedPayload = encryptedPayload[0];

        return new byte[] { (byte) (truncatedEncryptedPayload ^ countryCode) };
    }

    @Override
    public byte[] decryptCountryCode(final CryptoCipherStructureAbstract cryptoForECC, final byte[] ebid, final byte encryptedCountryCode) throws RobertServerCryptoException {
        this.assertLength("ebid", 64, ebid);
        this.assertLength("encrypted country code", 8, encryptedCountryCode);

        // decrypt method is same as encrypt but take in third parameter ecc
        return this.encryptCountryCode(cryptoForECC, ebid, encryptedCountryCode);
    }

    @Override
    public byte[] generateMACHello(final CryptoHMACSHA256 cryptoHMACSHA256S, final byte[] hello) throws RobertServerCryptoException {
        this.assertLength("hello message", 128, hello);

        // get the first 88-bits of hello message. ==> (ECC | EBID | Time) also called M_a,i in spec
        final byte[] mai = Arrays.copyOfRange(hello, 0, 11);
        this.assertLength("(ECC | EBID | Time) or M_a,i", 88, mai);

        byte[] generatedMAC = this.generateHMAC(cryptoHMACSHA256S, mai, DigestSaltEnum.HELLO);

        // truncate the result from 0 to 40-bits
        generatedMAC = Arrays.copyOfRange(generatedMAC, 0, 5);

        return generatedMAC;
    }

    /**
     *
     * @param cryptoHMACSHA256S CryptoStructure uses to encrypt HMAC-SHA256
     * @param argument data to be processed
     * @param salt prefixes the data to be processed
     * @return the HMAC-SHA256 encrypted, truncated value.
     */
    private byte[] generateHMAC(final CryptoHMACSHA256 cryptoHMACSHA256S,
            final byte[] argument,
            final DigestSaltEnum salt) throws RobertServerCryptoException {

        final byte[] prefix = new byte[] { salt.getValue() };

        // HMAC-SHA256 processing
        return cryptoHMACSHA256S.encrypt(ByteUtils.addAll(prefix, argument));
    }

    @Override
    public boolean macHelloValidation(final CryptoHMACSHA256 cryptoHMACSHA256S, final byte[] hello) throws RobertServerCryptoException {
        this.assertLength("hello message", 128, hello);

        // Generate HMAC-SHA256 from hello message in parameter
        final byte[] generatedMAC = this.generateMACHello(cryptoHMACSHA256S, hello);

        // get last 40-bits of hello to get MAC
        final byte[] mac = Arrays.copyOfRange(hello, 11, 16);

        return Arrays.equals(generatedMAC, mac);
    }

    @Override
    public boolean macESRValidation(final CryptoHMACSHA256 cryptoHMACSHA256S,
            final byte[] toBeEncrypted,
            final byte[] macToVerify) throws RobertServerCryptoException {
        return macValidationForType(cryptoHMACSHA256S, toBeEncrypted, macToVerify, DigestSaltEnum.STATUS);
    }

    @Override
    public boolean macValidationForType(final CryptoHMACSHA256 cryptoHMACSHA256S,
            final byte[] toBeEncrypted,
            final byte[] macToVerify,
            final DigestSaltEnum salt) throws RobertServerCryptoException {
        this.assertLength("concat(EBID | Time)", 64+32+32, toBeEncrypted);
        byte[] generatedMAC = this.generateHMAC(cryptoHMACSHA256S, toBeEncrypted, salt);
        return Arrays.equals(macToVerify, generatedMAC);
    }

    /**
     * Method asserting the size in bits of an array of bytes
     * @param bytes data to check
     * @param size size in bits (ex 24-bits -> 3-bytes)
     * @param propertyName property name to return in message
     * @throws RobertServerCryptoException argument should be at the right size
     */
    protected void assertLength(String propertyName, int size, byte... bytes) throws RobertServerCryptoException {
        if (bytes == null || bytes.length != size / 8) {
            String message = String.format("%s should be %s-bits sized but is %s-bits sized", propertyName, size, bytes == null ? 0 : bytes.length * 8);
            log.error(message);
            throw new RobertServerCryptoException(message);
        }
    }

    @Override
    public byte[] performAESOperation(int mode, byte[] data, byte[] key) {

        try {
            IvParameterSpec ivspec = new IvParameterSpec(iv);
            SecretKeySpec skeySpec = new SecretKeySpec(key, "AES");

            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5PADDING");
            cipher.init(mode, skeySpec, ivspec);

            return cipher.doFinal(data);

        } catch (NoSuchPaddingException |  NoSuchAlgorithmException |
                InvalidKeyException |
                IllegalBlockSizeException | BadPaddingException | InvalidAlgorithmParameterException e) {

            log.error("Unable to decrypt with AES cryptographic algorithm due to {}", e);
        }
        return null;
    }
}
