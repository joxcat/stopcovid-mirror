package fr.gouv.stopc.robertserver.ws.vo;

import java.util.ArrayList;
import java.util.List;

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
public class ContactVo {

	@NotNull
	@Size(min = 12, max = 12)
	@ToString.Exclude
	private String ebid;

	@NotNull
	@Size(min = 4, max = 4)
	private String ecc;

	/* TODO: to be formally validated first and added to API spec
	@NotNull
	@Min(0)
	private Integer neighborCount;

	@NotNull
	private Double contactScore;

	@NotNull
	private Integer contactDuration;

	@NotNull
	private Double confidence;
	*/

	@Builder.Default
	@Size(min = 1)
	@NotNull
	private List<HelloMessageDetailVo> ids = new ArrayList<>();

}
