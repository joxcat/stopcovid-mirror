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
