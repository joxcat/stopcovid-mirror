package fr.gouv.stopc.robertserver.ws.controller;

import static fr.gouv.stopc.robertserver.ws.config.Config.API_V1;
import static fr.gouv.stopc.robertserver.ws.config.Config.API_V2;

import javax.validation.Valid;
import javax.ws.rs.Consumes;
import javax.ws.rs.Produces;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import fr.gouv.stopc.robertserver.ws.dto.ReportBatchResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.utils.UriConstants;
import fr.gouv.stopc.robertserver.ws.vo.ReportBatchRequestVo;

@RestController
@RequestMapping(value = {"${controller.path.prefix}" + API_V1, "${controller.path.prefix}" + API_V2})
@Consumes(MediaType.APPLICATION_JSON_VALUE)
@Produces(MediaType.APPLICATION_JSON_VALUE)
public interface IReportController {

	@PostMapping(value = UriConstants.REPORT)
	ResponseEntity<ReportBatchResponseDto> reportContactHistory(@Valid @RequestBody(required = true) ReportBatchRequestVo reportBatchRequestVo)
			throws RobertServerException;

}
