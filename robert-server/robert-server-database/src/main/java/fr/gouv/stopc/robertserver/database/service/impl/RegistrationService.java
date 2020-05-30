package fr.gouv.stopc.robertserver.database.service.impl;

import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import javax.crypto.KeyGenerator;
import javax.inject.Inject;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.repository.RegistrationRepository;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;

@Slf4j
@Service
public class RegistrationService implements IRegistrationService {

	private RegistrationRepository registrationRepository;

	@Inject
	public RegistrationService(RegistrationRepository registrationRepository) {
		this.registrationRepository = registrationRepository;
	}

	// TODO: remove comments
//	private Registration create() {
//		return Registration.builder()
//		.permanentIdentifier(generateIdA())
//		.build();
//	}
//	private byte[] generateIdA() {
//		byte[] id = generateKey(5);
//		while(registrationRepository.existsById(id)) {
//			id = generateKey(5);
//		}
//		return id;
//	}
//
//	public byte [] generateKA() {
//		byte [] ka = null;
//
//		try {
//			KeyGenerator keyGen = KeyGenerator.getInstance("HmacSHA256");
//
//			//Creating a SecureRandom object
//			SecureRandom secRandom = new SecureRandom();
//
//			//Initializing the KeyGenerator
//			keyGen.init(secRandom);
//
//			//Creating/Generating a key
//			Key key = keyGen.generateKey();
//			ka = key.getEncoded();
//		} catch (NoSuchAlgorithmException e) {
//			log.error("Could not generate 256-bit key");
//		}
//		return ka;
//	}
//
//	public byte[] generateKey(final int nbOfbytes) {
//		byte[] rndBytes = new byte[nbOfbytes];
//		SecureRandom sr = new SecureRandom();
//		sr.nextBytes(rndBytes);
//		return rndBytes;
//	}

	@Override
	public Optional<Registration> createRegistration(byte[] id) {
		return Optional.ofNullable(Registration.builder()
					.permanentIdentifier(id)
					.build())
				.map(this.registrationRepository::insert);
	}

	@Override
	public Optional<Registration> findById(byte[] id) {
		return this.registrationRepository.findById(id);
	}
	
	@Override
	public Optional<Registration> saveRegistration(Registration registration) {
		return Optional.ofNullable(registration) 
				.map(this.registrationRepository::save);
	}

	@Override
	public void delete(Registration registration) {
		Optional.ofNullable(registration).ifPresent(this.registrationRepository::delete);
	}

	@Override
	public void deleteAll() {
		this.registrationRepository.deleteAll();
	}

	@Override
	public List<Registration> findAll() {
		return this.registrationRepository.findAll();
	}
	
}
