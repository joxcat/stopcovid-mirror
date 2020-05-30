package fr.gouv.stopc.robert.server.crypto.callable;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import fr.gouv.stopc.robert.server.crypto.structure.ICryptoStructure;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;

/**
 * Thread safe usage of TripleDES in concurrent thread.
 */
class CryptoStructureConcurrentArray<T extends ICryptoStructure> {
    private List<T> cryptoStructureList;

    private final Map<String, T> cryptoStructureIndexByThread = new HashMap<>();

    /**
     * Constructor defines the cryptoStructure Array to be used by a bunch of threads
     * @param cryptoStructureArray {@link #getCryptoStructure(String)}
     */
    public CryptoStructureConcurrentArray(T[] cryptoStructureArray) {
        this.cryptoStructureList = Arrays.asList(cryptoStructureArray);
    }

    /**
     * Array of CryptoStructure object stored to be used by a bunch of thread in ThreadPoolExecutor
     * @param threadName is the name of a thread
     * @return return an assigned CryptoStructure depending of the given threadName
     * @throws RobertServerCryptoException
     */
    public T getCryptoStructure(String threadName) throws RobertServerCryptoException {
//        if (!this.cryptoStructureIndexByThread.containsKey(threadName)) {
            this.cryptoStructureList = Collections.synchronizedList(this.cryptoStructureList);

            if (this.cryptoStructureList.isEmpty()) {
                throw new RobertServerCryptoException("There is no more CryptoStructure available.");
            }

            final T t = this.cryptoStructureList.get(0);
//            this.cryptoStructureIndexByThread.put(threadName, t);

            this.cryptoStructureList = withoutFirstElement(this.cryptoStructureList);
//        }
        return this.cryptoStructureIndexByThread.get(threadName);
    }

    private List<T> withoutFirstElement(List<T> list) {
        T[] cryptoStructureArray = (T[]) list.toArray();
        cryptoStructureArray = Arrays.copyOfRange(cryptoStructureArray, 1, cryptoStructureArray.length);
        List<T> truncatedList = Arrays.asList(cryptoStructureArray);
        return Collections.synchronizedList(truncatedList);
    }
}
