package fr.gouv.stopc.robert.server.crypto.callable;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.service.impl.CryptoServiceImpl;
import fr.gouv.stopc.robert.server.crypto.structure.CryptoCipherStructureAbstract;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoSkinny64;
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

    private final CryptoStructureConcurrentArray<CryptoCipherStructureAbstract> cryptoStructureForEBIDList;
    private final CryptoStructureConcurrentArray<CryptoCipherStructureAbstract> cryptoStructureForECCList;

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
        final CryptoCipherStructureAbstract[] availableCryptoForEBID = new CryptoCipherStructureAbstract[this.numberOfThreads];
        final CryptoCipherStructureAbstract[] availableCryptoForECC = new CryptoCipherStructureAbstract[this.numberOfThreads];

        for (int i = 0; i < this.numberOfThreads; i++) {
            availableCryptoForEBID[i] = new CryptoSkinny64(this.serverKey);;
            availableCryptoForECC[i] = new CryptoAES(this.federationKey);
        }
        // assign generated TripleDES to the TripleConcurrentList
        this.cryptoStructureForEBIDList = new CryptoStructureConcurrentArray<>(availableCryptoForEBID);
        this.cryptoStructureForECCList = new CryptoStructureConcurrentArray<>(availableCryptoForECC);
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
                            this.cryptoStructureForEBIDList,
                            this.cryptoStructureForECCList,
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
