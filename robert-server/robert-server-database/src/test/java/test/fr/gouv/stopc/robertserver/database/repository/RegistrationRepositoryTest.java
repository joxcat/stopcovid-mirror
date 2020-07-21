package test.fr.gouv.stopc.robertserver.database.repository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.data.mongo.DataMongoTest;
import org.springframework.test.context.ContextConfiguration;

import fr.gouv.stopc.robertserver.database.RobertServerDatabaseApplication;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.repository.RegistrationRepository;

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

	@Test
	public void testCountNbUsersWithOldEpochExpositions() {

		// Given
		EpochExposition expos1 = new EpochExposition();
		EpochExposition expos2 = new EpochExposition();
		expos1.setEpochId(300);
		expos2.setEpochId(500);

		List<EpochExposition> exposList1 = new ArrayList<>();
		exposList1.add(expos1);
		exposList1.add(expos2);

		EpochExposition expos3 = new EpochExposition();
		EpochExposition expos4 = new EpochExposition();
		expos3.setEpochId(200);
		expos4.setEpochId(300);

		List<EpochExposition> exposList2 = new ArrayList<>();
		exposList2.add(expos3);
		exposList2.add(expos4);

		EpochExposition expos5 = new EpochExposition();
		EpochExposition expos6 = new EpochExposition();
		expos5.setEpochId(100);
		expos6.setEpochId(200);

		List<EpochExposition> exposList3 = new ArrayList<>();
		exposList3.add(expos5);
		exposList3.add(expos6);

		SecureRandom sr = new SecureRandom();
		byte[] rndBytes1 = new byte[5];
		sr.nextBytes(rndBytes1);

		Registration registration1 = new Registration();
		registration1.setPermanentIdentifier(rndBytes1);
		registration1.setExposedEpochs(exposList1);

		byte[] rndBytes2 = new byte[5];
		sr.nextBytes(rndBytes2);
		Registration registration2 = new Registration();
		registration2.setPermanentIdentifier(rndBytes2);
		registration2.setExposedEpochs(exposList2);

		byte[] rndBytes3 = new byte[5];
		sr.nextBytes(rndBytes3);
		Registration registration3 = new Registration();
		registration3.setPermanentIdentifier(rndBytes3);
		registration3.setExposedEpochs(exposList3);

		List<Registration> registrations = new ArrayList<>();
		registrations.add(registration1);
		registrations.add(registration2);
		registrations.add(registration3);

		// When
		registrationRepository.saveAll(registrations);

		// Then
		long nbOldEpochExpositions = this.registrationRepository.countNbUsersWithOldEpochExpositions(200);
		assertEquals(2, nbOldEpochExpositions);
	}
}
