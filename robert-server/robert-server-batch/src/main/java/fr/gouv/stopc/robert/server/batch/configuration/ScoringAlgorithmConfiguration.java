package fr.gouv.stopc.robert.server.batch.configuration;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.Setter;

/**
 * Configuration class of the scoring algorithm
 * 
 *
 */
@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "robert.scoring")
public class ScoringAlgorithmConfiguration {

	// Max Rssi cutting peak
	private int rssiMax;

	// Weighting vector for the # of packets received per window values
	private double[] deltas;

	// limit power in Db below which the collected value is assumed to be zero
	private double p0;

	// Constant for RSSI averaging = 10 log(10)
	private double softMaxA;

	// Constant for risk averaging
	private double softMaxB;

}
