package fr.gouv.stopc.robertserver.ws.vo.mapper;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.bson.internal.Base64;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;

import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.HelloMessageDetail;
import fr.gouv.stopc.robertserver.ws.vo.HelloMessageDetailVo;
import fr.gouv.stopc.robertserver.ws.vo.ContactVo;

@Component
public class ContactMapper {


	public ContactMapper() {}

	public Optional<Contact> convertToEntity(ContactVo contactVo) {

		return Optional.ofNullable(contactVo).map(this::mapContact).orElse(Optional.empty());
	}

	public List<Contact> convertToEntity(List<ContactVo> contactVoList) {

		if (CollectionUtils.isEmpty(contactVoList)) {
			return Collections.emptyList();
		}

		List<Contact> contacts = new ArrayList<>();
		contactVoList.stream()
				.map(this::convertToEntity)
				.filter(item -> item.isPresent())
				.forEach(item -> contacts.add(item.get()));

		return contacts;

	}

	private HelloMessageDetail mapHelloMessageDetail(HelloMessageDetailVo dtoMessage) {
		return HelloMessageDetail.builder()
				.mac(Base64.decode(dtoMessage.getMac()))
				.rssiCalibrated(dtoMessage.getRssiCalibrated())
				.timeCollectedOnDevice(dtoMessage.getTimeCollectedOnDevice())
				.timeFromHelloMessage(dtoMessage.getTimeFromHelloMessage())
				.build();
	}

	private Optional<Contact> mapContact(ContactVo contactVo) {
		List<HelloMessageDetail> messageDetails = contactVo.getIds()
				.stream()
				.map(this::mapHelloMessageDetail)
				.collect(Collectors.toList());

		return Optional.of(Contact.builder()
				.ecc(Base64.decode(contactVo.getEcc()))
				.ebid(Base64.decode(contactVo.getEbid()))
				.timeInsertion(System.currentTimeMillis())
				.messageDetails(messageDetails)
				.build());
	}
}
