package fr.gouv.stopc.robertserver.ws.vo;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

public class StatusVo extends AuthRequestVo {

    @Getter
    @Setter
    @ToString.Exclude
    private PushInfoVo pushInfo;

    @Builder
    public StatusVo(String ebid, Integer epochId, String time, String mac, PushInfoVo pushInfo) {
        super(ebid, epochId, time, mac);
        this.pushInfo = pushInfo;
    }
}
