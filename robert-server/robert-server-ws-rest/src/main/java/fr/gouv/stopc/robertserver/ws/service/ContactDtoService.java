package fr.gouv.stopc.robertserver.ws.service;

import java.util.List;

import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.vo.GroupedHellosReportVo;


public interface ContactDtoService {

	public void saveContacts(List<GroupedHellosReportVo> contactVoList) throws RobertServerException;

}
