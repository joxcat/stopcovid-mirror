package fr.gouv.stopc.robert.server.batch.configuration;

import java.util.HashMap;
import java.util.Map;

import javax.inject.Inject;

import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.configuration.annotation.EnableBatchProcessing;
import org.springframework.batch.core.configuration.annotation.JobBuilderFactory;
import org.springframework.batch.core.configuration.annotation.StepBuilderFactory;
import org.springframework.batch.item.ItemProcessor;
import org.springframework.batch.item.data.MongoItemReader;
import org.springframework.batch.item.data.MongoItemWriter;
import org.springframework.batch.item.data.builder.MongoItemWriterBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.Sort.Direction;
import org.springframework.data.mongodb.core.MongoTemplate;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.server.batch.processor.ContactProcessor;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.service.ContactService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Configuration
@EnableBatchProcessing
public class ContactsProcessingConfiguration {
	
	private final IServerConfigurationService serverConfigurationService;

	private final IRegistrationService registrationService;

	private final ContactService contactService;

	private final ScoringStrategyService scoringStrategyService;

	private final ICryptoServerGrpcClient cryptoServerClient;

	private final int CHUNK_SIZE = 10000;
	
	@Inject
	public ContactsProcessingConfiguration(final IServerConfigurationService serverConfigurationService,
										   final IRegistrationService registrationService,
										   final ContactService contactService,
										   final ICryptoServerGrpcClient cryptoServerClient,
										   final ScoringStrategyService scoringStrategyService
			) {
		
		this.serverConfigurationService = serverConfigurationService;
		this.registrationService = registrationService;
		this.contactService = contactService;
		this.cryptoServerClient = cryptoServerClient;
		this.scoringStrategyService = scoringStrategyService;

	}

	@Bean
	public Job readReport(JobBuilderFactory jobBuilderFactory, Step step) {
		return jobBuilderFactory.get("processContacts").flow(step).end().build();
	}

	@Bean
	public Step step(StepBuilderFactory stepBuilderFactory, MongoItemReader<Contact> mongoItemReader,
			MongoItemWriter<Contact> mongoItemWriter, IServerConfigurationService serverConfigurationService) {
		return stepBuilderFactory.get("read").<Contact, Contact>chunk(CHUNK_SIZE).reader(mongoItemReader)
				.processor(contactsProcessor()).writer(mongoItemWriter).build();
	}

	@Bean
	public MongoItemReader<Contact> mongoItemReader(MongoTemplate mongoTemplate) {
		
	    MongoItemReader<Contact> reader = new MongoItemReader<>();

	    reader.setTemplate(mongoTemplate);

	    reader.setSort(new HashMap<String, Sort.Direction>() {{

	      put("_id", Direction.DESC);

	    }});

	    reader.setTargetType(Contact.class);

	    reader.setQuery("{}");
		return reader;
	}

	@Bean
	public MongoItemWriter<Contact> mongoItemWriter(MongoTemplate mongoTemplate) {
		Map<String, Direction> sortDirection = new HashMap<>();
		sortDirection.put("timeInsertion", Direction.DESC);
		MongoItemWriter<Contact> writer = new MongoItemWriterBuilder<Contact>().template(mongoTemplate)
				.collection("contacts_to_process").build();
		return writer;
	}

	@Bean
	public ItemProcessor<Contact, Contact> contactsProcessor() {
		return new ContactProcessor(
				this.serverConfigurationService,
				this.registrationService,
				this.contactService,
				this.cryptoServerClient,
				this.scoringStrategyService) {
		};
	}
}
