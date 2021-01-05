package fr.gouv.stopc.robertserver.ws.controller;

import javax.validation.Valid;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import fr.gouv.stopc.robertserver.ws.dto.ReportBatchResponseV4Dto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.utils.UriConstants;
import fr.gouv.stopc.robertserver.ws.vo.ReportBatchRequestVo;

@RestController
@RequestMapping(value = "${controller.path.prefix}" + UriConstants.API_V4,
		consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
public interface IReportControllerV4 {

	@PostMapping(value = UriConstants.REPORT)
	ResponseEntity<ReportBatchResponseV4Dto> reportContactHistory(@Valid @RequestBody(required = true) ReportBatchRequestVo reportBatchRequestVo)
			throws RobertServerException;
}
