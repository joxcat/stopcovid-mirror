package fr.gouv.stopc.robertserver.ws.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotNull;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Builder
public class CaptchaInternalCreationDto {
    @JsonProperty("id")
    @NotNull
    private String captchaId;

    @JsonProperty("captchaId")
    public String getCaptchaId() {
        return this.captchaId;
    }
}
