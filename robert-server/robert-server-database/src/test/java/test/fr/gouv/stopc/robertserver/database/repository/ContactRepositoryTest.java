package test.fr.gouv.stopc.robertserver.database.repository;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.data.mongo.DataMongoTest;
import org.springframework.test.context.ContextConfiguration;

import fr.gouv.stopc.robertserver.database.RobertServerDatabaseApplication;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.repository.ContactRepository;
import lombok.extern.slf4j.Slf4j;

import static org.junit.jupiter.api.Assertions.*;

@Slf4j
@ContextConfiguration(classes = {RobertServerDatabaseApplication.class})
@DataMongoTest
public class ContactRepositoryTest {

	@Autowired
	private ContactRepository contactRepository;
	
	@Test
	public void testSave() {
		
		// when 
		Contact contact = this.contactRepository.insert(
				Contact.builder().build());
		
		// Then
		assertNotNull(contact);
	}

	@Test
	public void testInsertWhenContactIsNull() {

		try{
			// when
			Contact contactToSave = null;
			Contact contact = this.contactRepository.insert(contactToSave);
			assertNull(contact);

		} catch (Exception e) {
			log.error(e.getMessage());
			fail("It should not fail");
		}
	}
	
}
