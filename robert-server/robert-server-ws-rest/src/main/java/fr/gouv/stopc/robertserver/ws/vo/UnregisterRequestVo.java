package fr.gouv.stopc.robertserver.ws.vo;

import lombok.Builder;

public class UnregisterRequestVo extends AuthRequestVo {
    @Builder
    public UnregisterRequestVo(String ebid, Integer epochId, String time, String mac) {
        super(ebid, epochId, time, mac);
    }
}
