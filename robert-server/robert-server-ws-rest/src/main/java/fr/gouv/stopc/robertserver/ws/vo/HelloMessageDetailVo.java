package fr.gouv.stopc.robertserver.ws.vo;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class HelloMessageDetailVo {

	@NotNull
	@Min(0)
	@Max(4294967295L)
	private Long timeCollectedOnDevice;

	@NotNull
	@Min(0)
	@Max(65535)
	private Integer timeFromHelloMessage;

	@NotNull
	@Size(min = 8, max = 8)
	private String mac;

	@Min(-127)
	@Max(0)
	private Integer rssiCalibrated;

}
