package fr.gouv.stopc.robert.server.batch;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories;

@ComponentScan(basePackages  = "fr.gouv.stopc")
@EnableMongoRepositories(basePackages = "fr.gouv.stopc")
@EnableAutoConfiguration(exclude={DataSourceAutoConfiguration.class})
@SpringBootApplication
public class RobertServerBatchApplication {

	public static void main(String[] args) {
		SpringApplication.run(RobertServerBatchApplication.class, args);
	}

}
