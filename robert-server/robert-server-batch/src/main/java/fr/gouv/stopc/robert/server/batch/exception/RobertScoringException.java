package fr.gouv.stopc.robert.server.batch.exception;

public class RobertScoringException extends Exception {
    public RobertScoringException(String message) {
        super(message);
    }

    public RobertScoringException(String message, Throwable cause) {
        super(message, cause);
    }
}
