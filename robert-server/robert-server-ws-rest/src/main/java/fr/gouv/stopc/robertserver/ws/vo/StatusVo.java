package fr.gouv.stopc.robertserver.ws.vo;

import javax.validation.constraints.NotNull;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

public class StatusVo extends AuthRequestVo {
    @Builder
    public StatusVo(String ebid, Integer epochId, String time, String mac) {
        super(ebid, epochId, time, mac);
    }
}
