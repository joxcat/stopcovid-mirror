package fr.gouv.stopc.robertserver.ws.exception;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import lombok.extern.slf4j.Slf4j;

@ControllerAdvice
@Slf4j
public class CustomRestExceptionHandler extends ResponseEntityExceptionHandler {

	@Override
	protected ResponseEntity<Object> handleHttpRequestMethodNotSupported(HttpRequestMethodNotSupportedException e, HttpHeaders headers, HttpStatus status, WebRequest request) {

		String message = e.getLocalizedMessage();
		log.error(message);

		return new ResponseEntity<>(buildApiError(message), status);
	}

	@Override
	protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException e, HttpHeaders headers, HttpStatus status, WebRequest request) {

		String message = MessageConstants.INVALID_DATA.getValue();
		log.error(message, e.getCause());

		return new ResponseEntity<>(buildApiError(message), status);
	}

	@ExceptionHandler(value = Exception.class)
	public ResponseEntity<Object> handleException(Exception e) {

		String message = MessageConstants.ERROR_OCCURED.getValue();
		if (e instanceof RobertServerException) {
			message = e.getMessage();
		}
		log.error(message, e.getCause());

		return new ResponseEntity<>(buildApiError(message), retrieveHttpStatus(e));
	}

	private HttpStatus retrieveHttpStatus(Exception e) {

		if (e instanceof RobertServerUnauthorizedException) {
			return HttpStatus.UNAUTHORIZED;
		} else if (e instanceof RobertServerBadRequestException) {
			return HttpStatus.BAD_REQUEST;
		}

		return HttpStatus.INTERNAL_SERVER_ERROR;
	}

	private ApiError buildApiError(String message) {

		return ApiError.builder().message(message).build();
	}
}
