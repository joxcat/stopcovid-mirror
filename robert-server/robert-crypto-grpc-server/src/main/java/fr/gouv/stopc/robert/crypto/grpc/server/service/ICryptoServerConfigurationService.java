package fr.gouv.stopc.robert.crypto.grpc.server.service;

public interface ICryptoServerConfigurationService {

    /**
     * Server key
     * 192-bits key uses in crypto
     * @return
     */
    byte[] getServerKey();

    /**
     * Federation key
     * 256-bits key uses in crypto
     * @return
     */
    byte[] getFederationKey();

    byte[] getServerKeyForEpochId(int epochId);

    long getServiceTimeStart();
}
