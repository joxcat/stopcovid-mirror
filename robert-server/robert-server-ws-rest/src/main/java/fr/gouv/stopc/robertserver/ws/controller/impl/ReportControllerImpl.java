package fr.gouv.stopc.robertserver.ws.controller.impl;

import javax.inject.Inject;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import fr.gouv.stopc.robertserver.ws.controller.IReportController;
import fr.gouv.stopc.robertserver.ws.dto.ReportBatchResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerBadRequestException;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerUnauthorizedException;
import fr.gouv.stopc.robertserver.ws.service.ContactDtoService;
import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import fr.gouv.stopc.robertserver.ws.vo.ReportBatchRequestVo;
import io.micrometer.core.instrument.util.StringUtils;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class ReportControllerImpl implements IReportController {

	private ContactDtoService contactDtoService;

	private RestTemplate restTemplate;

	@Value("${submission.code.server.host}")
	private String serverCodeHost;

	@Value("${submission.code.server.port}")
	private String serverCodePort;

	@Value("${submission.code.server.verify.path}")
	private String serverCodeVerificationUri;

	@Inject
	public ReportControllerImpl(ContactDtoService contactDtoService, RestTemplate restTemplate) {

		this.contactDtoService = contactDtoService;
		this.restTemplate = restTemplate;
	}

	private boolean areBothFieldsPresent(ReportBatchRequestVo reportBatchRequestVo) {
		return !CollectionUtils.isEmpty(reportBatchRequestVo.getContacts())
				&& StringUtils.isNotEmpty(reportBatchRequestVo.getContactsAsBinary());
	}

	private boolean areBothFieldsAbsent(ReportBatchRequestVo reportBatchRequestVo) {
		return CollectionUtils.isEmpty(reportBatchRequestVo.getContacts())
				&& StringUtils.isEmpty(reportBatchRequestVo.getContactsAsBinary());
	}

	@Override
	public ResponseEntity<ReportBatchResponseDto> reportContactHistory(ReportBatchRequestVo reportBatchRequestVo) throws RobertServerException {

		if (CollectionUtils.isEmpty(reportBatchRequestVo.getContacts())) {
			log.warn("No contacts in request");
			return ResponseEntity.badRequest().build();
		}

		if (areBothFieldsPresent(reportBatchRequestVo)) {
			log.warn("Contacts and ContactsAsBinary are both present");
			return ResponseEntity.badRequest().build();
		} else if (areBothFieldsAbsent(reportBatchRequestVo)) {
			log.warn("Contacts and ContactsAsBinary are absent");
			return ResponseEntity.badRequest().build();
		}

		checkValidityToken(reportBatchRequestVo.getToken());

		contactDtoService.saveContacts(reportBatchRequestVo.getContacts());

		ReportBatchResponseDto reportBatchResponseDto = ReportBatchResponseDto.builder().message(MessageConstants.SUCCESSFUL_OPERATION.getValue()).success(Boolean.TRUE).build();
		return ResponseEntity.ok(reportBatchResponseDto);
	}

	private void checkValidityToken(String token) throws RobertServerException {

		if (StringUtils.isEmpty(token)) {
			log.warn("No token provided");
			throw new RobertServerBadRequestException(MessageConstants.INVALID_DATA.getValue());
		}

		if (token.length() != 6 && token.length() != 36) {
			log.warn("Token size is incorrect");
			throw new RobertServerBadRequestException(MessageConstants.INVALID_DATA.getValue());
		}
		// TODO: Enable this when the token validation service is available
		// ResponseEntity<VerifyResponseDto> response = restTemplate.getForEntity(constructUri(), VerifyResponseDto.class, initHttpEntity(token));

		//		boolean isValid = Optional.ofNullable(response).map(ResponseEntity::getBody).map(VerifyResponseDto::isValid).orElse(false);

		// TODO: If isValid == false, then throw exception (when token validation is enabled).
		if (false) {
			throw new RobertServerUnauthorizedException(MessageConstants.INVALID_AUTHENTICATION.getValue());
		}
	}

	private String getCodeType(String token) {

		return token.length() == 6 ? "6-alphanum" : "UUIDv4";
	}

	private HttpEntity<VerifyRequestVo> initHttpEntity(String token) {

		HttpHeaders headers = new HttpHeaders();
		headers.setContentType(MediaType.APPLICATION_JSON);

		return new HttpEntity(new VerifyRequestVo(token, getCodeType(token)), headers);
	}

	private String constructUri() {

		return UriComponentsBuilder.newInstance().scheme("http").host(serverCodeHost).port(serverCodePort).path(serverCodeVerificationUri).build().toString();
	}

	@NoArgsConstructor
	@AllArgsConstructor
	@Data
	class VerifyRequestVo {

		private String code;

		private String type;

	}

	@NoArgsConstructor
	@AllArgsConstructor
	@Data
	class VerifyResponseDto {

		private boolean valid;

	}

}
