package test.fr.gouv.stopc.robert.server.crypto.service.impl;

import fr.gouv.stopc.robert.server.common.utils.ByteUtils;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robert.server.crypto.RobertServerCryptoApplication;
import fr.gouv.stopc.robert.server.crypto.callable.TupleGenerator;
import fr.gouv.stopc.robert.server.crypto.model.EphemeralTuple;
import fr.gouv.stopc.robert.server.crypto.service.impl.CryptoServiceImpl;
import fr.gouv.stopc.robert.server.crypto.structure.impl.Crypto3DES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoAES;
import fr.gouv.stopc.robert.server.crypto.structure.impl.CryptoHMACSHA256;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.util.Arrays;
import java.util.Collection;
import java.util.Date;
import java.util.Random;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

@Slf4j
@ExtendWith(SpringExtension.class)
class CryptoServiceImplTest {

    private static final CryptoServiceImpl cryptoService = new CryptoServiceImpl();

    @Test
    void macHelloValidationTest() throws Exception {

        // MOCKING ENCRYPTEDKEY

        // 40 bits idA
        final byte[] idA = new byte[40 / 8];

        // Application key should be 192-bits (3 x 64-bits) long because of the TripleDES key property
        final byte[] appKey = new byte[(3 * 64) / 8];

        // Server key should be 192-bits (3 x 64-bits) long because of the TripleDES key property
        final byte[] serverKey = new byte[(3 * 64) / 8];

        // Federation key should be 256-bits long.
        final byte[] federationKey = new byte[256 / 8];

        // Hazarding idA, serverKey and federationKey keys
        Random random = new Random();
        random.nextBytes(idA);
        random.nextBytes(serverKey);
        random.nextBytes(federationKey);
        random.nextBytes(appKey);

        final CryptoServiceImpl cryptoService = new CryptoServiceImpl();
        final int currentEpoch = TimeUtils.getNumberOfEpochsBetween(0, TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime()));
        int numberOfEpochs = 4 * 24 * 4;

        final TupleGenerator tupleGenerator = new TupleGenerator(serverKey, federationKey, 50);
        final Collection<EphemeralTuple> ephemeralTuples = tupleGenerator.exec(idA, currentEpoch, numberOfEpochs, (byte) 0x33);
        tupleGenerator.stop();


        //////////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////////
        //////////////////////////// HELLO DECRYPTION ////////////////////////
        //////////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////////


        final EphemeralTuple referenceET = ephemeralTuples.iterator().next();

        System.out.println("ECC     size : " + referenceET.getEncryptedCountryCode().length * 8 + "-bits" + " " + Arrays.toString(referenceET.getEncryptedCountryCode()));
        System.out.println("EBID    size : " + referenceET.getEbid().length * 8 + "-bits" + " " + Arrays.toString(referenceET.getEbid()));
        System.out.println("EPOCH : " + referenceET.getEpoch());

        final byte[] referenceTime = new byte[2];
        random.nextBytes(referenceTime);

        final byte[] referenceMAC = new byte[5];
        random.nextBytes(referenceMAC);

        final byte[] fakeHello = ByteUtils.addAll(referenceET.getEncryptedCountryCode(), ByteUtils.addAll(referenceET.getEbid(), ByteUtils.addAll(referenceTime, referenceMAC)));

