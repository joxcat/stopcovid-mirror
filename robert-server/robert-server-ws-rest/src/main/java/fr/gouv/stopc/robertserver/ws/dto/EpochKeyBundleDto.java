package fr.gouv.stopc.robertserver.ws.dto;

import java.io.Serializable;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotNull;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class EpochKeyBundleDto implements Serializable {

	@NotNull
	private long epochId;

	@NotNull
	private EpochKeyDto key;

}
