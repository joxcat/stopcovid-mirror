package fr.gouv.stopc.robert.crypto.grpc.server.storage.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.security.PublicKey;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class ClientIdentifierBundle {

    private byte[] id;
    private byte[] keyForMac;
    private byte[] keyForTuples;

}
