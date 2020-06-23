package fr.gouv.stopc.robert.server.batch.model;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ScoringResult {

	private Integer duration;
	
	private Integer nbContacts;
	
	private Double rssiScore;
	
}
