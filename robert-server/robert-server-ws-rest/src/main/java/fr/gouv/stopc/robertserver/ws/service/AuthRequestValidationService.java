package fr.gouv.stopc.robertserver.ws.service;

import fr.gouv.stopc.robert.crypto.grpc.server.messaging.DeleteIdResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromAuthResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetIdFromStatusResponse;
import fr.gouv.stopc.robert.server.common.DigestSaltEnum;
import fr.gouv.stopc.robertserver.ws.vo.StatusVo;
import lombok.*;
import org.springframework.http.ResponseEntity;

import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.vo.AuthRequestVo;

import java.util.Optional;

public interface AuthRequestValidationService {

    @AllArgsConstructor
    @Builder
    @Getter
    class ValidationResult<T> {
        T response;
        ResponseEntity error;
    }

    ValidationResult<GetIdFromAuthResponse> validateRequestForAuth(AuthRequestVo authRequestVo, DigestSaltEnum requestType);
    ValidationResult<GetIdFromStatusResponse> validateStatusRequest(StatusVo statusVo);
    ValidationResult<DeleteIdResponse> validateRequestForUnregister(AuthRequestVo authRequestVo);
}
