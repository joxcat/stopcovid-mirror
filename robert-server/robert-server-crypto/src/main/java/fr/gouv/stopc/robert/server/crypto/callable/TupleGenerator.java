package fr.gouv.stopc.robert.server.crypto.callable;

import java.security.Key;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAESECB;

import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.service.CryptoService;
import fr.gouv.stopc.robert.server.crypto.service.impl.CryptoServiceImpl;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoSkinny64;
import lombok.extern.slf4j.Slf4j;
import org.springframework.util.CollectionUtils;

@Slf4j
public class TupleGenerator {

    private final byte[] serverKey;

    private final Key federationKey;
    
    private CryptoSkinny64 skinny64;
    
    private CryptoAESECB aes;

    private final CryptoService cryptoService;

    public TupleGenerator(byte[] serverKey, Key federationKey) {
        this.serverKey = serverKey;
        this.federationKey = federationKey;
        this.skinny64 =  new CryptoSkinny64(this.serverKey);
        this.aes = new CryptoAESECB(this.federationKey);

        // Create instance of CryptoServiceImpl that will be used in threads
        this.cryptoService = new CryptoServiceImpl();
    }

    public Collection<EphemeralTuple> exec(final byte[] idA,
                                           final int currentEpoch,
                                           final int numEpoch,
                                           final byte countryCode) throws RobertServerCryptoException {
        Stream<EphemeralTuple> ephemeralTupleStream = IntStream.range(0, numEpoch).mapToObj(i -> {
            try {
                return new TupleCallable(
                                    this.cryptoService,
                                    this.skinny64,
                                    this.aes,
                                    idA,
                            currentEpoch + i,
                                    countryCode
                            ).call();
            } catch (RobertServerCryptoException e) {

                log.error("Error when generating tuples");
                return null;
            }
//            return null;
        });

        Collection<EphemeralTuple> ephemeralTuples = ephemeralTupleStream.filter(Objects::nonNull).collect(Collectors.toList());
        if (CollectionUtils.isEmpty(ephemeralTuples)) {
            throw new RobertServerCryptoException("Failed to generate the tuples");
        }
        if (ephemeralTuples.size() != numEpoch) {
            log.warn("Failed to generate some tuples");
        }
        return ephemeralTuples;
    }

    public void stop() {
//        this.threadExecutor.shutdown();
    }
}
