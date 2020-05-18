package fr.gouv.stopc.robert.server.crypto.service;

import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robert.server.crypto.structure.impl.Crypto3DES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;

/**
 * Service centralizing crypto operations required to generate or validate crypto tokens
 */
public interface CryptoService {

    /**
     * Generating Tuple ECC EBID and epoch performing encryption with crypto3DES and cryptoAES
     * EBID -> {@link #generateEBID(Crypto3DES, int, byte[])}
     * ECC -> {@link #encryptCountryCode(CryptoAES, byte[], byte)}
     *
     * @param crypto3DES instance of crypto3DES initialize with the KS key
     * @param cryptoAES  instance of cryptoAES initialize with the KS key
     * @param epochId    epoch to concat - 24-bits
     * @param idA        permanent identifier to concat 40-bits
     * @param countryCode         country code 8-bits (ex.: FR => 0x33)
     * @return return encrypted EphemeralTuple fed with ECC EBDI and epoch
     * @throws RobertServerCryptoException
     */
    EphemeralTuple generateEphemeralTuple(
            Crypto3DES crypto3DES,
            CryptoAES cryptoAES,
            int epochId, byte[] idA, byte countryCode) throws RobertServerCryptoException;

    /**
     * @param crypto3DES instance of TripleDES initialize with the KS key
     * @param epochId          epoch in int
     * @param idA        permanent identifier to concat 40-bits
     * @return return encrypted epochId idA as EBID with TripleDES algorithm
     * @throws RobertServerCryptoException
     */
    byte[] generateEBID(Crypto3DES crypto3DES, int epochId, byte[] idA) throws RobertServerCryptoException;

    /**
     * Decrypt an EBID
     * @param crypto3DES
     * @param ebid
     * @return
     * @throws RobertServerCryptoException
     */
    byte[] decryptEBID(Crypto3DES crypto3DES, byte[] ebid) throws RobertServerCryptoException;

    /**
     * @param cryptoAES instance of TripleDES initialize with the KS key
     * @param ebid      Result of encryption of IDa and i as EBID - 64-bits
     * @param countryCode        country code - 8-bits
     * @return return encrypted countryCode and EBID as ECC with MSB method specified in ROBert documentation.
     * @throws RobertServerCryptoException
     */
    byte[] encryptCountryCode(CryptoAES cryptoAES, byte[] ebid, byte countryCode) throws RobertServerCryptoException;

    /**
     * Decrypt an encrypted country code
     * @param cryptoAES
     * @param ebid
     * @param encryptedCountryCode
     * @return
     * @throws RobertServerCryptoException
     */
     byte[] decryptCountryCode(CryptoAES cryptoAES, byte[] ebid, byte encryptedCountryCode) throws RobertServerCryptoException;

    /**
     *
     * @param cryptoHMACSHA256S CryptoStructure used to encrypt HMAC-SHA256
     * @param hello hello message 128-bits (ECC | EBID | Time | MAC)
     * @return the HMACSH256 encrypted, truncate value.
     * @throws RobertServerCryptoException
     */
    byte[] generateMACHello(CryptoHMACSHA256 cryptoHMACSHA256S, byte[] hello) throws RobertServerCryptoException;

    /**
     * Validate the MAC in hello parameter
     * @param hello 128-bits long
     * @return
     * @throws RobertServerCryptoException
     */
    boolean macHelloValidation(CryptoHMACSHA256 cryptoHMACSHA256S, byte[] hello) throws RobertServerCryptoException;

    /**
     * @param cryptoHMACSHA256S CryptoStructure used to encrypt HMAC-SHA256
     * @param toBeEncrypted is concat(EBID | Time) respectively 32-bits + 64-bits
     * @param macToVerify the mac to compare the encrypted payload against
     * @return
     * @throws RobertServerCryptoException
     */
    boolean macESRValidation(CryptoHMACSHA256 cryptoHMACSHA256S,
                             byte[] toBeEncrypted,
                             byte[] macToVerify) throws RobertServerCryptoException;

    /**
     *
     * @param cryptoHMACSHA256S
     * @param toBeEncrypted Payload to be encrypted (with the additional prefixByte parameter)
     * @param macToVerify The MAC to be verified
     * @param salt The type of the request (0x02=ESR, 0x03=Unregister...)
     * @return Whether the MAC is valid for the provided prefixByte
     * @throws RobertServerCryptoException
     */
    boolean macValidationForType(final CryptoHMACSHA256 cryptoHMACSHA256S,
                                 final byte[] toBeEncrypted,
                                 final byte[] macToVerify,
                                 final DigestSaltEnum salt) throws Exception;
}
