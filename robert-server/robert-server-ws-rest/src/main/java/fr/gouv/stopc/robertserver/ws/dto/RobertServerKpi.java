package fr.gouv.stopc.robertserver.ws.dto;

import java.time.LocalDate;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Aggregation of Kpi on exposition and notification of users
 *
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RobertServerKpi {

	/**
	 * Date of computation of the KPI
	 */
	private LocalDate date;

	/**
	 * Number of alerted (notified) users
	 */
	private Long nbAlertedUsers;

	/**
	 * Number of users exposed to a user declared positive but not at risk
	 */
	private Long nbExposedButNotAtRiskUsers;

	/**
	 * Number of users exposed to a user declared positive, at risk but not yet
	 * notified
	 */
	private Long nbInfectedUsersNotNotified;

	/**
	 * Number of users already notified and scored again
	 */
	private Long nbNotifiedUsersScoredAgain;
}
