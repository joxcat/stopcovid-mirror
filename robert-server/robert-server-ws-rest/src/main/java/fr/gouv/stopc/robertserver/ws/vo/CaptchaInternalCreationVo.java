package fr.gouv.stopc.robertserver.ws.vo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class CaptchaInternalCreationVo {

    @NotNull
    private String type;

    @NotNull
    private String locale;
}
