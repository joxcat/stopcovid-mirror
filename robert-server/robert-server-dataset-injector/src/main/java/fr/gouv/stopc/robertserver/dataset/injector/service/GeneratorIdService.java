package fr.gouv.stopc.robertserver.dataset.injector.service;

import java.security.Key;

public interface GeneratorIdService {

    byte[] generateIdA();

    byte[] decryptStoredKeyWithAES256GCMAndKek(byte[] storedKey, Key kek);
}
