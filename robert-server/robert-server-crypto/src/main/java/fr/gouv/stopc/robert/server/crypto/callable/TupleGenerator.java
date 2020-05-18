package fr.gouv.stopc.robert.server.crypto.callable;

import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.structure.impl.Crypto3DES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAES;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.service.impl.CryptoServiceImpl;
import lombok.extern.slf4j.Slf4j;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.*;

@Slf4j
public class TupleGenerator {

    private final int numberOfThreads;

    private final byte[] serverKey;

    private final byte[] federationKey;

    private final CryptoStructureConcurrentArray<Crypto3DES> cryptoStructure3DESList;
    private final CryptoStructureConcurrentArray<CryptoAES> cryptoStructureAESList;

    private ThreadPoolExecutor threadExecutor;
    private final CryptoService cryptoService;

    public TupleGenerator(byte[] serverKey, byte[] federationKey, int numberOfThreads) {
        this.numberOfThreads = numberOfThreads;
        this.serverKey = serverKey;
        this.federationKey = federationKey;

        // Create instance of CryptoServiceImpl that will be used in threads
        this.cryptoService = new CryptoServiceImpl();

        // Create ThreadPoolExecutor
        this.threadExecutor = (ThreadPoolExecutor) Executors.newFixedThreadPool(1);

        // Generate [ #numberOfThreads * tripleDES ]
        final Crypto3DES[] availableCrypto3DES = new Crypto3DES[this.numberOfThreads];
        final CryptoAES[] availableCryptoAES = new CryptoAES[this.numberOfThreads];

        for (int i = 0; i < this.numberOfThreads; i++) {
            final Crypto3DES crypto3DES = new Crypto3DES(this.serverKey);
            final CryptoAES cryptoAES = new CryptoAES(this.federationKey);

            availableCrypto3DES[i] = crypto3DES;
            availableCryptoAES[i] = cryptoAES;
        }
        // assign generated TripleDES to the TripleConcurrentList
        this.cryptoStructure3DESList = new CryptoStructureConcurrentArray<>(availableCrypto3DES);
        this.cryptoStructureAESList = new CryptoStructureConcurrentArray<>(availableCryptoAES);
    }

    public Collection<EphemeralTuple> exec(final byte[] idA,
                                           final int currentEpoch,
                                           final int numEpoch,
                                           final byte countryCode) throws RobertServerCryptoException {
        // Create list of callable executable
        Collection<Callable<EphemeralTuple>> callableList = new ArrayList<>();
        for (int i = 0; i < numEpoch; i++) {
            final int epoch = (currentEpoch + i);

            callableList.add(
                    new TupleCallable(
                            this.cryptoService,
                            this.cryptoStructure3DESList,
                            this.cryptoStructureAESList,
                            idA, epoch, countryCode
                    )
            );
        }

        // Store information related to execution.
        Collection<EphemeralTuple> ephemeralTuples = new ArrayList<>();
        try {
            // Execute previous callable list
            final List<Future<EphemeralTuple>> futures = this.threadExecutor.invokeAll(callableList);


            for (Future<EphemeralTuple> future : futures) {
                ephemeralTuples.add(future.get());
            }
        } catch (InterruptedException e) {
            log.warn("Interrupting thread!", e);
            Thread.currentThread().interrupt();
        } catch (ExecutionException e) {
            log.error(e.getMessage());
            throw new RobertServerCryptoException(e.getMessage(), e);
        }
        return ephemeralTuples;
    }

    public void stop() {
        this.threadExecutor.shutdown();
    }
}
