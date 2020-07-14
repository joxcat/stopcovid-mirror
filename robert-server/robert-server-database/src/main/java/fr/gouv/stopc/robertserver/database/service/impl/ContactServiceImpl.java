package fr.gouv.stopc.robertserver.database.service.impl;

import java.util.List;
import java.util.Optional;

import javax.inject.Inject;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.CollectionUtils;

import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.repository.ContactRepository;
import fr.gouv.stopc.robertserver.database.service.ContactService;
import org.springframework.util.CollectionUtils;


@Service
@Transactional
public class ContactServiceImpl implements ContactService {

	private ContactRepository contactRepository;

	@Inject
	public ContactServiceImpl(ContactRepository contactRepository) {

		this.contactRepository = contactRepository;
	}

	@Override
	public void saveContacts(List<Contact> contacts) {

		contactRepository.insert(contacts);
	}

	@Override
	public void delete(Contact contact) {

		Optional.ofNullable(contact).ifPresent(this.contactRepository::delete);
	}

	@Override
	public void deleteAll(List<Contact> contacts) {
		if (!CollectionUtils.isEmpty(contacts)) {
			this.contactRepository.deleteAll(contacts);
		}
	}

	@Override
	public void deleteAll() {
		this.contactRepository.deleteAll();
	}

	@Override
	public List<Contact> findAll() {

		return this.contactRepository.findAll();
	}

	@Override
	public Long count() {
		return this.contactRepository.count();
	}
}
