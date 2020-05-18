package fr.gouv.stopc.robert.server.crypto.callable;

import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.structure.impl.Crypto3DES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAES;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;

import java.util.concurrent.Callable;

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
     * Declared list of Crypto3DES instances threadSafe
     */
    private final CryptoStructureConcurrentArray<Crypto3DES> cryptoStructure3DESList;

    /**
     * Declared list of CryptoAES instances threadSafe
     */
    private final CryptoStructureConcurrentArray<CryptoAES> cryptoStructureAESList;

    /**
     * Country code (ex. : FR -> 0x33)
     */
    private byte countryCode;

    /**
     * Share instance of {@link #cryptoService} for multi thread for memory performance.
     * keysToEncrypt is corresponding to the key that would be encrypted by {@link #cryptoService}
     */
    public TupleCallable(CryptoService cryptoService,
                         CryptoStructureConcurrentArray<Crypto3DES> cryptoStructure3DESList,
                         CryptoStructureConcurrentArray<CryptoAES> cryptoStructureAESList,
                         byte[] idA, int epochId, byte countryCode) {
        this.cryptoService = cryptoService;
        this.idA = idA;
        this.epoch = epochId;
        this.countryCode = countryCode;
        this.cryptoStructure3DESList = cryptoStructure3DESList;
        this.cryptoStructureAESList = cryptoStructureAESList;
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

        final String threadName = Thread.currentThread().getName();

        final Crypto3DES c3DESs = this.cryptoStructure3DESList.getCryptoStructure(threadName);
        final CryptoAES cAESsc = this.cryptoStructureAESList.getCryptoStructure(threadName);

        return this.cryptoService.generateEphemeralTuple(
                c3DESs,
                cAESsc,
                this.epoch, this.idA, this.countryCode
        );
    }

}
