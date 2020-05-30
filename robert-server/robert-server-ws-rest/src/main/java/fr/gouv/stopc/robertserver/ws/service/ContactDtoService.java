package fr.gouv.stopc.robertserver.ws.service;

import java.util.List;

import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.vo.ContactVo;


public interface ContactDtoService {

	public void saveContacts(List<ContactVo> contactVoList) throws RobertServerException;

}
