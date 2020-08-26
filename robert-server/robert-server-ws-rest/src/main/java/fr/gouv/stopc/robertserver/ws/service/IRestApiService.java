package fr.gouv.stopc.robertserver.ws.service;

import java.util.Optional;

import fr.gouv.stopc.robertserver.ws.dto.VerifyResponseDto;
import fr.gouv.stopc.robertserver.ws.vo.PushInfoVo;

public interface IRestApiService {

    Optional<VerifyResponseDto> verifyReportToken(String token, String type);

    void registerPushNotif(PushInfoVo pushInfoVo);

    void unregisterPushNotif(String pushToken);
}
