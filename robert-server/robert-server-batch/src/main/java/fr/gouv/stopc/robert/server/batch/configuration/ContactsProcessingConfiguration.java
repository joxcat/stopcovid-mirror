package fr.gouv.stopc.robert.server.batch.configuration;

import java.util.HashMap;
import java.util.Map;

import javax.inject.Inject;

import fr.gouv.stopc.robert.server.batch.processor.RegistrationProcessor;
import fr.gouv.stopc.robertserver.database.model.Registration;
import lombok.extern.slf4j.Slf4j;
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
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.service.ContactService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;

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

	private final PropertyLoader propertyLoader;

	private final JobBuilderFactory jobBuilderFactory;

	private final StepBuilderFactory stepBuilderFactory;



	@Inject
	public ContactsProcessingConfiguration(final IServerConfigurationService serverConfigurationService,
										   final IRegistrationService registrationService,
										   final ContactService contactService,
										   final ICryptoServerGrpcClient cryptoServerClient,
										   final ScoringStrategyService scoringStrategyService,
										   final PropertyLoader propertyLoader,
										   final JobBuilderFactory jobBuilderFactory,
										   final StepBuilderFactory stepBuilderFactory
			) {
		
		this.serverConfigurationService = serverConfigurationService;
		this.registrationService = registrationService;
		this.contactService = contactService;
		this.cryptoServerClient = cryptoServerClient;
		this.scoringStrategyService = scoringStrategyService;
		this.propertyLoader =  propertyLoader;
		this.stepBuilderFactory = stepBuilderFactory;
		this.jobBuilderFactory = jobBuilderFactory;
	}

	@Bean
	public Job scoreAndProcessRisks(Step stepContact, Step stepRegistration) {

		BatchMode batchMode;

		try {
			batchMode = BatchMode.valueOf(this.propertyLoader.getBatchMode());
		} catch (IllegalArgumentException e) {
			log.error("Unrecognized batch mode {}", this.propertyLoader.getBatchMode());
			batchMode = BatchMode.NONE;
		}

		if (batchMode == BatchMode.FULL_REGISTRATION_SCAN_COMPUTE_RISK) {
			log.info("Launching registration batch (No contact scoring, risk computation)");
			return this.jobBuilderFactory.get("processRegistration").flow(stepRegistration).end().build();
		} else if (batchMode == BatchMode.SCORE_CONTACTS_AND_COMPUTE_RISK) {
			log.info("Launching contact batch (Contact scoring, Risk computation)");
			return this.jobBuilderFactory.get("processContacts").flow(stepContact).end().build();
		}
		return null;
	}

	@Bean
	public Step stepContact(
			MongoItemReader<Contact> mongoContactItemReader,
			MongoItemWriter<Contact> mongoContactItemWriter) {

		return this.stepBuilderFactory.get("readContacts").<Contact, Contact>chunk(CHUNK_SIZE).reader(mongoContactItemReader)
					.processor(contactsProcessor()).writer(mongoContactItemWriter).build();
	}

	@Bean
	public Step stepRegistration(
			MongoItemReader<Registration> mongoRegistrationItemReader,
			MongoItemWriter<Registration> mongoRegistrationItemWriter) {

		return this.stepBuilderFactory.get("readRegistrations").<Registration, Registration>chunk(CHUNK_SIZE).reader(mongoRegistrationItemReader)
				.processor(registrationsProcessor()).writer(mongoRegistrationItemWriter).build();
	}

	@Bean
	public MongoItemReader<Contact> mongoContactItemReader(MongoTemplate mongoTemplate) {
		
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
	public MongoItemReader<Registration> mongoRegistrationItemReader(MongoTemplate mongoTemplate) {

		MongoItemReader<Registration> reader = new MongoItemReader<>();

		reader.setTemplate(mongoTemplate);

		reader.setSort(new HashMap<String, Sort.Direction>() {{

			put("_id", Direction.DESC);

		}});

		reader.setTargetType(Registration.class);

		reader.setQuery("{exposedEpochs: {$ne: []}}");
		return reader;
	}

	@Bean
	public MongoItemWriter<Contact> mongoContactItemWriter(MongoTemplate mongoTemplate) {
		Map<String, Direction> sortDirection = new HashMap<>();
		sortDirection.put("timeInsertion", Direction.DESC);
		MongoItemWriter<Contact> writer = new MongoItemWriterBuilder<Contact>().template(mongoTemplate)
				.collection("contacts_to_process").build();
		return writer;
	}

	@Bean
	public MongoItemWriter<Registration> mongoRegistrationItemWriter(MongoTemplate mongoTemplate) {
		MongoItemWriter<Registration> writer = new MongoItemWriterBuilder<Registration>().template(mongoTemplate)
				.collection("Registration").build();
		return writer;
	}

	@Bean
	public ItemProcessor<Contact, Contact> contactsProcessor() {
		return new ContactProcessor(
				this.serverConfigurationService,
				this.registrationService,
				this.contactService,
				this.cryptoServerClient,
				this.scoringStrategyService,
				this.propertyLoader) {
		};
	}

	@Bean
	public ItemProcessor<Registration, Registration> registrationsProcessor() {
		return new RegistrationProcessor(
				this.serverConfigurationService,
				this.registrationService,
				this.scoringStrategyService,
				this.propertyLoader) {
		};
	}

	private enum BatchMode {
		NONE,
		FULL_REGISTRATION_SCAN_COMPUTE_RISK,
		SCORE_CONTACTS_AND_COMPUTE_RISK;
	}
}
