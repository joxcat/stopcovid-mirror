package fr.gouv.stopc.robert.crypto.grpc.server.service;

import java.util.Optional;

import fr.gouv.stopc.robert.crypto.grpc.server.storage.model.ClientIdentifierBundle;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;

public interface IECDHKeyService {
    Optional<ClientIdentifierBundle> deriveKeysFromClientPublicKey(byte[] clientPublicKey) throws RobertServerCryptoException;
}
