package fr.gouv.stopc.robertserver.ws.vo;

import lombok.Builder;

public class DeleteHistoryRequestVo extends AuthRequestVo {

	@Builder
	public DeleteHistoryRequestVo(String ebid, String time, String mac) {
		super(ebid, time, mac);
	}

}
