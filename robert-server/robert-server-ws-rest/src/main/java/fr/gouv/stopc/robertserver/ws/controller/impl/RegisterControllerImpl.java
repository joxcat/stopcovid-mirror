package fr.gouv.stopc.robertserver.ws.controller.impl;

import javax.inject.Inject;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.database.service.IApplicationConfigService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.controller.IRegisterController;
import fr.gouv.stopc.robertserver.ws.dto.RegisterResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.service.CaptchaService;
import fr.gouv.stopc.robertserver.ws.vo.RegisterVo;

@Service
public class RegisterControllerImpl extends AbstractRegisterControllerImpl implements IRegisterController {

    private final CaptchaService captchaService;

    @Inject
    public RegisterControllerImpl(final IRegistrationService registrationService,
            final IServerConfigurationService serverConfigurationService,
            final IApplicationConfigService applicationConfigService,
            final CaptchaService captchaService,
            final ICryptoServerGrpcClient cryptoServerClient) {

        this.registrationService = registrationService;
        this.serverConfigurationService = serverConfigurationService;
        this.applicationConfigService = applicationConfigService;
        this.captchaService = captchaService;
        this.cryptoServerClient = cryptoServerClient;

    }

    @Override
    public ResponseEntity<RegisterResponseDto> register(RegisterVo registerVo) throws RobertServerException {

        if (!this.captchaService.verifyCaptcha(registerVo)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        return postCheckRegister(registerVo);
    }
}
