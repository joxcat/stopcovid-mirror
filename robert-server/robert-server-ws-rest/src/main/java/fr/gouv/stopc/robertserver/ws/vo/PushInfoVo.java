package fr.gouv.stopc.robertserver.ws.vo;

import javax.validation.constraints.NotNull;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class PushInfoVo {

    @NotNull
    @ToString.Exclude
    private String token;

    @NotNull
    @ToString.Exclude
    private String locale;

    @NotNull
    @ToString.Exclude
    private String timezone;

}
