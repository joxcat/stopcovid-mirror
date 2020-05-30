package fr.gouv.stopc.robert.crypto.grpc.server.storage.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@AllArgsConstructor
@Getter
public class RobertServerStorageException extends Exception {

    private static final long serialVersionUID = 1L;

    private String message;

    private Throwable error;

    public RobertServerStorageException(String message) {

        this.message = message;
    }

}
