package fr.gouv.stopc.robertserver.ws.config;

import javax.inject.Inject;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;

@Configuration
public class RobertServerWsConfiguration {
	
	@Inject
	public RobertServerWsConfiguration(final PropertyLoader propertyLoader,
			final ICryptoServerGrpcClient cryptoServerClient) {
		
		cryptoServerClient.init(propertyLoader.getCryptoServerHost(), Integer.parseInt( propertyLoader.getCryptoServerPort()));
	}

	@Bean
	public RestTemplate restTemplate() {

		return new RestTemplate();
	}

}
