package fr.gouv.stopc.robertserver.database.model;

import java.util.List;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
@Document(value = "idTable")
public class Registration {
	
	@Id
	@ToString.Exclude
	private byte[] permanentIdentifier;

	@ToString.Exclude
	private byte[] sharedKey;
	
	private boolean isNotified;
	
	private boolean atRisk;
	
	private int lastStatusRequestEpoch;

	private int lastNotificationEpoch;
	
	private List<EpochExposition> exposedEpochs;
	
}
