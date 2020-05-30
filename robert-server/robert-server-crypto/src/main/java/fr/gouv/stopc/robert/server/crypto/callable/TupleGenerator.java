package fr.gouv.stopc.robert.server.crypto.callable;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import org.springframework.cglib.core.CollectionUtils;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.service.impl.CryptoServiceImpl;
import fr.gouv.stopc.robert.server.crypto.structure.CryptoCipherStructureAbstract;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESOFB;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoSkinny64;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class TupleGenerator {

    private final int numberOfThreads;

    private final byte[] serverKey;

    private final byte[] federationKey;
    
    private CryptoSkinny64 skinny64;
    
    private CryptoAESOFB  aes;

//    private final CryptoStructureConcurrentArray<CryptoCipherStructureAbstract> cryptoStructureForEBIDList;
//    private final CryptoStructureConcurrentArray<CryptoCipherStructureAbstract> cryptoStructureForECCList;

//    private ThreadPoolExecutor threadExecutor;
    private final CryptoService cryptoService;

    public TupleGenerator(byte[] serverKey, byte[] federationKey, int numberOfThreads) {
        this.numberOfThreads = numberOfThreads;
        this.serverKey = serverKey;
        this.federationKey = federationKey;
        this.skinny64 =  new CryptoSkinny64(this.serverKey);
        this.aes = new CryptoAESOFB(this.federationKey);

        // Create instance of CryptoServiceImpl that will be used in threads
        this.cryptoService = new CryptoServiceImpl();

        // Create ThreadPoolExecutor
//        this.threadExecutor = (ThreadPoolExecutor) Executors.newFixedThreadPool(1);

        // Generate [ #numberOfThreads * tripleDES ]
//        final CryptoCipherStructureAbstract[] availableCryptoForEBID = new CryptoSkinny64[this.numberOfThreads];
//        final CryptoCipherStructureAbstract[] availableCryptoForECC = new CryptoAESOFB[this.numberOfThreads];

//        for (int i = 0; i < this.numberOfThreads; i++) {
//            availableCryptoForEBID[i] = new CryptoSkinny64(this.serverKey);
//            availableCryptoForECC[i] = new CryptoAESOFB(this.federationKey);
//        }
        // assign generated TripleDES to the TripleConcurrentList
//        this.cryptoStructureForEBIDList = new CryptoStructureConcurrentArray<>(availableCryptoForEBID);
//        this.cryptoStructureForECCList = new CryptoStructureConcurrentArray<>(availableCryptoForECC);
    }

    public Collection<EphemeralTuple> exec(final byte[] idA,
                                           final int currentEpoch,
                                           final int numEpoch,
                                           final byte countryCode) throws RobertServerCryptoException {
        // Create list of callable executable
        Collection<EphemeralTuple> ephemeralTuples = new ArrayList<>();
        
        Stream<EphemeralTuple> ephemeralTupleStream = IntStream.range(0, numEpoch).mapToObj(i-> {
            try {
                return (new TupleCallable(
                                    this.cryptoService,
                                    this.skinny64,
                                    this.aes,
                                    idA, currentEpoch + i, countryCode
                            )).call();
            } catch (RobertServerCryptoException e) {

                log.error("Error When generation tupoles");
                return null;
            }
//            return null;
        });
        
        ephemeralTuples =  ephemeralTupleStream.filter(Objects::nonNull).collect(Collectors.toList());
        if (ephemeralTuples == null || ephemeralTuples.size() != numEpoch) {
            throw new RobertServerCryptoException("Failing to generate the tuples");
        }
        return ephemeralTuples;
//        });
//        for (int i = 0; i < numEpoch; i++) {
//            final int epoch = (currentEpoch + i);
//
//            callableList.add(
//                    (new TupleCallable(
//                            this.cryptoService,
//                            new CryptoSkinny64(this.serverKey),
//                            new CryptoAESOFB(this.federationKey),
//                            idA, epoch, countryCode
//                    )).call()
//            );
//        }

        // Store information related to execution.
//        Collection<EphemeralTuple> ephemeralTuples = new ArrayList<>();
//        try {
//            // Execute previous callable list
////            final List<EphemeralTupleFuture> futures = this.threadExecutor.invokeAll(callableList);
//
//
////            for (List<EphemeralTuple> future : futures) {
////                ephemeralTuples.add(future.get());
//            }
//        } catch (InterruptedException e) {
//            log.warn("Interrupting thread!", e);
//            Thread.currentThread().interrupt();
//        } catch (ExecutionException e) {
//            log.error(e.getMessage());
//            throw new RobertServerCryptoException(e.getMessage(), e);
//        }
//        return callableList;
    }

    public void stop() {
//        this.threadExecutor.shutdown();
    }
}
