package fr.gouv.stopc.robert.server.crypto.service;

import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.structure.CryptoCipherStructureAbstract;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;

/**
 * Service centralizing crypto operations required to generate or validate crypto tokens
 */
public interface CryptoService {

    /**
     * Generating Tuple ECC EBID and epoch performing encryption with cryptoForEBID and cryptoForECC
     * EBID -> {@link #generateEBID(CryptoCipherStructureAbstract, int, byte[])}
     * ECC -> {@link #encryptCountryCode(CryptoCipherStructureAbstract, byte[], byte)}
     *
     * @param cryptoForEBID instance of cryptoForEBID initialize with the KS key
     * @param cryptoForECC  instance of cryptoForECC initialize with the KS key
     * @param epochId    epoch to concat - 24-bits
     * @param idA        permanent identifier to concat 40-bits
     * @param countryCode         country code 8-bits (ex.: FR => 0x21)
     * @return return encrypted EphemeralTuple fed with ECC EBDI and epoch
     * @throws RobertServerCryptoException
     */
    EphemeralTuple generateEphemeralTuple(
            CryptoCipherStructureAbstract cryptoForEBID,
            CryptoCipherStructureAbstract cryptoForECC,
            int epochId, byte[] idA, byte countryCode) throws RobertServerCryptoException;
 

    /**
     * @param cryptoForEBID instance of Crypto algo to encrypt EBID with, using KS (server key)
     * @param epochId          epoch in int
     * @param idA        permanent identifier to concat 40-bits
     * @return return encrypted epochId idA as encrypted EBID
     * @throws RobertServerCryptoException
     */
    byte[] generateEBID(CryptoCipherStructureAbstract cryptoForEBID, int epochId, byte[] idA) throws RobertServerCryptoException;

    /**
     * Decrypt an EBID
     * @param cryptoForEBID
     * @param ebid
     * @return
     * @throws RobertServerCryptoException
     */
    byte[] decryptEBID(CryptoCipherStructureAbstract cryptoForEBID, byte[] ebid) throws RobertServerCryptoException;

    /**
     * @param cryptoForECC instance of Crypto algo to encrypt ECC with, using KG (federation key)
     * @param ebid      Result of encryption of IDa and i as EBID - 64-bits
     * @param countryCode        country code - 8-bits
     * @return return encrypted countryCode and EBID as ECC with MSB method specified in ROBert documentation.
     * @throws RobertServerCryptoException
     */
    byte[] encryptCountryCode(CryptoCipherStructureAbstract cryptoForECC, byte[] ebid, byte countryCode) throws RobertServerCryptoException;

    /**
     * Decrypt an encrypted country code
     * @param cryptoForECC
     * @param ebid
     * @param encryptedCountryCode
     * @return
     * @throws RobertServerCryptoException
     */
     byte[] decryptCountryCode(CryptoCipherStructureAbstract cryptoForECC, byte[] ebid, byte encryptedCountryCode) throws RobertServerCryptoException;

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
                                 final DigestSaltEnum salt) throws RobertServerCryptoException;


    byte[] performAESOperation(int mode, byte[] data, byte[] key);

}
