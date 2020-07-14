package test.fr.gouv.stopc.robertserver.database.service;

import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.repository.RegistrationRepository;
import fr.gouv.stopc.robertserver.database.service.impl.RegistrationService;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import javax.crypto.KeyGenerator;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@Slf4j
@ExtendWith(SpringExtension.class)
public class RegistrationServiceImplTest {

	@InjectMocks
	private RegistrationService registrationService;

	@Mock
	RegistrationRepository registrationRepository;


	private byte[] generateIdA() {
		byte[] id = generateKey(5);
		while(registrationRepository.existsById(id)) {
			id = generateKey(5);
		}
		return id;
	}

	public byte [] generateKA() {
		byte [] ka = null;

		try {
			KeyGenerator keyGen = KeyGenerator.getInstance("HmacSHA256");

			//Creating a SecureRandom object
			SecureRandom secRandom = new SecureRandom();

			//Initializing the KeyGenerator
			keyGen.init(secRandom);

			//Creating/Generating a key
			Key key = keyGen.generateKey();
			ka = key.getEncoded();
		} catch (NoSuchAlgorithmException e) {
			log.error("Could not generate 256-bit key");
		}
		return ka;
	}

	public byte[] generateKey(final int nbOfbytes) {
		byte[] rndBytes = new byte[nbOfbytes];
		SecureRandom sr = new SecureRandom();
		sr.nextBytes(rndBytes);
		return rndBytes;
	}

	@Test
	public void testCreateRegistration() {

		// Given
		assertNotNull(this.registrationService);
		assertNotNull(this.registrationRepository);

		when(this.registrationRepository.existsById(any())).thenReturn(false);

		// When
		this.registrationService.createRegistration(this.generateIdA());

		// Then
		verify(this.registrationRepository).insert(any(Registration.class));

	}

	@Test
	public void testCreateRegistrationWhenExistATheFirstCall() {

		// Given
		assertNotNull(this.registrationService);
		assertNotNull(this.registrationRepository);

		when(this.registrationRepository.existsById(any())).thenReturn(true).thenReturn(false);

		// When
		this.registrationService.createRegistration(this.generateIdA());

		// Then
		verify(this.registrationRepository, times(2)).existsById(any());
		verify(this.registrationRepository).insert(any(Registration.class));

	}

	@Test
	public void testFindById() {

		// When
		this.registrationService.findById(ByteUtils.EMPTY_BYTE_ARRAY);

		// Then
		verify(this.registrationRepository).findById(ByteUtils.EMPTY_BYTE_ARRAY);
	}

	@Test
	public void testSaveRegistrationWhenIsNull() {

		// When
		this.registrationService.saveRegistration(null);

		// Then
		verify(this.registrationRepository, never()).save(any(Registration.class));
	}

	@Test
	public void testSaveRegistration() {

		// Given
		Registration registration = Registration.builder().build();

		// When
		this.registrationService.saveRegistration(registration);

		// Then
		verify(this.registrationRepository).save(registration);
	}

	@Test
	public void testSaveAllWhenIsNull() {

		// When
		this.registrationService.saveAll(null);

		// Then
		verify(this.registrationRepository, never()).saveAll(any(List.class));
	}

	@Test
	public void testSaveAllWhenNotNull() {

		// Given
		List<Registration> registrations = new ArrayList<>();
		registrations.add(Registration.builder().build());
		registrations.add(Registration.builder().build());

		// When
		this.registrationService.saveAll(registrations);

		// Then
		verify(this.registrationRepository).saveAll(registrations);
	}


	@Test
	public void testDeleteWhenIsNull() {

		// When
		this.registrationService.delete(null);

		// Then
		verify(this.registrationRepository, never()).delete(any());
	}

	@Test
	public void testDeleteWhenNotNull() {

		// Given
		Registration registration = new Registration();

		// When
		this.registrationService.delete(registration);

		// Then
		verify(this.registrationRepository).delete(registration);
	}

	@Test
	public void testFindAll() {

		// When
		this.registrationService.findAll();

		// Then
		verify(this.registrationRepository).findAll();
	}

	@Test
	public void testCount() {

		// When
		this.registrationService.count();

		// Then
		verify(this.registrationRepository).count();
	}

	@Test
	public void countNbUsersWithOldEpochExpositions() {

		// When
		this.registrationService.countNbUsersWithOldEpochExpositions(3000);

		// Then
		verify(this.registrationRepository).countNbUsersWithOldEpochExpositions(3000);
	}

}
