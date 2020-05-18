package fr.gouv.stopc.robertserver.database.service.impl;

import java.util.List;

import javax.inject.Inject;

import org.springframework.stereotype.Service;

import fr.gouv.stopc.robertserver.database.model.ApplicationConfigurationModel;
import fr.gouv.stopc.robertserver.database.repository.ApplicationConfigurationRepository;
import fr.gouv.stopc.robertserver.database.service.IApplicationConfigService;

@Service
public class ApplicationConfigServiceImpl implements IApplicationConfigService {

	private ApplicationConfigurationRepository repository;

	@Inject
	public ApplicationConfigServiceImpl(final ApplicationConfigurationRepository repository) {
		this.repository = repository;
	}

	@Override
	public List<ApplicationConfigurationModel> findAll() {
		return this.repository.findAll();
	}

}
