package fr.gouv.stopc.robertserver.ws.vo;

import javax.validation.constraints.NotNull;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class CaptchaCreationVo {

    @NotNull
    private String type;

    @NotNull
    private String locale;
}
