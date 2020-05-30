package fr.gouv.stopc.robertserver.ws.dto;

import java.util.List;

import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;

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
	private String tuples;

	@Singular("config")
	private List<ClientConfigDto> config;

	@Min(3797858242L)
	private long timeStart;

	private String message;
 }
