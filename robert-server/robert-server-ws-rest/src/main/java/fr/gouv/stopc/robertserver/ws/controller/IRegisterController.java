package fr.gouv.stopc.robertserver.ws.controller;

import javax.validation.Valid;
import javax.ws.rs.Consumes;
import javax.ws.rs.Produces;

import fr.gouv.stopc.robertserver.ws.vo.RegisterVo;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import fr.gouv.stopc.robertserver.ws.dto.RegisterResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.utils.UriConstants;

@RestController
@RequestMapping(value = {"${controller.path.prefix}" + UriConstants.API_V2, "${controller.path.prefix}" + UriConstants.API_V3,
        "${controller.path.prefix}" + UriConstants.API_V4})
@Consumes(MediaType.APPLICATION_JSON_VALUE)
@Produces(MediaType.APPLICATION_JSON_VALUE)
public interface IRegisterController {

	@PostMapping(value = UriConstants.REGISTER)
	ResponseEntity<RegisterResponseDto> register(@Valid @RequestBody(required=true) RegisterVo registervo)
			throws RobertServerException;
}
