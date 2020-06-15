package fr.gouv.stopc.robert.server.crypto.callable;

import java.util.concurrent.Callable;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.structure.CryptoCipherStructureAbstract;

/**
 * Callable to create encrypted key using #CryptoService
 */
public class TupleCallable implements Callable<EphemeralTuple> {

    /**
     * Service instance to use in callable.
     * Should access to cryptographic method.
     * Share instance of Crypto service for multi thread for memory performance.
     */
    private final CryptoService cryptoService;

    /**
     * Permanent and anonymous identifier of user UA, stored by the server
     */
    private final byte[] idA;

    /**
     * Epoch number as integer
     */
    private final int epoch;

    /**
     * Declared list of Crypto instances to process EBID threadSafe
     */
//    private final CryptoStructureConcurrentArray<CryptoCipherStructureAbstract> cryptoStructureForEBIDList;

    /**
     * Declared list of Crypto instances to process ECC threadSafe
     */
//    private final CryptoStructureConcurrentArray<CryptoCipherStructureAbstract> cryptoStructureForECCList;

    /**
     * Country code (ex. : FR -> 0x21)
     */
    private byte countryCode;

    private CryptoCipherStructureAbstract cryptoStructureForEBID;

    private CryptoCipherStructureAbstract cryptoStructureForECC;

    /**
     * Share instance of {@link #cryptoService} for multi thread for memory performance.
     * keysToEncrypt is corresponding to the key that would be encrypted by {@link #cryptoService}
     */
//    public TupleCallable(CryptoService cryptoService,
//            CryptoStructureConcurrentArray<CryptoCipherStructureAbstract> cryptoStructureForEBIDList,
//            CryptoStructureConcurrentArray<CryptoCipherStructureAbstract> cryptoStructureForECCList,
//            byte[] idA, int epochId, byte countryCode) {
//        this.cryptoService = cryptoService;
//        this.idA = idA;
//        this.epoch = epochId;
//        this.countryCode = countryCode;
//        this.cryptoStructureForEBIDList = cryptoStructureForEBIDList;
//        this.cryptoStructureForECCList = cryptoStructureForECCList;
//    }

    public TupleCallable(CryptoService cryptoService,
            CryptoCipherStructureAbstract cryptoStructureForEBID,
            CryptoCipherStructureAbstract cryptoStructureForECC,
            byte[] idA, int epochId, byte countryCode) {
        this.cryptoService = cryptoService;
        this.idA = idA;
        this.epoch = epochId;
        this.countryCode = countryCode;
        this.cryptoStructureForEBID = cryptoStructureForEBID;
        this.cryptoStructureForECC = cryptoStructureForECC;
    }
    /**
     * Generate ephemeralTuple.
     * This callable is using a thread safe array service of CryptoStructureList.
     * @return the encrypted keys made by {@link #cryptoService} applied on {@link #idA}
     * @throws RobertServerCryptoException
     * @throws IllegalArgumentException
     */
    @Override
    public EphemeralTuple call() throws RobertServerCryptoException {

//        final String threadName = Thread.currentThread().getName();

//        final CryptoCipherStructureAbstract cryptoStructureForEBID = this.cryptoStructureForEBIDList.getCryptoStructure(threadName);
//        final CryptoCipherStructureAbstract cryptoStructureForECC = this.cryptoStructureForECCList.getCryptoStructure(threadName);

        return this.cryptoService.generateEphemeralTuple(
                cryptoStructureForEBID,
                cryptoStructureForECC,
                this.epoch, this.idA, this.countryCode
                );
    }

}
