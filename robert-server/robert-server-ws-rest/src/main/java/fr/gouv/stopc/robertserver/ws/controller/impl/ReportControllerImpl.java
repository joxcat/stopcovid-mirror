package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.util.Optional;

import javax.inject.Inject;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.CollectionUtils;

import fr.gouv.stopc.robertserver.ws.controller.IReportController;
import fr.gouv.stopc.robertserver.ws.dto.ReportBatchResponseDto;
import fr.gouv.stopc.robertserver.ws.dto.VerifyResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerBadRequestException;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerUnauthorizedException;
import fr.gouv.stopc.robertserver.ws.service.ContactDtoService;
import fr.gouv.stopc.robertserver.ws.service.IRestApiService;
import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import fr.gouv.stopc.robertserver.ws.vo.ReportBatchRequestVo;
import io.micrometer.core.instrument.util.StringUtils;
import lombok.extern.slf4j.Slf4j;

import java.util.Objects;

@Service
@Slf4j
public class ReportControllerImpl implements IReportController {


    private final ContactDtoService contactDtoService;

    private final IRestApiService restApiService;


    @Inject
    public ReportControllerImpl(final ContactDtoService contactDtoService, final IRestApiService restApiService) {

        this.contactDtoService = contactDtoService;
        this.restApiService = restApiService;
    }

    private boolean areBothFieldsPresent(ReportBatchRequestVo reportBatchRequestVo) {
        return !CollectionUtils.isEmpty(reportBatchRequestVo.getContacts())
                && StringUtils.isNotEmpty(reportBatchRequestVo.getContactsAsBinary());
    }

    private boolean areBothFieldsAbsent(ReportBatchRequestVo reportBatchRequestVo) {
        return Objects.isNull(reportBatchRequestVo.getContacts())
                && StringUtils.isEmpty(reportBatchRequestVo.getContactsAsBinary());
    }

    @Override
    public ResponseEntity<ReportBatchResponseDto> reportContactHistory(ReportBatchRequestVo reportBatchRequestVo) throws RobertServerException {

        if (areBothFieldsPresent(reportBatchRequestVo)) {
            log.warn("Contacts and ContactsAsBinary are both present");
            return ResponseEntity.badRequest().build();
        } else if (Objects.isNull(reportBatchRequestVo.getContacts())) {
            log.warn("Contacts are null. They could be empty([]) but not null");
            return ResponseEntity.badRequest().build();
        }else if (areBothFieldsAbsent(reportBatchRequestVo)) {
            log.warn("Contacts and ContactsAsBinary are both absent");
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

        Optional<VerifyResponseDto> response = this.restApiService.verifyReportToken(token, getCodeType(token));

        if (!response.isPresent() ||  !response.get().isValid()) {
            log.warn("Verifying the token failed");
            throw new RobertServerUnauthorizedException(MessageConstants.INVALID_AUTHENTICATION.getValue());
        }

        log.info("Verifying the token succeeded");
    }

    private String getCodeType(String token) {
        // TODO: create enum for long and short codes
        return token.length() == 6 ? "2" : "1";
    }
}
