package test.fr.gouv.stopc.robert.crypto.grpc.server.service.impl;

import java.security.*;
import java.security.spec.ECGenParameterSpec;
import java.util.Optional;

import fr.gouv.stopc.robert.crypto.grpc.server.storage.cryptographic.service.ICryptographicStorageService;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.model.ClientIdentifierBundle;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.builder.ToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;
import org.bouncycastle.pqc.math.linearalgebra.ByteUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.ECDHKeyServiceImpl;
import test.fr.gouv.stopc.robert.crypto.grpc.server.utils.CryptoTestUtils;

import javax.crypto.KeyAgreement;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@Slf4j
@ExtendWith(SpringExtension.class)
public class ECDHKeyServiceImplTest {

    @InjectMocks
    private ECDHKeyServiceImpl keyService;

    @Mock
    private ICryptographicStorageService cryptographicStorageService;

    @BeforeEach
    void beforeEach() {
        assertNotNull(this.keyService);
    }

    @Test
    void testKeyDerivationFromClientPublicKeySucceeds() {

        // Given
        byte [] clientPublicKey = CryptoTestUtils.generateECDHPublicKey();
        Optional<ClientIdentifierBundle> clientIdentifierBundle = null;

        when(this.cryptographicStorageService.getServerKeyPair())
                .thenReturn(Optional.ofNullable(CryptoTestUtils.generateECDHKeyPair()));

        try {
            // When
            clientIdentifierBundle = this.keyService.deriveKeysFromClientPublicKey(clientPublicKey);
        } catch (RobertServerCryptoException e) {
            fail("Should not happen");
        }

        // Then
        assertTrue(clientIdentifierBundle.isPresent());
        assertNotNull(clientIdentifierBundle.get().getKeyForTuples());
        assertNotNull(clientIdentifierBundle.get().getKeyForMac());
    }

    /**
     * Understanding ECDH algo behavior
     */
    @Test
    void testKeyDerivationECDHTest() {

        try {
            KeyPairGenerator kpg = KeyPairGenerator.getInstance("EC");
            kpg.initialize(new ECGenParameterSpec("secp256r1"));
            KeyPair serverECDHKey = kpg.generateKeyPair();

            PrivateKey serverPrivateKey = serverECDHKey.getPrivate();
            log.info("Server private key format: {}", serverPrivateKey.getFormat());
            log.info("Server private key algorithm: {}", serverPrivateKey.getAlgorithm());
            log.info("Server private key data as hex: {}", ByteUtils.toHexString(serverPrivateKey.getEncoded()));
            log.info("Server private key data as binary: {}", ByteUtils.toBinaryString(serverPrivateKey.getEncoded()));
            log.info(ToStringBuilder.reflectionToString(serverPrivateKey, ToStringStyle.MULTI_LINE_STYLE));

            // use server public key as client public key
            PublicKey clientPublicKey = serverECDHKey.getPublic();
            log.info("Client public private key format: {}", clientPublicKey.getFormat());
            log.info("Client public key algorithm: {}", clientPublicKey.getAlgorithm());
            log.info("Client public key data as hex: {}", ByteUtils.toHexString(clientPublicKey.getEncoded()));
            log.info("Client public key data as binary: {}", ByteUtils.toBinaryString(clientPublicKey.getEncoded()));
            log.info(ToStringBuilder.reflectionToString(clientPublicKey, ToStringStyle.MULTI_LINE_STYLE));

            KeyAgreement ka = KeyAgreement.getInstance("ECDH");
            ka.init(serverPrivateKey);
            ka.doPhase(clientPublicKey, true);

            byte[] generatedSecret = ka.generateSecret();
            log.info(ToStringBuilder.reflectionToString(ka, ToStringStyle.MULTI_LINE_STYLE));
            log.info("Generated shared secret: {}", ByteUtils.toHexString(generatedSecret));

        } catch (NoSuchAlgorithmException
                | InvalidKeyException | IllegalStateException | InvalidAlgorithmParameterException e) {
            log.error("Unable to generate ECDH Keys due to {}", e.getMessage());
        }
    }
}
