package fr.gouv.stopc.robert.server.crypto.structure;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;

public interface ICipherStructure {

    Cipher getCipher();

    /**
     * IV Used in Cipher initialization.
     * @return
     */
    IvParameterSpec getIv();
}
