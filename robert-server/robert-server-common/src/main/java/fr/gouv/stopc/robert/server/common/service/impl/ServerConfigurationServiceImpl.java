package fr.gouv.stopc.robert.server.common.service.impl;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

import javax.annotation.PostConstruct;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;

/**
 * Default implementation of the IServerConfigurationService
 */
@Service
public class ServerConfigurationServiceImpl implements IServerConfigurationService {

	@Value("${robert.server.country-code}")
	private byte serverCountryCode;

	@Value("${robert.protocol.hello-message-timestamp-tolerance:180}")
	private Integer helloMessageTimeStampTolerance;

	@Value("${robert.protocol.contagious-period:14}")
	private Integer contagiousPeriod;

	@Value("${robert.server.request-time-delta-tolerance:60}")
	private Integer requestTimeDeltaTolerance;

	@Value("${robert.server.status-request-minimum-epoch-gap:48}")
	private Integer statusRequestMinimumEpochGap;

	@Value("${robert.server.captcha-challenge-timestamp-tolerance:15}")
	private Integer captchaChallengeTimestampTolerance;

	@Value("${robert.protocol.risk-threshold:15.0}")
	private Double riskThreshold;

	@Value("${robert.protocol.epoch-bundle-duration:4}")
	private Integer epochBundleDurationInDays;

	@Value("${robert.server.time-start}")
	private String timeStart;

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
	public byte getServerCountryCode() {
		return this.serverCountryCode;
	}

	@Override
	public int getHelloMessageTimeStampTolerance() {
		return this.helloMessageTimeStampTolerance;
	}

	@Override
	public int getContagiousPeriod() {
		return this.contagiousPeriod;
	}

	@Override
	public int getEpochDurationSecs() {
		return TimeUtils.EPOCH_DURATION_SECS;
	}

	@Override
	public int getEpochBundleDurationInDays() {
		return this.epochBundleDurationInDays;
	}

	@Override
	public int getRequestTimeDeltaTolerance() {
		return this.requestTimeDeltaTolerance;
	}

	@Override
	public int getStatusRequestMinimumEpochGap() {
		return this.statusRequestMinimumEpochGap;
	}

	@Override
	public int getCaptchaChallengeTimestampTolerance() {
		return this.captchaChallengeTimestampTolerance;
	}

	@Override
	public double getRiskThreshold() {
		return this.riskThreshold;
	}
}
