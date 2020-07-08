package fr.gouv.stopc.robertserver.ws.service.impl.utils;

import org.springframework.http.HttpStatus;

import fr.gouv.stopc.robertserver.ws.service.impl.CaptchaInternalErrorMessage;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
@EqualsAndHashCode(callSuper=false)
public class CaptchaInternalAccessException extends RuntimeException {

	private CaptchaInternalErrorMessage errorMessage;
	private HttpStatus statusCode;
	private String error;

	public CaptchaInternalAccessException(HttpStatus statusCode,CaptchaInternalErrorMessage errorMessage, String error) {
		super(error);
		this.errorMessage = errorMessage;
		this.statusCode = statusCode;
		this.error = error;
	}
}
