package fr.gouv.stopc.robertserver.ws.service;

import fr.gouv.stopc.robertserver.ws.vo.RegisterInternalVo;


public interface CaptchaInternalService {

	boolean verifyCaptcha(RegisterInternalVo registerVo);

}
