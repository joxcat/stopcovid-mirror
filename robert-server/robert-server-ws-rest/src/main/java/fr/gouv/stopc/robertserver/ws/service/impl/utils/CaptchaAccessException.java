package fr.gouv.stopc.robertserver.ws.service.impl.utils;

import org.springframework.http.HttpStatus;

import fr.gouv.stopc.robertserver.ws.service.impl.CaptchaErrorMessage;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Data
@EqualsAndHashCode(callSuper=false)
public class CaptchaAccessException extends RuntimeException {

	private CaptchaErrorMessage errorMessage;
	private HttpStatus statusCode;
	private String error;

	public CaptchaAccessException(HttpStatus statusCode, CaptchaErrorMessage errorMessage, String error) {
		super(error);
		this.errorMessage = errorMessage;
		this.statusCode = statusCode;
		this.error = error;
	}
}
