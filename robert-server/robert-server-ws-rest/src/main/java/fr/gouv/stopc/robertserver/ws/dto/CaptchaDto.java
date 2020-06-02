package fr.gouv.stopc.robertserver.ws.dto;

import java.util.Date;
import java.util.List;

import javax.validation.constraints.NotNull;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Builder
public class CaptchaDto {

	@NotNull
	private boolean success;

	@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss'Z'")
	@JsonProperty("challenge_ts")
	private Date challengeTimestamp;

	@NotNull
	private String hostname;

	@JsonProperty("error-codes")
	private List<String> errorCodes;

}
