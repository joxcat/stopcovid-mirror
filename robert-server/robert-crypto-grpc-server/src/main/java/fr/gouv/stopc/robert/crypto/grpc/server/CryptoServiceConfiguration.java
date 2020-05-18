package fr.gouv.stopc.robert.crypto.grpc.server;

import java.io.IOException;

import javax.inject.Inject;

import org.springframework.context.annotation.Configuration;

import fr.gouv.stopc.robert.crypto.grpc.server.utils.PropertyLoader;

@Configuration
public class CryptoServiceConfiguration {

	
	@Inject
	public CryptoServiceConfiguration(CryptoServiceGrpcServer server, 
			PropertyLoader propertyLoader) throws IOException, InterruptedException {

		server.initPort(Integer.parseInt(propertyLoader.getCryptoServerPort()));
		server.start();
		server.blockUntilShutdown();

	}

}