        final CryptoHMACSHA256 cryptoHMACSHA256 = new CryptoHMACSHA256(appKey);
        cryptoService.generateMACHello(cryptoHMACSHA256, fakeHello);

    }

    @Test
    public void validateHelloMessage() throws Exception {

        // MOCKING ENCRYPTEDKEY

        // 40 bits IDa
        final byte[] idA = new byte[40 / 8];

        // Application key should be 192-bits (3 x 64-bits) long because of the TripleDES key property
        final byte[] applicationKey = new byte[(3 * 64) / 8];

        // Server key should be 192-bits (3 x 64-bits) long because of the TripleDES key property
        final byte[] serverKey = new byte[(3 * 64) / 8];

        // Federation key should be 256-bits long.
        final byte[] federationKey = new byte[256 / 8];

        // Hazarding IDa, serverKey and federationKey keys
        Random random = new Random();
        random.nextBytes(idA);
        random.nextBytes(serverKey);
        random.nextBytes(federationKey);
        random.nextBytes(applicationKey);

        final CryptoServiceImpl cryptoService = new CryptoServiceImpl();
        final int currentEpoch = TimeUtils.getNumberOfEpochsBetween(0, TimeUtils.convertUnixMillistoNtpSeconds(new Date().getTime()));
        int numberOfEpochs = 4 * 24 * 4;

        final TupleGenerator tupleGenerator = new TupleGenerator(serverKey, federationKey, 50);
        final Collection<EphemeralTuple> ephemeralTuples = tupleGenerator.exec(idA, currentEpoch, numberOfEpochs, (byte) 0x33);
        tupleGenerator.stop();

        //////////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////////
        //////////////////////////// HELLO DECRYPTION ////////////////////////
        //////////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////////

        final EphemeralTuple referenceET = ephemeralTuples.iterator().next();

        System.out.println("ECC     size : " + referenceET.getEncryptedCountryCode().length * 8 + "-bits" + " " + Arrays.toString(referenceET.getEncryptedCountryCode()));
        System.out.println("EBID    size : " + referenceET.getEbid().length * 8 + "-bits" + " " + Arrays.toString(referenceET.getEbid()));
        System.out.println("EPOCH : " + referenceET.getEpoch());

        final byte[] referenceTime = new byte[2];
        random.nextBytes(referenceTime);

        final byte[] referenceMAC = new byte[5];
        random.nextBytes(referenceMAC);

        final byte[] hello = ByteUtils.addAll(referenceET.getEncryptedCountryCode(), ByteUtils.addAll(referenceET.getEbid(), ByteUtils.addAll(referenceTime, referenceMAC)));

        final Crypto3DES crypto3DES = new Crypto3DES(serverKey);
        final CryptoAES cryptoAES = new CryptoAES(federationKey);

        //Verify that the message has the right length :
        assert hello.length == (8 + 64 + 16 + 40) / 8;

        //1. parses hA
        System.out.println("------ HELLO SPLIT ------");
        final byte[] encryptedCountryCode = Arrays.copyOfRange(hello, 0, 1);
        final byte[] ebid = Arrays.copyOfRange(hello, 1, 9); // 64/8
        final byte[] time = Arrays.copyOfRange(hello, 9, 11); // 8 + 16/8
        final byte[] mac = Arrays.copyOfRange(hello, 11, 16); // 10 + 40/8
        assert encryptedCountryCode.length + ebid.length + time.length + mac.length == hello.length;
        System.out.println(Arrays.toString(encryptedCountryCode) + Arrays.toString(ebid) + Arrays.toString(time) + Arrays.toString(mac));
        System.out.println(Arrays.toString(hello));


        //2. decrypts eccA
        System.out.println("------ ECC DECRYPTED ------");
        final byte[] countryCode = this.cryptoService.decryptCountryCode(cryptoAES, ebid, encryptedCountryCode[0]);
        System.out.println("country code : " + countryCode[0]);

        // 3. computes ENC-1(KS; ebidA)
        System.out.println("------ EBID DECRYPTED ------");
        final byte[] concatIdAAndEpoch = this.cryptoService.decryptEBID(crypto3DES, ebid);
        final byte[] epoch = Arrays.copyOfRange(concatIdAAndEpoch, 0, 3); // 24/8
        final byte[] decryptedIdA = Arrays.copyOfRange(concatIdAAndEpoch, 3, concatIdAAndEpoch.length); // 24/8
        System.out.println(Arrays.toString(epoch) + Arrays.toString(decryptedIdA));
        System.out.println(Arrays.toString(concatIdAAndEpoch));

        //4. veries that idA
        // 7. retrieves from IDTable, Ka, the key associated with idA
        // TODO: call DAO here to verify that user exists and get Ka in the same time here. "one call verify and get necessary information

        // 5. checks that

        // 6. checks that time0

        // 8. verifies if the MAC, macA
        System.out.println("------ MAC VALIDATION ------");
        boolean isValid = this.cryptoService.macHelloValidation(new CryptoHMACSHA256(applicationKey), hello);
        System.out.println("mac valid : " + (isValid ? "yes" : "no"));
    }

    @Test
    void testIntToBytesConversionArrayLength() {
        int val = 123;
        byte[] valAsBytes = ByteUtils.intToBytes(val);

        assertEquals(Integer.BYTES, valAsBytes.length);
    }
}
