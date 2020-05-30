package fr.gouv.stopc.robert.crypto.grpc.server;

import java.io.IOException;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@ComponentScan(basePackages  = "fr.gouv.stopc")
@SpringBootApplication
public class RobertCryptoGrpcServerApplication {

	public static void main(String[] args) throws IOException, InterruptedException {

		SpringApplication.run(RobertCryptoGrpcServerApplication.class, args);
	
	}

}
