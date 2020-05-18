package fr.gouv.stopc.robertserver.ws.service;

import fr.gouv.stopc.robertserver.ws.vo.RegisterVo;


public interface CaptchaService {

	boolean verifyCaptcha(RegisterVo registerVo);

}
