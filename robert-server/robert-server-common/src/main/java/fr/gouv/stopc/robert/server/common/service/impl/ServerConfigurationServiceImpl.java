package fr.gouv.stopc.robert.server.common.service.impl;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;

import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;

/**
 * Issue #TODO: this class must not use hardcoded values
 * Facade for server configuration parameters and keys
 */
@Service
public class ServerConfigurationServiceImpl implements IServerConfigurationService {

    private final byte[] serverKey;

    private final byte[] federationKey;

    /**
     * Generate a key of bit array.
     *
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

    public ServerConfigurationServiceImpl() {
        // key serv should be a 192-bits key
        this.serverKey = this.generateKey(192);

        // key serv should be a 256-bits key
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
    public long getServiceTimeStart() {
        final LocalDateTime ldt = LocalDateTime.of(2020, 4, 14, 00, 00);
        final ZonedDateTime zdt = ldt.atZone(ZoneId.of("Europe/Paris"));
        return TimeUtils.convertUnixMillistoNtpSeconds(zdt.toInstant().toEpochMilli());
    }

    @Override
    public byte getServerCountryCode() {
        return (byte) 0x33;
    }

    @Override
    public int getHelloMessageTimeStampTolerance() {
        return 180;
    }

    @Override
    public int getContagiousPeriod() {
        return 14;
    }

    @Override
    public int getEpochDurationSecs() {
        return TimeUtils.EPOCH_DURATION_SECS;
    }

    @Override
    public int getEpochBundleDurationInDays() {
        // number of seconds in a day / duration of an epoch in seconds * number of days for which to generates bundle
        // (to be configurable)
        return 4;
    }

    @Override
    public int getRequestTimeDeltaTolerance() {
        return 60;
    }

    @Override
    public int getStatusRequestMinimumEpochGap() {
        return 2;
    }

    @Override
    public int getCaptchaChallengeTimestampTolerance() {
        return 60;
    }

    // Issue #TODO: store all values of this risk threshold to track any configuration change over time
    @Override
    public double getRiskThreshold() {
        return 0.5;
    }
}
