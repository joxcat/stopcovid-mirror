package test.fr.gouv.stopc.robertserver.database.repository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.util.List;

import org.bson.types.ObjectId;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.data.mongo.DataMongoTest;
import org.springframework.test.context.ContextConfiguration;

import fr.gouv.stopc.robertserver.database.RobertServerDatabaseApplication;
import fr.gouv.stopc.robertserver.database.model.ApplicationConfigurationModel;
import fr.gouv.stopc.robertserver.database.repository.ApplicationConfigurationRepository;

@ContextConfiguration(classes = { RobertServerDatabaseApplication.class })
@DataMongoTest
public class ApplicationConfigurationRepositoryTest {

	@Autowired
	private ApplicationConfigurationRepository applicationConfigurationRepository;

	@Test
	public void testApplicationConfigurationRepo() {
		// when
		this.applicationConfigurationRepository
				.save(new ApplicationConfigurationModel(new ObjectId().toString(), "config", "value"));
		List<ApplicationConfigurationModel> applicationConfigurationModels = this.applicationConfigurationRepository
				.findAll();
		// Then
		assertNotNull(applicationConfigurationModels);
		assertEquals(1, applicationConfigurationModels.size());
	}

}
