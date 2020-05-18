package test.fr.gouv.stopc.robertserver.database.repository;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.security.SecureRandom;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.data.mongo.DataMongoTest;
import org.springframework.test.context.ContextConfiguration;

import fr.gouv.stopc.robertserver.database.RobertServerDatabaseApplication;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.repository.RegistrationRepository;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@ContextConfiguration(classes = {RobertServerDatabaseApplication.class})
@DataMongoTest
public class RegistrationRepositoryTest {

	@Autowired
    private RegistrationRepository registrationRepository;
	
	@Test
	public void testSave() {
		SecureRandom sr = new SecureRandom();
		byte[] rndBytes = new byte[5];
		sr.nextBytes(rndBytes);
		
		// when 
		Registration idTableTest = this.registrationRepository.insert(
				Registration.builder().permanentIdentifier(rndBytes).build());

		// Then
		assertNotNull(idTableTest);
	}
	
	@Test
	public void testGetFind() {
		
		// Given
		SecureRandom sr = new SecureRandom();
		byte[] rndBytes = new byte[5];
		sr.nextBytes(rndBytes);

		this.registrationRepository.insert(Registration.builder().permanentIdentifier(rndBytes).build());

		// When && Then
		assertTrue(this.registrationRepository.existsById(rndBytes));	
	}
}
