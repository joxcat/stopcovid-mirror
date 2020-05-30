package test.fr.gouv.stopc.robert.crypto.grpc.server.service.impl;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Arrays;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import fr.gouv.stopc.robert.crypto.grpc.server.storage.model.ClientIdentifierBundle;
//import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.ClientKeyStorageService;

@ExtendWith(SpringExtension.class)
public class ClientKeyStorageServiceTest {
//    private ClientKeyStorageService clientKeyStorageService;
//
//    @BeforeEach
//    void beforeEach() {
//        this.clientKeyStorageService = new ClientKeyStorageService();
//    }
//
//    private final static String KEY_PLACEHOLDER = "0123456789ABCDEF0123456789ABCDEF";
//
//    @Test
//    public void testCreateIdAndKeySucceeds() {
//        Optional<ClientIdentifierBundle> bundle = this.clientKeyStorageService.createClientIdUsingKeys(
//                KEY_PLACEHOLDER.getBytes(),
//                KEY_PLACEHOLDER.getBytes());
//        assertTrue(bundle.isPresent());
//
//        assertNotNull(bundle.get().getId());
//        assertNotNull(bundle.get().getKeyMac());
//        assertNotNull(bundle.get().getKeyTuples());
//        assertEquals(5, bundle.get().getId().length);
//        assertEquals(32, bundle.get().getKeyMac().length);
//        assertEquals(32, bundle.get().getKeyTuples().length);
//    }
//
//    @Test
//    public void testFindIdSucceeds() {
//        Optional<ClientIdentifierBundle> bundle = this.clientKeyStorageService.createClientIdUsingKeys(
//                KEY_PLACEHOLDER.getBytes(),
//                KEY_PLACEHOLDER.getBytes());
//        assertTrue(bundle.isPresent());
//
//        byte[] idCopy = Arrays.copyOf(bundle.get().getId(), bundle.get().getId().length);
//        Optional<ClientIdentifierBundle> found = this.clientKeyStorageService.findKeyById(idCopy);
//        assertTrue(found.isPresent());
//        assertTrue(Arrays.equals(found.get().getId(), bundle.get().getId()));
//        assertTrue(Arrays.equals(found.get().getKeyMac(), bundle.get().getKeyMac()));
//        assertTrue(Arrays.equals(found.get().getKeyTuples(), bundle.get().getKeyTuples()));
//    }
//
//    @Test
//    public void testFindNonExistentIdFails() {
//        Optional<ClientIdentifierBundle> bundle = this.clientKeyStorageService.createClientIdUsingKeys(
//                KEY_PLACEHOLDER.getBytes(),
//                KEY_PLACEHOLDER.getBytes());
//        assertTrue(bundle.isPresent());
//
//        byte[] id = bundle.get().getId();
//        id[3] = (byte)(id[3] + 1);
//        Optional<ClientIdentifierBundle> found = this.clientKeyStorageService.findKeyById(id);
//        assertTrue(!found.isPresent());
//    }
//
//    @Test
//    public void testDeleteClientIdSucceeds() {
//        Optional<ClientIdentifierBundle> bundle = this.clientKeyStorageService.createClientIdUsingKeys(
//                KEY_PLACEHOLDER.getBytes(),
//                KEY_PLACEHOLDER.getBytes());
//        assertTrue(bundle.isPresent());
//
//        this.clientKeyStorageService.deleteClientId(bundle.get().getId());
//        assertTrue(!this.clientKeyStorageService.findKeyById(bundle.get().getId()).isPresent());
//    }
}
