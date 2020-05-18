package fr.gouv.stopc.robertserver.database.service;

import java.util.List;

import fr.gouv.stopc.robertserver.database.model.ApplicationConfigurationModel;

public interface IApplicationConfigService {
	
	public List<ApplicationConfigurationModel> findAll();

}
