package fr.gouv.stopc.robertserver.ws.service.impl;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

import org.springframework.stereotype.Service;

import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.dto.RobertServerKpi;
import fr.gouv.stopc.robertserver.ws.service.IKpiService;

/**
 * Default implementation of the <code>IKpiService</code>
 * 
 */
@Service
public class KpiServiceImpl implements IKpiService {

	/**
	 * The registration management service
	 */
	private IRegistrationService registrationDbService;

	/**
	 * Spring Injection constructor
	 * 
	 * @param registrationDbService the <code>IRegistrationService</code> bean to
	 *                              inject
	 */
	public KpiServiceImpl(IRegistrationService registrationDbService) {
		this.registrationDbService = registrationDbService;
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	public List<RobertServerKpi> computeKpi(LocalDate fromDate, LocalDate toDate) {
		// Retrieve the different kpis of the current date (because of the
		// implementation of the Robert Protocol, kpis of Robert Server can be
		// calculated only for the current date)
		Long nbAlertedUsers = registrationDbService.countNbUsersAtRiskAgain()
				+ registrationDbService.countNbUsersNotified();
		Long nbExposedUsersNotAtRisk = registrationDbService.countNbExposedUsersButNotAtRisk();
		Long nbInfectedUsersNotNotified = registrationDbService.countNbUsersAtRiskAndNotNotified();
		Long nbNotifiedUsersScoredAgain = registrationDbService.countNbNotifiedUsersScoredAgain();
		
		return Arrays.asList(new RobertServerKpi(LocalDate.now(), nbAlertedUsers, nbExposedUsersNotAtRisk,
				nbInfectedUsersNotNotified, nbNotifiedUsersScoredAgain));
	}

}
