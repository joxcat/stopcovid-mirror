package fr.gouv.stopc.robert.server.crypto.structure;

import java.security.InvalidKeyException;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public abstract class CryptoMacStructureAbstract implements ICryptoStructure, IMacStructure {

    /**
     * @param payloadToEncrypt payload to encrypt
     * @return the arguments[0] encrypted with TripleDES algo
     * @throws RobertServerCryptoException 
     */
    @Override
    public byte[] encrypt(byte[] payloadToEncrypt) throws RobertServerCryptoException {
        try {
            this.getMac().init(this.getSecretKey());

            return this.getMac().doFinal(payloadToEncrypt);
        } catch (InvalidKeyException | IllegalStateException e) {
            log.error(e.getMessage(), e);
            throw new RobertServerCryptoException(e.getMessage());
        }
    }

}
