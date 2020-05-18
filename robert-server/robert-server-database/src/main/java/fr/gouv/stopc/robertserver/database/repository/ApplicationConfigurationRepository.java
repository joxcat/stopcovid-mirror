package fr.gouv.stopc.robertserver.database.repository;

import org.springframework.data.mongodb.repository.MongoRepository;

import fr.gouv.stopc.robertserver.database.model.ApplicationConfigurationModel;

public interface ApplicationConfigurationRepository extends MongoRepository<ApplicationConfigurationModel, String> {

}
