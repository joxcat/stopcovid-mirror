package fr.gouv.stopc.robertserver.ws.dto;

import javax.validation.constraints.NotNull;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class ReportBatchResponseV4Dto {
	@NotNull
	private Boolean success;
	private String message;
	private String reportValidationToken;
}
