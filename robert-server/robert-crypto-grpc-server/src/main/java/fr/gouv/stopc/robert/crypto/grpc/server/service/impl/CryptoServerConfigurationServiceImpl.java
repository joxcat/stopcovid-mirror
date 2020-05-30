package fr.gouv.stopc.robert.crypto.grpc.server.service.impl;

import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.crypto.grpc.server.service.ICryptoServerConfigurationService;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;


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

    @Override
    public byte[] getServerKeyForEpochId(int epochId) {
        // TODO: retrieve key for this epoch from HSM storage
        return generateKey(192);
    }

    @Override
    public long getServiceTimeStart() {
        final LocalDateTime ldt = LocalDateTime.of(2020, 4, 14, 00, 00);
        final ZonedDateTime zdt = ldt.atZone(ZoneId.of("Europe/Paris"));
        return TimeUtils.convertUnixMillistoNtpSeconds(zdt.toInstant().toEpochMilli());
    }
}
