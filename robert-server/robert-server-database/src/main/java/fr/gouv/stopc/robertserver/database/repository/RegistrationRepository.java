package fr.gouv.stopc.robertserver.database.repository;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import fr.gouv.stopc.robertserver.database.model.Registration;

@Repository
public interface RegistrationRepository extends MongoRepository<Registration, byte[]>{
	
	
}
