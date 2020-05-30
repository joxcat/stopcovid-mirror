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
public class ReportBatchRequestVo {

	@NotNull
	@Size(min = 6, max = 36)
	@ToString.Exclude
	private String token;

	private List<ContactVo> contacts;

	private String contactsAsBinary;

}
