package fr.gouv.stopc.robertserver.ws.vo;

import lombok.Builder;

public class StatusVo extends AuthRequestVo {
    @Builder
    public StatusVo(String ebid, String time, String mac) {
        super(ebid, time, mac);
    }
}
