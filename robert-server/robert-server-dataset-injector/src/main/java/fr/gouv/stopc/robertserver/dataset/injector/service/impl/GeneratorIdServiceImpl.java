package fr.gouv.stopc.robertserver.dataset.injector.service.impl;

import com.google.protobuf.ByteString;
import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CreateRegistrationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.CreateRegistrationResponse;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.dataset.injector.service.GeneratorIdService;
import fr.gouv.stopc.robertserver.dataset.injector.utils.PropertyLoader;
import lombok.extern.slf4j.Slf4j;
import org.bson.internal.Base64;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.GCMParameterSpec;
import javax.inject.Inject;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.spec.AlgorithmParameterSpec;
import java.util.Optional;

@Slf4j
@Service
public class GeneratorIdServiceImpl implements GeneratorIdService {

    private static final String AES_ENCRYPTION_CIPHER_SCHEME = "AES/GCM/NoPadding";
    private static final int IV_LENGTH = 12;

    @Autowired
    private IServerConfigurationService serverConfigurationService;

    private ICryptoServerGrpcClient cryptoServerClient;
    private final PropertyLoader propertyLoader;

    @Inject
    public GeneratorIdServiceImpl(PropertyLoader propertyLoader, ICryptoServerGrpcClient cryptoServerClient) {
        this.propertyLoader = propertyLoader;
        this.cryptoServerClient = cryptoServerClient;
        this.cryptoServerClient.init(propertyLoader.getCryptoServerHost(), Integer.parseInt(propertyLoader.getCryptoServerPort()));
    }

    @Override
    public byte[] generateIdA(){
        byte[] clientPublicECDHKey = Base64.decode("MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEtLhNO6Ez2Gc6H+xHCKUgVAOYk5PzQbcoNPxVvsE8IIHLQIoMlj9sj3A4oEHv8Ke/9xm9h6phSDkmficc24gJ+Q==");
        byte[] serverCountryCode = new byte[1];
        serverCountryCode[0] = this.serverConfigurationService.getServerCountryCode();

        CreateRegistrationRequest request = CreateRegistrationRequest.newBuilder()
                .setClientPublicKey(ByteString.copyFrom(clientPublicECDHKey))
                .setNumberOfDaysForEpochBundles(this.serverConfigurationService.getEpochBundleDurationInDays())
                .setServerCountryCode(ByteString.copyFrom(serverCountryCode))
                .setFromEpochId(TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart()))
                .build();

        Optional<CreateRegistrationResponse> response = this.cryptoServerClient.createRegistration(request);

        if(!response.isPresent()) {
            log.error("Unable to generate an identity for the client");
            return null;
        }

        return response.get().getIdA().toByteArray();
    }

    public byte[] decryptStoredKeyWithAES256GCMAndKek(byte[] storedKey, Key kek) {
        AlgorithmParameterSpec algorithmParameterSpec = new GCMParameterSpec(128, storedKey, 0, IV_LENGTH);
        byte[] toDecrypt = new byte[storedKey.length - IV_LENGTH];
        System.arraycopy(storedKey, IV_LENGTH, toDecrypt, 0, storedKey.length - IV_LENGTH);

        try {
            Cipher cipher = Cipher.getInstance(AES_ENCRYPTION_CIPHER_SCHEME);
            cipher.init(Cipher.DECRYPT_MODE, kek, algorithmParameterSpec);
            return cipher.doFinal(toDecrypt);
        } catch (NoSuchAlgorithmException | NoSuchPaddingException
                | InvalidKeyException | InvalidAlgorithmParameterException | IllegalBlockSizeException
                | BadPaddingException e) {
            log.error(String.format("Algorithm %s is not available", AES_ENCRYPTION_CIPHER_SCHEME));
        }
        return null;
    }
}
