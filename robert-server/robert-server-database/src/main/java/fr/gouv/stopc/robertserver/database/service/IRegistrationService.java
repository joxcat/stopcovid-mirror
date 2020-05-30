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
	
}
