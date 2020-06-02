package fr.gouv.stopc.robert.crypto.grpc.server.service.impl;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.crypto.grpc.server.service.ICryptoServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;

/**
 * Default implementation of the ICryptoServerConfigurationService
 */
@Service
public class CryptoServerConfigurationServiceImpl implements ICryptoServerConfigurationService {

	@Value("${robert.server.time-start}")
	private String timeStart;

	@Value("${robert.protocol.hello-message-timestamp-tolerance:180}")
	private Integer helloMessageTimeStampTolerance;
	
	private Long timeStartNtp;

	/**
	 * Initializes the timeStartNtp field
	 */
	@PostConstruct
	private void initTimeStartNtp() {
		LocalDate ld = LocalDate.parse(timeStart, DateTimeFormatter.BASIC_ISO_DATE);
		timeStartNtp = TimeUtils.convertUnixStoNtpSeconds(ld.atStartOfDay().toEpochSecond(ZoneOffset.UTC));
	}
	
	@Override
	public long getServiceTimeStart() {
		return this.timeStartNtp;
	}
	
	@Override
	public int getHelloMessageTimeStampTolerance() {
		return this.helloMessageTimeStampTolerance;
	}
}
