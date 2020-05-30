package test.fr.gouv.stopc.robert.crypto.grpc.server.utils;

import java.security.*;
import java.security.spec.ECGenParameterSpec;

import lombok.extern.slf4j.Slf4j;

import javax.crypto.spec.DHGenParameterSpec;

@Slf4j
public final class CryptoTestUtils {

    private CryptoTestUtils() {
        throw new AssertionError();
    }

    public static byte[] generateECDHPublicKey() {
        return generateECDHPublicKey("secp256r1");
    }

    public static byte[] generateECDHPublicKey(String ecSpec) {
        KeyPair keyPair = generateECDHKeyPair(ecSpec);

        return keyPair == null ? null : keyPair.getPublic().getEncoded();
    }

    public static KeyPair generateECDHKeyPair() {
        return generateECDHKeyPair("secp256r1");
    }

    public static KeyPair generateECDHKeyPair(String ecSpec) {
        try {
            // Generate ephemeral ECDH keypair
            KeyPairGenerator kpg;
            kpg = KeyPairGenerator.getInstance("EC");
            kpg.initialize(new ECGenParameterSpec(ecSpec));
            KeyPair keyPair = kpg.generateKeyPair();

            return keyPair;

        } catch (NoSuchAlgorithmException | IllegalStateException | InvalidAlgorithmParameterException e) {
            log.error("Unable to generate ECDH public key", e.getMessage());
        }

        return null;
    }

    public static byte[] generateDHPublicKey() {
        try {
            KeyPairGenerator kpg;
            kpg = KeyPairGenerator.getInstance("DH");
            kpg.initialize(1024, new SecureRandom());
            KeyPair keyPair = kpg.generateKeyPair();

            return keyPair.getPublic().getEncoded();

        } catch (NoSuchAlgorithmException | IllegalStateException  e) {
            log.error("Unable to generate DH public key", e.getMessage());
        }

        return null;
    }

}
