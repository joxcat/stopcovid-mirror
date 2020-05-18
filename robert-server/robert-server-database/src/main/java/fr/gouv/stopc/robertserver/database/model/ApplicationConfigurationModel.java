package fr.gouv.stopc.robertserver.database.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
@Document(collection = "application_configuration")
public class ApplicationConfigurationModel {

	@Id
	private String id;

	private String name;

	private Object value;
}
