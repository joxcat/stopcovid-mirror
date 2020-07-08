package fr.gouv.stopc.robertserver.ws.service;

import java.time.LocalDate;
import java.util.List;

import fr.gouv.stopc.robertserver.ws.vo.RobertServerKpi;

/**
 * Service for Kpis generation
 *
 */
public interface IKpiService {

	/**
	 * Compute the Kpis for each day on a period
	 * 
	 * @param fromDate the beginning date of the period
	 * @param toDate   the ending date of the period
	 * @return the list of <code>RobertServerKpi</code> for each day on the period
	 */
	List<RobertServerKpi> computeKpi(LocalDate fromDate, LocalDate toDate);

}
