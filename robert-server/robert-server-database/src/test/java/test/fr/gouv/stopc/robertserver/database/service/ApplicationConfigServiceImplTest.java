package test.fr.gouv.stopc.robertserver.database.service;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.verify;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import fr.gouv.stopc.robertserver.database.repository.ApplicationConfigurationRepository;
import fr.gouv.stopc.robertserver.database.service.impl.ApplicationConfigServiceImpl;

@ExtendWith(SpringExtension.class)
public class ApplicationConfigServiceImplTest {

	@InjectMocks
	private ApplicationConfigServiceImpl applicationConfigService;

	@Mock
	private ApplicationConfigurationRepository applicationConfigRepository; 

	@Test
	public void testFindAll() {

		// Given
		assertNotNull(this.applicationConfigService);
		assertNotNull(this.applicationConfigRepository);

		// When
		this.applicationConfigService.findAll();

		// Then
		verify(this.applicationConfigRepository).findAll();
	}

}
