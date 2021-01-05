package fr.gouv.stopc.robertserver.ws.controller.impl;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robertserver.ws.controller.IReportController;
import fr.gouv.stopc.robertserver.ws.dto.ReportBatchResponseDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.service.ContactDtoService;
import fr.gouv.stopc.robertserver.ws.service.IRestApiService;
import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import fr.gouv.stopc.robertserver.ws.vo.ReportBatchRequestVo;

@Service
public class ReportControllerImpl implements IReportController {

    private ReportControllerDelegate delegate;

	private ContactDtoService contactDtoService;

    public ReportControllerImpl(final ContactDtoService contactDtoService,
		final IRestApiService restApiService, final ReportControllerDelegate delegate) {

        this.contactDtoService = contactDtoService;
        this.delegate = delegate;
    }

    @Override
    public ResponseEntity<ReportBatchResponseDto> reportContactHistory(ReportBatchRequestVo reportBatchRequestVo) throws RobertServerException {
        if ( ! delegate.isReportRequestValid(reportBatchRequestVo) ) 
        	return ResponseEntity.badRequest().build();

        contactDtoService.saveContacts(reportBatchRequestVo.getContacts());
        
        ReportBatchResponseDto reportBatchResponseDto = ReportBatchResponseDto.builder()
				.message(MessageConstants.SUCCESSFUL_OPERATION.getValue())
				.success(Boolean.TRUE)
				.build();

		return ResponseEntity.ok(reportBatchResponseDto);
    }
}
