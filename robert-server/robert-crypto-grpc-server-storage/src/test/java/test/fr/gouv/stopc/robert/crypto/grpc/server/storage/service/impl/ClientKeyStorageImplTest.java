package test.fr.gouv.stopc.robert.crypto.grpc.server.storage.service.impl;

import fr.gouv.stopc.robert.crypto.grpc.server.storage.cryptographic.service.ICryptographicStorageService;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.database.model.ClientIdentifier;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.database.repository.ClientIdentifierRepository;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.model.ClientIdentifierBundle;
import fr.gouv.stopc.robert.crypto.grpc.server.storage.service.impl.ClientKeyStorageServiceImpl;
import org.bson.internal.Base64;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.springframework.data.domain.Example;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import javax.crypto.spec.SecretKeySpec;

import java.security.SecureRandom;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(SpringExtension.class)

public class ClientKeyStorageImplTest {

    @Mock
    ICryptographicStorageService cryptographicStorageService;

    ClientKeyStorageServiceImpl clientKeyStorageService;

    MockClientIdentifierRepository mockClientIdentifierRepository;

    @BeforeEach
    void beforeEach() {
        this.mockClientIdentifierRepository = new MockClientIdentifierRepository();

        this.clientKeyStorageService = new ClientKeyStorageServiceImpl(cryptographicStorageService, mockClientIdentifierRepository);
        this.mockClientIdentifierRepository.clearLastSavedClientIdentifier();

        when(this.cryptographicStorageService.getKeyForEncryptingClientKeys()).thenReturn(new SecretKeySpec(generateKey(), "AES"));
    }

    private byte[] generateKey() {
        byte[] key = new byte[32];
        new SecureRandom().nextBytes(key);
        return key;
    }

    @Test
    void testCreateClientIdUsingKeysSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundle = this.clientKeyStorageService.createClientIdUsingKeys(generateKey(), generateKey());

        assertTrue(clientIdentifierBundle.isPresent());

        Optional<ClientIdentifierBundle> clientIdentifierBundle1 = this.clientKeyStorageService.findKeyById(clientIdentifierBundle.get().getId());
        assertTrue(Arrays.equals(clientIdentifierBundle1.get().getKeyForMac(), clientIdentifierBundle.get().getKeyForMac()));
    }

    @Test
    void testCreateTwoClientIdsAndKeysDifferSucceeds() {
        Optional<ClientIdentifierBundle> clientIdentifierBundleWithDecryptedKeys1 = this.clientKeyStorageService.createClientIdUsingKeys(generateKey(), generateKey());
        assertTrue(clientIdentifierBundleWithDecryptedKeys1.isPresent());
        ClientIdentifier encryptedClientIdentifierWithEncryptedKeys1 = this.mockClientIdentifierRepository.getLastSavedClientIdentifier();

        this.mockClientIdentifierRepository.clearLastSavedClientIdentifier();
        Optional<ClientIdentifierBundle> clientIdentifierBundle2 = this.clientKeyStorageService.createClientIdUsingKeys(generateKey(), generateKey());
        assertTrue(clientIdentifierBundle2.isPresent());
        ClientIdentifier encryptedClientIdentifier2 = this.mockClientIdentifierRepository.getLastSavedClientIdentifier();

        assertNotEquals(encryptedClientIdentifierWithEncryptedKeys1.getIdA(), encryptedClientIdentifier2.getIdA());
        assertNotEquals(encryptedClientIdentifierWithEncryptedKeys1.getKeyForMac(), encryptedClientIdentifier2.getKeyForMac());
        assertNotEquals(encryptedClientIdentifierWithEncryptedKeys1.getKeyForTuples(), encryptedClientIdentifier2.getKeyForTuples());
    }

    private class MockClientIdentifierRepository implements ClientIdentifierRepository {

        private ClientIdentifier lastSavedClientIdentifier;

        public ClientIdentifier getLastSavedClientIdentifier() {
            return this.lastSavedClientIdentifier;
        }
        public void clearLastSavedClientIdentifier() { this.lastSavedClientIdentifier = null; }

        @Override
        public <S extends ClientIdentifier> S saveAndFlush(S s) {
           return save(s);
        }

        @Override
        public Optional<ClientIdentifier> findByIdA(String idA) {
            return Optional.ofNullable(this.lastSavedClientIdentifier);
        }

        @Override
        public List<ClientIdentifier> findAll() {
            return null;
        }

        @Override
        public List<ClientIdentifier> findAll(Sort sort) {
            return null;
        }

        @Override
        public Page<ClientIdentifier> findAll(Pageable pageable) {
            return null;
        }

        @Override
        public List<ClientIdentifier> findAllById(Iterable<Long> iterable) {
            return null;
        }

        @Override
        public long count() {
            return 0;
        }

        @Override
        public void deleteById(Long aLong) {

        }

        @Override
        public void delete(ClientIdentifier clientIdentifier) {

        }

        @Override
        public void deleteAll(Iterable<? extends ClientIdentifier> iterable) {

        }

        @Override
        public void deleteAll() {

        }

        @Override
        public <S extends ClientIdentifier> Optional<S> findOne(Example<S> example) {
            return Optional.empty();
        }

        @Override
        public <S extends ClientIdentifier> Page<S> findAll(Example<S> example, Pageable pageable) {
            return null;
        }

        @Override
        public <S extends ClientIdentifier> long count(Example<S> example) {
            return 0;
        }

        @Override
        public <S extends ClientIdentifier> boolean exists(Example<S> example) {
            return false;
        }

        @Override
        public <S extends ClientIdentifier> S save(S s) {
            this.lastSavedClientIdentifier = s;
            return s;
        }

        @Override
        public <S extends ClientIdentifier> List<S> saveAll(Iterable<S> iterable) {
            return null;
        }

        @Override
        public Optional<ClientIdentifier> findById(Long aLong) {
            return Optional.empty();
        }

        @Override
        public boolean existsById(Long aLong) {
            return false;
        }

        @Override
        public void flush() {

        }

        @Override
        public void deleteInBatch(Iterable<ClientIdentifier> iterable) {

        }

        @Override
        public void deleteAllInBatch() {

        }

        @Override
        public ClientIdentifier getOne(Long aLong) {
            return null;
        }

        @Override
        public <S extends ClientIdentifier> List<S> findAll(Example<S> example) {
            return null;
        }

        @Override
        public <S extends ClientIdentifier> List<S> findAll(Example<S> example, Sort sort) {
            return null;
        }
    }
}