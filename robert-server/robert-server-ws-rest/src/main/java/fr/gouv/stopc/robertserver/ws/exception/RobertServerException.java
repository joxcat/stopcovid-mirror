package fr.gouv.stopc.robertserver.ws.exception;

import java.util.Optional;

import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor
@Getter
public class RobertServerException extends Exception {

	private static final long serialVersionUID = 1L;

	private String message;

	private Throwable error;

	public RobertServerException(String message) {

		this.message = message;
	}

	public RobertServerException(MessageConstants message) {

		Optional.ofNullable(message).ifPresent(item -> this.message = item.getValue());
	}

	public RobertServerException(MessageConstants message, Throwable error) {

		Optional.ofNullable(message).ifPresent(item -> this.message = item.getValue());
		this.error = error;
	}

}
