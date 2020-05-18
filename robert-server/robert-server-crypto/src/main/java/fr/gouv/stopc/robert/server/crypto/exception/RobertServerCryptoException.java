package fr.gouv.stopc.robert.server.crypto.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Getter
public class RobertServerCryptoException extends Exception {

	private static final long serialVersionUID = 1L;

	private String message;

	private Throwable error;

	public RobertServerCryptoException(String message) {

		this.message = message;
	}

}
