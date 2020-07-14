package fr.gouv.stopc.robertserver.dataset.injector;

import fr.gouv.stopc.robertserver.dataset.injector.service.InjectorDataSetService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories;

@SpringBootApplication
@ComponentScan(basePackages  = "fr.gouv.stopc")
@EntityScan(basePackages  = "fr.gouv.stopc")
@EnableMongoRepositories(basePackages = "fr.gouv.stopc.robertserver.database.repository")
@EnableAutoConfiguration
@EnableJpaRepositories(basePackages ="fr.gouv.stopc.robert.crypto.grpc.server.storage.database.repository")
@Slf4j
public class RobertServerInjectorDatasetApplication {

	@Autowired
	private InjectorDataSetService injectorDataSetService;

	public static void main(String[] args) {
		ConfigurableApplicationContext cac = SpringApplication.run(RobertServerInjectorDatasetApplication.class, args);
		InjectorDataSetService bean = cac.getBean(InjectorDataSetService.class);

		if(isArgListValid(args)) {
			if ("contact".equalsIgnoreCase(args[0])) {
				bean.injectContacts(Integer.valueOf(args[1]));
			} else if ("registration".equalsIgnoreCase(args[0])){
				bean.injectRegistrations(Integer.valueOf(args[1]));
			}
		} else{
			log.error("Usage args   : <contact or registration> <number of element>");
			log.error("Example 1 : contact 1000");
			log.error("Example 2 : registration 100000");
		}
	}

	private static boolean isArgListValid(String[] args){
		boolean isArgListValid = false;

		if(args.length == 2 && ("contact".equals(args[0]) || "registration".equals(args[0]))){
			try {
				Integer.valueOf(args[1]);
				isArgListValid = true;
			} catch (NumberFormatException e){
				log.error("Error : the second argument must be a number.");
			}
		}
		return isArgListValid;
	}
}

