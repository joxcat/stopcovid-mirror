package fr.gouv.stopc.robertserver.ws.dto;

import javax.validation.constraints.NotNull;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Builder
public class CaptchaImageDto {

	@NotNull
	private String format;

	@NotNull
	private Integer value;

	@NotNull
	private String data;
}
