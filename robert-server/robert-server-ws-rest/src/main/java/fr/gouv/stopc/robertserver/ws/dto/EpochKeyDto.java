package fr.gouv.stopc.robertserver.ws.dto;

import java.io.Serializable;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class EpochKeyDto implements Serializable {

	@NotNull
	@Size(min = 12, max = 12)
	@ToString.Exclude
	private String ebid;

	@NotNull
	@Size(min = 4, max = 4)
	private String ecc;
}
