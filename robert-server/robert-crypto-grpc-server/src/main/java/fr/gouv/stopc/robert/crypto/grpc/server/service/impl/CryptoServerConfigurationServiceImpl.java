package fr.gouv.stopc.robert.crypto.grpc.server.service.impl;

import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.crypto.grpc.server.service.ICryptoServerConfigurationService;


/**
 * TODO : remove or update this class
 * Implementation of a fake service waiting server repository to be accessible.
 */
@Service
public class CryptoServerConfigurationServiceImpl implements ICryptoServerConfigurationService {

    private final byte[] serverKey;
    private final byte[] federationKey;

    /**
     * Generation of bit array.
     * @param size in bits
     * @return
     */
    private byte[] generateKey(int size) {
        size /= 8;
        byte[] data = new byte[size];
        for (int i = 0; i < size; i++) {
            data[i] = new Long(i).byteValue();
        }
        return data;
    }

    public CryptoServerConfigurationServiceImpl() {
        super();
       // server key should be a 192-bits key
       this.serverKey = this.generateKey(192);

        // federation kev should be a 256-bits key
        this.federationKey = this.generateKey(256);
    }

    @Override
    public byte[] getServerKey() {
        return this.serverKey;
    }

    @Override
    public byte[] getFederationKey() {
        return this.federationKey;
    }
}
