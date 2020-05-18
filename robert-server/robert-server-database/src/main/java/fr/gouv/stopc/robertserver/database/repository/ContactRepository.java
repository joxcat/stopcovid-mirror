package fr.gouv.stopc.robertserver.database.repository;

import org.springframework.data.mongodb.repository.MongoRepository;

import fr.gouv.stopc.robertserver.database.model.Contact;


public interface ContactRepository extends MongoRepository<Contact, String> {

}
