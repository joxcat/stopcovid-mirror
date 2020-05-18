package fr.gouv.stopc.robert.server.batch.configuration;

import javax.inject.Inject;

import org.springframework.context.annotation.Configuration;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;

@Configuration
public class RobertServerBatchConfiguration {
	
	@Inject
	public RobertServerBatchConfiguration(final PropertyLoader propertyLoader,
			final ICryptoServerGrpcClient cryptoServerClient) {
		
		cryptoServerClient.init(propertyLoader.getCryptoServerHost(), Integer.parseInt( propertyLoader.getCryptoServerPort()));
	}

}
