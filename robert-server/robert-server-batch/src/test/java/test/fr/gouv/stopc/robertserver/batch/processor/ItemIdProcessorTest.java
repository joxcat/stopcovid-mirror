package test.fr.gouv.stopc.robertserver.batch.processor;

import fr.gouv.stopc.robert.server.batch.RobertServerBatchApplication;
import fr.gouv.stopc.robert.server.batch.model.ItemIdMapping;
import fr.gouv.stopc.robert.server.batch.processor.ContactIdMappingProcessor;
import fr.gouv.stopc.robert.server.batch.processor.RegistrationIdMappingProcessor;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.Registration;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.annotation.DirtiesContext.ClassMode;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.security.SecureRandom;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@Slf4j
@DirtiesContext(classMode = ClassMode.AFTER_EACH_TEST_METHOD)
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = { RobertServerBatchApplication.class })
@TestPropertySource(locations = "classpath:application.properties", properties = "robert.scoring.algo-version=0")
public class ItemIdProcessorTest {

	private ContactIdMappingProcessor contactIdMappingProcessor;

	private RegistrationIdMappingProcessor registrationIdMappingProcessor;

	@BeforeEach
	public void before() {
		this.contactIdMappingProcessor = new ContactIdMappingProcessor();
		this.registrationIdMappingProcessor = new RegistrationIdMappingProcessor();
	}

	@Test
	public void testBuilContactEntryForIdMapping() {
		// Given
		Contact contact1 = Contact.builder().id("a971").build();
		Contact contact2 = Contact.builder().id("a972").build();

		// When
		ItemIdMapping process1 = contactIdMappingProcessor.process(contact1);
		ItemIdMapping process2 = contactIdMappingProcessor.process(contact2);

		Long sequentialId1 = process1.getId();
		Long sequentialId2 = process2.getId();

		// Then
		assertNotNull(process1);
		assertNotNull(process2);
		assertNotNull(sequentialId1);
		assertNotNull(sequentialId2);
		assertNotNull(process1.getItemId());
		assertNotNull(process2.getItemId());

		assertEquals(sequentialId1+1, sequentialId2);
	}

	@Test
	public void testBuilRegistrationEntryForIdMapping() {
		// Given
		SecureRandom sr = new SecureRandom();
		byte[] rndBytes1 = new byte[5];
		sr.nextBytes(rndBytes1);

		byte[] rndBytes2 = new byte[5];
		sr.nextBytes(rndBytes2);

		Registration registration1 = Registration.builder().permanentIdentifier(rndBytes1).build();
		Registration registration2 = Registration.builder().permanentIdentifier(rndBytes2).build();

		// When
		ItemIdMapping process1 = registrationIdMappingProcessor.process(registration1);
		ItemIdMapping process2 = registrationIdMappingProcessor.process(registration2);

		Long sequentialId1 = process1.getId();
		Long sequentialId2 = process2.getId();

		// Then
		assertNotNull(process1);
		assertNotNull(process2);
		assertNotNull(sequentialId1);
		assertNotNull(sequentialId2);
		assertNotNull(process1.getItemId());
		assertNotNull(process2.getItemId());

		assertEquals(sequentialId1+1, sequentialId2);
	}
}
