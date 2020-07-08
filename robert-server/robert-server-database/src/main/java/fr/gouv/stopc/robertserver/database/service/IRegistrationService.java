package fr.gouv.stopc.robertserver.database.service;

import java.util.List;
import java.util.Optional;

import fr.gouv.stopc.robertserver.database.model.Registration;

public interface IRegistrationService {
	
	Optional<Registration> createRegistration(byte[] id);
	
	Optional<Registration> findById(byte[] id);

	Optional<Registration> saveRegistration(Registration registration);

	void delete(Registration registration);

	void deleteAll();

	List<Registration> findAll();

	/**
	 * Return the number of users detected a new time at risk (isNotified = true and
	 * atRisk=true)
	 * 
	 * @return the number
	 */
	Long countNbUsersAtRiskAgain();

	/**
	 * Return the number of users detected a new time at risk (isNotified = false
	 * and atRisk = true)
	 * 
	 * @return the number
	 */
	Long countNbUsersAtRiskAndNotNotified();

	/**
	 * Return the number of users notified (isNotified = true, atRisk = false)
	 * 
	 * @return the number
	 */
	Long countNbUsersNotified();

	/**
	 * Return the number of users notified (isNotified = true, atRisk = false)
	 * 
	 * @return the number
	 */
	Long countNbExposedUsersButNotAtRisk();

}
