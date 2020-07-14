package test.fr.gouv.stopc.robertserver.database.service;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.repository.ContactRepository;
import fr.gouv.stopc.robertserver.database.service.impl.ContactServiceImpl;

@ExtendWith(SpringExtension.class)
public class ContactServiceImplTest {

	@InjectMocks
	private ContactServiceImpl contactService;

	@Mock
	private ContactRepository contactRepository;

	@BeforeEach
	public void before() {

		assertNotNull(this.contactService);
		assertNotNull(this.contactRepository);
		
	}

	@Test
	public void testSaveContact() {

		// Given
		List<Contact> contacts = new ArrayList<Contact>();
		contacts.add(new Contact());

		// When
		this.contactService.saveContacts(contacts);

		// Then
		verify(this.contactRepository).insert(contacts);
	}

	@Test
	public void testDeleteWhenIsNull() {

		// When
		this.contactService.delete(null);

		// Then
		verify(this.contactRepository, never()).delete(any());
	}

	@Test
	public void testDeleteWhenNotNull() {

		// Given
		Contact contact = new Contact();

		// When
		this.contactService.delete(contact);

		// Then
		verify(this.contactRepository).delete(contact);
	}

	@Test
	public void testDeleteAllWhenNotNull() {

		// When
		this.contactService.deleteAll(null);

		// Then
		verify(this.contactRepository, never()).deleteAll(any());
	}

	@Test
	public void testDeleteAllWhenIsNull() {

		// Given
		List<Contact> contacts = new ArrayList<>();
		contacts.add(new Contact());
		contacts.add(new Contact());

		// When
		this.contactService.deleteAll(contacts);

		// Then
		verify(this.contactRepository).deleteAll(contacts);
	}

	@Test
	public void testFindAll() {

		// When
		this.contactService.findAll();

		// Then
		verify(this.contactRepository).findAll();
	}

	@Test
	public void testCount() {

		// When
		this.contactService.count();

		// Then
		verify(this.contactRepository).count();
	}
}
