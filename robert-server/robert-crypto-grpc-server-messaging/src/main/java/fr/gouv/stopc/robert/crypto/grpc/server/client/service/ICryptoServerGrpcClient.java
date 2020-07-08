package fr.gouv.stopc.robert.crypto.grpc.server.client.service;

import java.util.Optional;

import fr.gouv.stopc.robert.crypto.grpc.server.messaging.*;


public interface ICryptoServerGrpcClient {

	void init(String host, int port);

	Optional<GetIdFromStatusResponse> getIdFromStatus(GetIdFromStatusRequest request);

	Optional<GetIdFromAuthResponse> getIdFromAuth(GetIdFromAuthRequest request);

	Optional<CreateRegistrationResponse> createRegistration(CreateRegistrationRequest request);

	Optional<GetInfoFromHelloMessageResponse> getInfoFromHelloMessage(GetInfoFromHelloMessageRequest request);

	Optional<DeleteIdResponse> deleteId(DeleteIdRequest request);

}
