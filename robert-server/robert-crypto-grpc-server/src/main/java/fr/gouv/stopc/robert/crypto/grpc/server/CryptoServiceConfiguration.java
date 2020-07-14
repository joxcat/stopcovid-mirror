package fr.gouv.stopc.robert.crypto.grpc.server;

import java.io.IOException;

import javax.inject.Inject;

import org.springframework.context.annotation.Configuration;

import fr.gouv.stopc.robert.crypto.grpc.server.storage.cryptographic.service.ICryptographicStorageService;
import fr.gouv.stopc.robert.crypto.grpc.server.utils.PropertyLoader;

@Configuration
public class CryptoServiceConfiguration {


    @Inject
    public CryptoServiceConfiguration(CryptoServiceGrpcServer server, 
            PropertyLoader propertyLoader, 
            ICryptographicStorageService  cryptoStorageService) throws IOException, InterruptedException {

        // Init the cryptographic Storage
        cryptoStorageService.init(propertyLoader.getKeyStorePassword(), propertyLoader.getKeyStoreConfigFile());

        server.initPort(Integer.parseInt(propertyLoader.getCryptoServerPort()));
        server.start();
        server.blockUntilShutdown();

    }

}
