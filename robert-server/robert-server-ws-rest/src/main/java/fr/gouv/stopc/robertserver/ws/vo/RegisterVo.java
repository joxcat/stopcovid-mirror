package fr.gouv.stopc.robertserver.ws.vo;

import javax.validation.constraints.NotEmpty;
import javax.validation.constraints.NotNull;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.experimental.SuperBuilder;

@AllArgsConstructor
@NoArgsConstructor
@Data
@SuperBuilder
public class RegisterVo {
  @JsonProperty(required = true)
  @NotNull
  @NotEmpty
  @ToString.Exclude
  private String captcha;

  @JsonProperty(required = true)
  @NotNull
  @NotEmpty
  @ToString.Exclude
  private String clientPublicECDHKey;

  @ToString.Exclude
  private PushInfoVo pushInfo;

}
