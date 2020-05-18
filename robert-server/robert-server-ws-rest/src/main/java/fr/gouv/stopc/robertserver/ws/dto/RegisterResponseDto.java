package fr.gouv.stopc.robertserver.ws.dto;

import java.util.List;

import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.Singular;
import lombok.ToString;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class RegisterResponseDto
 {
	
	@NotNull
	@ToString.Exclude
	private String key;

	@NotNull
	@Size(min = 1)
	@Singular
	private List<EpochKeyBundleDto> idsForEpochs;

	private String message;

	@Singular("filteringAlgoConfig")
	private List<AlgoConfigDto> filteringAlgoConfig;

	@Min(3797858242L)
	private long timeStart;

}
