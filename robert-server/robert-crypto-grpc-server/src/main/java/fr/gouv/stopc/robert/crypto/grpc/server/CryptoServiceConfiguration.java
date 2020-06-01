package fr.gouv.stopc.robert.crypto.grpc.server;

import java.io.IOException;

import javax.inject.Inject;

import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
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

        // Store if does not exist the public and key 
        //cryptoStorageService.addECDHKeys(propertyLoader.getServerPublicKey(), propertyLoader.getServerPrivateKey());
        //cryptoStorageService.addKekKeysIfNotExist(
        //        ByteUtils.generateRandom(32),
        //        ByteUtils.generateRandom(32));
        server.initPort(Integer.parseInt(propertyLoader.getCryptoServerPort()));
        server.start();
        server.blockUntilShutdown();

    }

}
