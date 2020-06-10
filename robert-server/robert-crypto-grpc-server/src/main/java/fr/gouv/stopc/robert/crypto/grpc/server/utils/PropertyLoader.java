package fr.gouv.stopc.robert.crypto.grpc.server.utils;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import lombok.Getter;


@Getter
@Component
public class PropertyLoader {

    @Value("${robert.crypto.server.port}")
    private String cryptoServerPort;

    @Value("${robert.crypto.server.keystore.password}")
    private String keyStorePassword;

    @Value("${robert.crypto.server.keystore.config.file}")
    private String keyStoreConfigFile;

    @Value("${robert.crypto.server.public.key}")
    private String serverPublicKey;

    @Value("${robert.crypto.server.private.key}")
    private String serverPrivateKey;

    @Value("${robert.server.time-start}")
    private String timeStart;
}
