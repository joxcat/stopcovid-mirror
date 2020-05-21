package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import javax.inject.Inject;

import org.bson.internal.Base64;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.EphemeralTupleRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.EphemeralTupleResponse;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.ApplicationConfigurationModel;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IApplicationConfigService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.controller.IRegisterController;
import fr.gouv.stopc.robertserver.ws.dto.AlgoConfigDto;
import fr.gouv.stopc.robertserver.ws.dto.RegisterResponseDto;
import fr.gouv.stopc.robertserver.ws.dto.mapper.EpochKeyBundleDtoMapper;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.service.CaptchaService;
import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import fr.gouv.stopc.robertserver.ws.vo.RegisterVo;

@Service
public class RegisterControllerImpl implements IRegisterController {

    private final IRegistrationService registrationService;

    private final IServerConfigurationService serverConfigurationService;

    private final IApplicationConfigService applicationConfigService;

    private final CaptchaService captchaService;

    private final EpochKeyBundleDtoMapper epochKeyBundleDtoMapper;

    private  final ICryptoServerGrpcClient cryptoServerClient;
 
    @Inject
    public RegisterControllerImpl(final IRegistrationService registrationService,
                                  final IServerConfigurationService serverConfigurationService,
                                  final IApplicationConfigService applicationConfigService,
                                  final CaptchaService captchaService,
                                  final EpochKeyBundleDtoMapper epochKeyBundleDtoMapper,
                                  final ICryptoServerGrpcClient cryptoServerClient) {

        this.registrationService = registrationService;
        this.serverConfigurationService = serverConfigurationService;
        this.applicationConfigService = applicationConfigService;
        this.captchaService = captchaService;
        this.epochKeyBundleDtoMapper = epochKeyBundleDtoMapper;
        this.cryptoServerClient = cryptoServerClient;

    }

    @Override
    public ResponseEntity<RegisterResponseDto> register(RegisterVo registerVo) throws RobertServerException {

          // TODO: Enable this when the capcha becomes
//        if (StringUtils.isEmpty(registerVo.getCaptcha())) {
//            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
//        }

        if (!this.captchaService.verifyCaptcha(registerVo)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        Optional<Registration> registration = this.registrationService.createRegistration();

 
        if (registration.isPresent()) {
            return ResponseEntity.status(HttpStatus.CREATED).body(processRegistration(registration.get()));
        }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
    }

    private RegisterResponseDto processRegistration(Registration registration) throws RobertServerException {

        RegisterResponseDto registerResponseDto = new RegisterResponseDto();

        List<ApplicationConfigurationModel> serverConf = this.applicationConfigService.findAll();
        if (CollectionUtils.isEmpty(serverConf)) {
            registerResponseDto.setFilteringAlgoConfig(Collections.emptyList());
        } else {
            registerResponseDto
                    .setFilteringAlgoConfig(serverConf.stream().map(item -> AlgoConfigDto.builder().name(item.getName()).value(item.getValue()).build()).collect(Collectors.toList()));
        }

        final byte countrycode = this.serverConfigurationService.getServerCountryCode();

        final long tpstStart = this.serverConfigurationService.getServiceTimeStart();
        final int numberOfEpochs = 4 * 24 * 4;

        final int currentEpochId = TimeUtils.getCurrentEpochFrom(tpstStart);
        
        registerResponseDto.setTimeStart(tpstStart);

        EphemeralTupleRequest request = EphemeralTupleRequest.newBuilder()
                .setCountryCode(ByteString.copyFrom(new byte[] {countrycode}))
                .setCurrentEpochID(currentEpochId)
                .setIdA(ByteString.copyFrom(registration.getPermanentIdentifier()))
                .setNumberOfEpochsToGenerate(numberOfEpochs)
                .build();

        Optional<EphemeralTupleResponse> tupleResponse = this.cryptoServerClient.generateEphemeralTuple(request);

        if (!tupleResponse.isPresent() || CollectionUtils.isEmpty(tupleResponse.get().getTupleList())) {
            throw new RobertServerException(MessageConstants.ERROR_OCCURED);
        }

        registerResponseDto.setIdsForEpochs(
                this.epochKeyBundleDtoMapper.convert(tupleResponse.get().getTupleList()));

        registerResponseDto.setKey(Base64.encode(registration.getSharedKey()));
        return registerResponseDto;
    }

}