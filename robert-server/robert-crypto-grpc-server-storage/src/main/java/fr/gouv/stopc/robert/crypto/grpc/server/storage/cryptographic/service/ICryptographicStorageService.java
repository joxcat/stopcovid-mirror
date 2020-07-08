package fr.gouv.stopc.robert.crypto.grpc.server.storage.cryptographic.service;

import java.security.Key;
import java.security.KeyPair;
import java.security.Provider;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public interface ICryptographicStorageService {

    void init(String password, String configFile);
 
    boolean contains(String alias);

    byte[] getServerKey(int epochId, long serviceTimeStart, boolean takePreviousDaysKey);

    byte[][] getServerKeys(int epochId, long serviceTimeStart, int nbDays);

    Key getFederationKey();
 
    byte[] getEntry(String alias);

//    void addECDHKeys(String serverPublicKey, String serverPrivateKey);
//    void addKekKeysIfNotExist(byte[] kekForKa, byte[] kekForKs);

    Optional<KeyPair> getServerKeyPair();

    Provider getProvider();

    Key getKeyForEncryptingClientKeys();
    //Key getKeyForEncryptingServerKeys();

    /**
     * Reload the HSM to be able to access the keys added daily
     * @return Whether HSM reload was successful
     */
    boolean reloadHSM(String password, String configFile);

    /**
     * Gets the complete list of keys cached from the HSM
     * @return
     */
    List<String> getHSMCacheStatus();

}
