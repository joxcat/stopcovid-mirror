package test.fr.gouv.stopc.robert.server.common.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.HashMap;

import org.bson.internal.Base64;
import org.junit.jupiter.api.Test;

import fr.gouv.stopc.robert.server.common.service.impl.ServerConfigurationServiceImpl;

class ServerConfigurationServiceImplTest {

    @Test
    public void instantiationTest() {

        final HashMap<String, Integer> federationMap = new HashMap<>();
        final HashMap<String, Integer> serverMap = new HashMap<>();
        int numIter = 10;
        for (int i = 0; i < numIter; i++) {
            final ServerConfigurationServiceImpl keyService = new ServerConfigurationServiceImpl();

            // Federation key should be 256-bits long
            final byte[] fakeFederationKey = keyService.getFederationKey();
            String federationKeyAsBase64 = Base64.encode(fakeFederationKey);
            System.out.println(federationKeyAsBase64);
            federationMap.put(federationKeyAsBase64, i);
            assertEquals(fakeFederationKey.length, 256/8);

            // Server key should be 192-bits long
            final byte[] fakeServerKey = keyService.getServerKey();
            String serverKeyAsBase64 = Base64.encode(fakeServerKey);
            System.out.println(serverKeyAsBase64);
            serverMap.put(serverKeyAsBase64, i);
            assertEquals(fakeServerKey.length, 192/8);

        }

        // if it is every time the same value is just replace in map
        assertEquals(federationMap.size(), 1);
        assertEquals(serverMap.size(), 1);
    }
}
