package fr.gouv.stopc.robert.server.crypto.structure;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import java.security.spec.AlgorithmParameterSpec;

public interface ICipherStructure {

    Cipher getCipher();
    
    Cipher getDecryptCypher();

    AlgorithmParameterSpec getAlgorithmParameterSpec();
}
