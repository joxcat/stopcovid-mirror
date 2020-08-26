package fr.gouv.stopc.robertserver.ws.vo;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

public class UnregisterRequestVo extends AuthRequestVo {

    @Getter
    @Setter
    @ToString.Exclude
    private String pushToken;

    @Builder
    public UnregisterRequestVo(String ebid, Integer epochId, String time, String mac, String pushToken) {
        super(ebid, epochId, time, mac);
        this.pushToken = pushToken;
    }
}
