package fr.gouv.stopc.robertserver.ws.service;

import java.util.Optional;

import fr.gouv.stopc.robertserver.ws.dto.VerifyResponseDto;

public interface IRestApiService {

    Optional<VerifyResponseDto> verifyReportToken(String token, String type);
}
