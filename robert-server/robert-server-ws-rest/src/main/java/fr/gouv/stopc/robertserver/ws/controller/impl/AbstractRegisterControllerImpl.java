package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.bson.internal.Base64;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CreateRegistrationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CreateRegistrationResponse;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.ApplicationConfigurationModel;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IApplicationConfigService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import fr.gouv.stopc.robertserver.ws.dto.ClientConfigDto;
import fr.gouv.stopc.robertserver.ws.dto.RegisterResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import fr.gouv.stopc.robertserver.ws.vo.RegisterVo;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public abstract class AbstractRegisterControllerImpl {

	protected IRegistrationService registrationService;
	protected IServerConfigurationService serverConfigurationService;
	protected IApplicationConfigService applicationConfigService;
	protected ICryptoServerGrpcClient cryptoServerClient;

	protected ResponseEntity<RegisterResponseDto> postCheckRegister(RegisterVo registerVo) throws RobertServerException {
	
	    byte[] clientPublicECDHKey = Base64.decode(registerVo.getClientPublicECDHKey());
	    byte[] serverCountryCode = new byte[1];
	    serverCountryCode[0] = this.serverConfigurationService.getServerCountryCode();
	
	    CreateRegistrationRequest request = CreateRegistrationRequest.newBuilder()
	            .setClientPublicKey(ByteString.copyFrom(clientPublicECDHKey))
	            .setNumberOfDaysForEpochBundles(this.serverConfigurationService.getEpochBundleDurationInDays())
	            .setServerCountryCode(ByteString.copyFrom(serverCountryCode))
	            .setFromEpochId(TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart()))
	            .build();
	
	    Optional<CreateRegistrationResponse> response = this.cryptoServerClient.createRegistration(request);
	
	    if(!response.isPresent() || response.get().hasError()) {
	        log.error("Unable to generate an identity for the client");
	        throw new RobertServerException(MessageConstants.ERROR_OCCURED);
	    }
	
	    CreateRegistrationResponse identity = response.get();
	
	    Registration registration = Registration.builder()
	            .permanentIdentifier(identity.getIdA().toByteArray())
	            .build();
	
	    Optional<Registration> registered = this.registrationService.saveRegistration(registration);
	
	    if (registered.isPresent()) {
	        RegisterResponseDto registerResponseDto = new RegisterResponseDto();
	
	        List<ApplicationConfigurationModel> serverConf = this.applicationConfigService.findAll();
	        if (CollectionUtils.isEmpty(serverConf)) {
	            registerResponseDto.setConfig(Collections.emptyList());
	        } else {
	            registerResponseDto.setConfig(serverConf
	                    .stream()
	                    .map(item -> ClientConfigDto.builder().name(item.getName()).value(item.getValue()).build())
	                    .collect(Collectors.toList()));
	        }
	
	        registerResponseDto.setTuples(Base64.encode(identity.getTuples().toByteArray()));
	        registerResponseDto.setTimeStart(this.serverConfigurationService.getServiceTimeStart());
	        return ResponseEntity.status(HttpStatus.CREATED).body(registerResponseDto);
	    }
	
	    return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
	}

}
