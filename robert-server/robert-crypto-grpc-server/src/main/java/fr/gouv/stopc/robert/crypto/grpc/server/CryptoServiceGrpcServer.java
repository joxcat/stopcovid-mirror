package fr.gouv.stopc.robert.crypto.grpc.server;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

import javax.inject.Inject;

import org.springframework.stereotype.Service;

import fr.gouv.stopc.robert.crypto.grpc.server.service.impl.CryptoGrpcServiceImplGrpc.CryptoGrpcServiceImplImplBase;
import io.grpc.BindableService;
import io.grpc.Server;
import io.grpc.ServerBuilder;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class CryptoServiceGrpcServer {

	private int port;
	private Server server;

	private CryptoGrpcServiceImplImplBase service;
	
	@Inject
	public CryptoServiceGrpcServer(final CryptoGrpcServiceImplImplBase service) {
		this.service = service;
	}
	
	public CryptoServiceGrpcServer(int port) {
		this(ServerBuilder.forPort(port), port);
	}
	
	public CryptoServiceGrpcServer(ServerBuilder<?> serverBuilder, int port) {
		this.server = serverBuilder.addService(service).build();
		this.port = port;

	}

	public CryptoServiceGrpcServer(ServerBuilder<?> serverBuilder, int port, BindableService cryptoService) {
		this.server = serverBuilder
				.addService(cryptoService)
				.build();
		this.port = port;

	}

	public void initPort(int port) {
		this.port = port;
		this.server = ServerBuilder.forPort(port).addService(service).build();
	}
	public void start() throws IOException {
		server.start();
		log.info("Server started, listening on " + port);
	}

	/** Stop serving requests and shutdown resources. */
	public void stop() throws InterruptedException {
		if (server != null) {
			server.shutdown().awaitTermination(30, TimeUnit.SECONDS);
		}
	}

	/**
	 * Await termination on the main thread since the grpc library uses daemon threads.
	 */
	public void blockUntilShutdown() throws InterruptedException {
		if (server != null) {
			server.awaitTermination();
		}
	}
}
