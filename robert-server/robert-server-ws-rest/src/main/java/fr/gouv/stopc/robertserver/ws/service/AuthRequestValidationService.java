package fr.gouv.stopc.robertserver.ws.service;

import org.springframework.http.ResponseEntity;

import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.vo.AuthRequestVo;

import java.util.Optional;

public interface AuthRequestValidationService {
    /**
     * Perform MAC validation for an authenticated request
     */
    interface IMacValidator {
        boolean validate(byte[] key, byte[] toCheck, byte[] mac);
    }

    /**
     * Perform further business validation of request and request handling
     */
    interface IAuthenticatedRequestHandler {
        Optional<ResponseEntity> validate(Registration record, int epoch) throws RobertServerException;
    }

    Optional<ResponseEntity> validateRequestForAuth(AuthRequestVo authRequestVo,
                                                    IMacValidator macValidator,
                                                    IAuthenticatedRequestHandler otherValidator);
}
