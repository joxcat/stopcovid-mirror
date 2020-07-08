package fr.gouv.stopc.robertserver.ws.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Builder
public class CaptchaInternalDto {

	/** Present only if the request has been completed successfully */
	@JsonProperty("result")
	private String result;

	/** Present, along with {@link #errorMessage}, only if the request had some issue */
	@JsonProperty("code")
	private String errorCode;

	/** Present, along with {@link #errorCode}, only if the request had some issue */
	@JsonProperty("message")
	private String errorMessage;

}
