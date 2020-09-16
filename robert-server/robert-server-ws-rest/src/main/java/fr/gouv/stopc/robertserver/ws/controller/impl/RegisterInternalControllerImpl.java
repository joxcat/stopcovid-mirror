package fr.gouv.stopc.robertserver.ws.controller.impl;

import javax.inject.Inject;
import javax.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.database.service.IApplicationConfigService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.config.WsServerConfiguration;
import fr.gouv.stopc.robertserver.ws.controller.IRegisterInternalController;
import fr.gouv.stopc.robertserver.ws.dto.RegisterResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.service.CaptchaInternalService;
import fr.gouv.stopc.robertserver.ws.service.IRestApiService;
import fr.gouv.stopc.robertserver.ws.vo.RegisterInternalVo;

@Service
public class RegisterInternalControllerImpl extends AbstractRegisterControllerImpl implements IRegisterInternalController {

    private final CaptchaInternalService captchaInternalService;

    @Inject
    public RegisterInternalControllerImpl(final IRegistrationService registrationService,
            final IServerConfigurationService serverConfigurationService,
            final IApplicationConfigService applicationConfigService,
            final CaptchaInternalService captchaInternalService,
            final ICryptoServerGrpcClient cryptoServerClient,
            final IRestApiService restApiService,
            final WsServerConfiguration wsServerConfiguration) {

        this.registrationService = registrationService;
        this.serverConfigurationService = serverConfigurationService;
        this.applicationConfigService = applicationConfigService;
        this.captchaInternalService = captchaInternalService;
        this.cryptoServerClient = cryptoServerClient;
        this.restApiService = restApiService;
        this.wsServerConfiguration = wsServerConfiguration;
    }

	@Override
	public ResponseEntity<RegisterResponseDto> register(@Valid RegisterInternalVo registerVo)
			throws RobertServerException {

        if (!this.captchaInternalService.verifyCaptcha(registerVo)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        
        return postCheckRegister(registerVo);
	}
}
