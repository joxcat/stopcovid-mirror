package fr.gouv.stopc.robertserver.ws.service.impl;

import org.springframework.http.HttpStatus;

import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

@NoArgsConstructor
@AllArgsConstructor
@Data
@SuperBuilder
public class CaptchaErrorMessage {

	private HttpStatus httpStatus;

	@JsonProperty
	private String message;

	@JsonProperty
	private String code;
}
