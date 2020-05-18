package fr.gouv.stopc.robertserver.ws.vo;

import javax.validation.constraints.NotNull;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class RegisterVo {
  @JsonProperty(required = true)
  @NotNull
  @ToString.Exclude
  private String captcha;

}
