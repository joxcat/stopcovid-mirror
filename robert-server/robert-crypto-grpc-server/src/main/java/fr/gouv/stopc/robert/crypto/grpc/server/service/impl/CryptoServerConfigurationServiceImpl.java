package fr.gouv.stopc.robert.crypto.grpc.server.service.impl;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

import javax.annotation.PostConstruct;
import javax.inject.Inject;

import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.crypto.grpc.server.service.ICryptoServerConfigurationService;
import fr.gouv.stopc.robert.crypto.grpc.server.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;


/**
 * Default implementation of the ICryptoServerConfigurationService
 */
@Service
public class CryptoServerConfigurationServiceImpl implements ICryptoServerConfigurationService {

    private long timeStartNtp;

    private final PropertyLoader propertyLoader;

    @Inject
    public CryptoServerConfigurationServiceImpl(final PropertyLoader propertyLoader) {
        this.propertyLoader = propertyLoader;
    }
    /**
     * Initializes the timeStartNtp field
     */
    @PostConstruct
    private void initTimeStartNtp() {
        LocalDate ld = LocalDate.parse(this.propertyLoader.getTimeStart(), DateTimeFormatter.BASIC_ISO_DATE);
        final ZonedDateTime zdt = ld.atStartOfDay().atZone(ZoneId.of("UTC"));
        timeStartNtp = TimeUtils.convertUnixMillistoNtpSeconds(zdt.toInstant().toEpochMilli());
    }

    @Override
    public long getServiceTimeStart() {
        return this.timeStartNtp;
    }

}
