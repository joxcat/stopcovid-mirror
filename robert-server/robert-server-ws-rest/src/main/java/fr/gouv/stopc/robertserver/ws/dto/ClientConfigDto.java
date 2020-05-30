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
public class ClientConfigDto {

	@NotNull
	private String name;

	@NotNull
	private Object value;

}
