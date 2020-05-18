package fr.gouv.stopc.robertserver.database.model;

import javax.persistence.Id;
import javax.validation.constraints.NotNull;

import lombok.*;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.List;

@NoArgsConstructor
@AllArgsConstructor
@Data
@Builder
@Document(collection = "CONTACTS_TO_PROCESS")
public class Contact {

	@Id
	@ToString.Exclude
	private String id;

	@ToString.Exclude
	private byte[] ebid;

	@ToString.Exclude
	private byte[] ecc;

	@NotNull
	private List<HelloMessageDetail> messageDetails;

	@NotNull
	private Long timeInsertion;
}
