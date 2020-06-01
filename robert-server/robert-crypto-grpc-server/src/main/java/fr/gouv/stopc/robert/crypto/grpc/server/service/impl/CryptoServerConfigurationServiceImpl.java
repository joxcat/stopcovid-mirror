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

    @Override
    public long getServiceTimeStart() {
        final LocalDateTime ldt = LocalDateTime.of(2020, 4, 14, 00, 00);
        final ZonedDateTime zdt = ldt.atZone(ZoneId.of("Europe/Paris"));
        return TimeUtils.convertUnixMillistoNtpSeconds(zdt.toInstant().toEpochMilli());
    }
}
