package fr.gouv.stopc.robertserver.ws.vo;

import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.ToString;

@Getter
@AllArgsConstructor
public abstract class AuthRequestVo
 {
    @NotNull
    @Size(min = 12, max = 12)
    @ToString.Exclude
    private String ebid;

    @NotNull
    @ToString.Exclude
    @Min(0)
    private Integer epochId;

    @NotNull
    @Size(min = 8, max = 8)
    private String time;

    @NotNull
    @Size(min = 44, max = 44)
    private String mac;
}
