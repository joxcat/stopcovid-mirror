package fr.gouv.stopc.robert.server.batch.configuration;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.inject.Inject;

import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.configuration.annotation.EnableBatchProcessing;
import org.springframework.batch.core.configuration.annotation.JobBuilderFactory;
import org.springframework.batch.core.configuration.annotation.StepBuilderFactory;
import org.springframework.batch.core.configuration.annotation.StepScope;
import org.springframework.batch.core.partition.PartitionHandler;
import org.springframework.batch.core.partition.support.Partitioner;
import org.springframework.batch.core.partition.support.TaskExecutorPartitionHandler;
import org.springframework.batch.item.ItemProcessor;
import org.springframework.batch.item.ItemWriter;
import org.springframework.batch.item.data.MongoItemReader;
import org.springframework.batch.item.data.MongoItemWriter;
import org.springframework.batch.item.data.builder.MongoItemWriterBuilder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.SimpleAsyncTaskExecutor;
import org.springframework.core.task.TaskExecutor;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.Sort.Direction;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.server.batch.listener.ProcessingJobExecutionListener;
import fr.gouv.stopc.robert.server.batch.model.ItemIdMapping;
import fr.gouv.stopc.robert.server.batch.partitioner.RangePartitioner;
import fr.gouv.stopc.robert.server.batch.processor.ContactIdMappingProcessor;
import fr.gouv.stopc.robert.server.batch.processor.ContactProcessor;
import fr.gouv.stopc.robert.server.batch.processor.PurgeOldEpochExpositionsProcessor;
import fr.gouv.stopc.robert.server.batch.processor.RegistrationIdMappingProcessor;
import fr.gouv.stopc.robert.server.batch.processor.RegistrationProcessor;
import fr.gouv.stopc.robert.server.batch.service.ItemIdMappingService;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.batch.writer.ContactItemWriter;
import fr.gouv.stopc.robert.server.batch.writer.RegistrationItemWriter;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.ContactService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Configuration
@EnableBatchProcessing
public class ContactsProcessingConfiguration {

	public static final int GRID_SIZE = 10;
	public static final String TOTAL_CONTACT_COUNT_KEY = "totalContactCount";
	public static final String TOTAL_REGISTRATION_COUNT_KEY = "totalRegistrationCount";
	public static final String TOTAL_REGISTRATION_FOR_PURGE_COUNT_KEY = "totalRegistrationForPurgeCount";
	
	private final IServerConfigurationService serverConfigurationService;

	private final IRegistrationService registrationService;

	private final ContactService contactService;

	private final ScoringStrategyService scoringStrategyService;

	private final ItemIdMappingService itemIdMappingService;

	private final ICryptoServerGrpcClient cryptoServerClient;

	private final int CHUNK_SIZE = 10000;
	private final int POPULATE_STEP_CHUNK_SIZE = 200000;

	private final PropertyLoader propertyLoader;

	private final JobBuilderFactory jobBuilderFactory;

	private final StepBuilderFactory stepBuilderFactory;



	@Inject
	public ContactsProcessingConfiguration(final IServerConfigurationService serverConfigurationService,
										   final IRegistrationService registrationService,
										   final ContactService contactService,
										   final ICryptoServerGrpcClient cryptoServerClient,
										   final ScoringStrategyService scoringStrategyService,
										   final ItemIdMappingService itemIdMappingService,
										   final PropertyLoader propertyLoader,
										   final JobBuilderFactory jobBuilderFactory,
										   final StepBuilderFactory stepBuilderFactory
			) {
		
		this.serverConfigurationService = serverConfigurationService;
		this.registrationService = registrationService;
		this.contactService = contactService;
		this.cryptoServerClient = cryptoServerClient;
		this.scoringStrategyService = scoringStrategyService;
		this.itemIdMappingService = itemIdMappingService;
		this.propertyLoader =  propertyLoader;
		this.stepBuilderFactory = stepBuilderFactory;
		this.jobBuilderFactory = jobBuilderFactory;
	}

	@Bean
	public Job scoreAndProcessRisks(Step contactProcessingStep, Step processRegistrationStep, Step purgeOldEpochExpositionsStep,
									Step populateRegistrationIdMappingStep, Step populateContactIdMappingStep,
									Step populateRegistrationIdMappingForEpochPurgeStep) {

		BatchMode batchMode;

		try {
			batchMode = BatchMode.valueOf(this.propertyLoader.getBatchMode());
		} catch (IllegalArgumentException e) {
			log.error("Unrecognized batch mode {}", this.propertyLoader.getBatchMode());
			batchMode = BatchMode.NONE;
		}

		if (batchMode == BatchMode.FULL_REGISTRATION_SCAN_COMPUTE_RISK) {
			log.info("Launching registration batch (No contact scoring, risk computation)");
			return this.jobBuilderFactory.get("processRegistration")
					.listener(new ProcessingJobExecutionListener(TOTAL_REGISTRATION_COUNT_KEY,
							registrationService, contactService, serverConfigurationService,
							propertyLoader, itemIdMappingService))
					.start(populateRegistrationIdMappingStep)
					.next(processRegistrationStep).build();
		} else if (batchMode == BatchMode.SCORE_CONTACTS_AND_COMPUTE_RISK) {
			log.info("Launching contact batch (Contact scoring, Risk computation)");
			return this.jobBuilderFactory.get("processContacts")
					.listener(new ProcessingJobExecutionListener(TOTAL_CONTACT_COUNT_KEY,
							registrationService, contactService, serverConfigurationService,
							propertyLoader, itemIdMappingService))
					.start(populateContactIdMappingStep)
					.next(contactProcessingStep).build();
		} else if (batchMode == BatchMode.PURGE_OLD_EPOCH_EXPOSITIONS) {
			log.info("Launching purge old epoch exposition batch");
			return this.jobBuilderFactory.get("purgeOldEpochExpositions")
					.listener(new ProcessingJobExecutionListener(TOTAL_REGISTRATION_FOR_PURGE_COUNT_KEY,
							registrationService, contactService, serverConfigurationService,
							propertyLoader, itemIdMappingService))
					.start(populateRegistrationIdMappingForEpochPurgeStep)
					.next(purgeOldEpochExpositionsStep).build();
		}
		return null;
	}

	@Bean
	public Step populateRegistrationIdMappingStep(
			MongoItemReader<Registration> mongoRegistrationIdMappingItemReader,
			MongoItemWriter<ItemIdMapping> mongoRegistrationIdMappingItemWriter) {

		return this.stepBuilderFactory.get("populateRegistrationIdMapping").<Registration, ItemIdMapping>chunk(POPULATE_STEP_CHUNK_SIZE).reader(mongoRegistrationIdMappingItemReader)
				.processor(registrationIdMappingProcessor()).writer(mongoRegistrationIdMappingItemWriter).build();
	}

	@Bean
	public Step populateContactIdMappingStep(
			MongoItemReader<Contact> mongoContactIdMappingItemReader,
			MongoItemWriter<ItemIdMapping> mongoContactIdMappingItemWriter) {

		return this.stepBuilderFactory.get("populateContactIdMapping").<Contact, ItemIdMapping>chunk(POPULATE_STEP_CHUNK_SIZE).reader(mongoContactIdMappingItemReader)
				.processor(contactIdMappingProcessor()).writer(mongoContactIdMappingItemWriter).build();
	}

	@Bean
	public Step populateRegistrationIdMappingForEpochPurgeStep(
			MongoItemReader<Registration> mongoRegistrationIdMappingForPurgeItemReader,
			MongoItemWriter<ItemIdMapping> mongoRegistrationIdMappingItemWriter) {

		return this.stepBuilderFactory.get("populateRegistrationIdMappingForPurge").<Registration, ItemIdMapping>chunk(POPULATE_STEP_CHUNK_SIZE).reader(mongoRegistrationIdMappingForPurgeItemReader)
				.processor(registrationIdMappingProcessor()).writer(mongoRegistrationIdMappingItemWriter).build();
	}

	@Bean
	public Step contactProcessingStep(MongoItemReader<Contact> mongoContactItemReader) {
		Step workerStep = contactWorkerStep(stepBuilderFactory, mongoContactItemReader);

		return this.stepBuilderFactory.get("readContacts").partitioner("contactWorkerStep", partitioner())
				.partitionHandler(partitionHandler(workerStep))
				.build();
	}

	@Bean
	public Step processRegistrationStep(MongoItemReader<Registration> mongoRegistrationItemReader) {
		Step workerStep = registrationWorkerStep(stepBuilderFactory, mongoRegistrationItemReader);

		return this.stepBuilderFactory.get("readRegistrations").partitioner("registrationWorkerStep", partitioner())
				.partitionHandler(partitionHandler(workerStep))
				.build();
	}

	@Bean
	public Step purgeOldEpochExpositionsStep(MongoItemReader<Registration> mongoOldEpochExpositionsItemReader) {
		Step workerStep = purgeOldExpochExpositionsWorkerStep(stepBuilderFactory, mongoOldEpochExpositionsItemReader);

		return this.stepBuilderFactory.get("readRegistrationsForPurge").partitioner("purgeOldEpochExpositionsWorkerStep", partitioner())
				.partitionHandler(partitionHandler(workerStep))
				.build();
	}

	public Partitioner partitioner() {
		return new RangePartitioner();
	}


	public PartitionHandler partitionHandler(Step workerStep) {

		TaskExecutorPartitionHandler handler = new TaskExecutorPartitionHandler();
		handler.setGridSize(GRID_SIZE);
		handler.setTaskExecutor(taskExecutor());
		handler.setStep(workerStep);

		try {
			handler.afterPropertiesSet();
		} catch (Exception e) {
			log.error(e.getMessage());
		}

		return handler;
	}

	public TaskExecutor taskExecutor() {

		return new SimpleAsyncTaskExecutor();
	}

	public Step contactWorkerStep(StepBuilderFactory stepBuilderFactory, MongoItemReader<Contact> mongoItemReader) {

		return stepBuilderFactory.get("contactWorkerStep")
				.<Contact, Contact>chunk(CHUNK_SIZE)
				.reader(mongoItemReader)
				.processor(contactsProcessor())
				.writer(mongoContactItemWriter())
				.build();
	}

	public Step registrationWorkerStep(StepBuilderFactory stepBuilderFactory, MongoItemReader<Registration> mongoItemReader) {

		return stepBuilderFactory.get("registrationWorkerStep")
				.<Registration, Registration>chunk(CHUNK_SIZE)
				.reader(mongoItemReader)
				.processor(registrationsProcessor())
				.writer(mongoRegistrationItemWriter())
				.build();
	}

	public Step purgeOldExpochExpositionsWorkerStep(StepBuilderFactory stepBuilderFactory, MongoItemReader<Registration> mongoItemReader) {

		return stepBuilderFactory.get("purgeOldExpochExpositionsWorkerStep")
				.<Registration, Registration>chunk(CHUNK_SIZE)
				.reader(mongoItemReader)
				.processor(purgeOldExpositionsProcessor())
				.writer(mongoRegistrationForPurgeItemWriter())
				.build();
	}

	@Bean
	@StepScope
	public MongoItemReader<Contact> mongoContactItemReader(MongoTemplate mongoTemplate,
														   @Value("#{stepExecutionContext[name]}") final String name,
														   @Value("#{stepExecutionContext[start]}") final int start,
														   @Value("#{stepExecutionContext[end]}") final int end) {

		log.info("{} currently reading registrations from itemId collections from id={} - to id= {} ", name, start, end);

		List<String> itemIdentifiers = (List<String>)itemIdMappingService.getItemIdMappingsBetweenIds(start, end);

		Query query = new Query();
		query.addCriteria(Criteria.where("_id").in(itemIdentifiers));
		MongoItemReader<Contact> reader = new MongoItemReader<>();
		reader.setTemplate(mongoTemplate);
		reader.setTargetType(Contact.class);
		reader.setQuery(query);
		reader.setPageSize(CHUNK_SIZE);
		return reader;
	}

	@Bean
	@StepScope
	public MongoItemReader<Registration> mongoRegistrationItemReader(MongoTemplate mongoTemplate,
																	 @Value("#{stepExecutionContext[name]}") final String name,
																	 @Value("#{stepExecutionContext[start]}") final int start,
																	 @Value("#{stepExecutionContext[end]}") final int end) {
		log.info("{} currently reading registrations from itemId collections from id={} - to id= {} ", name, start, end);

		List<byte[]> itemIdentifiers = (List<byte[]>)itemIdMappingService.getItemIdMappingsBetweenIds(start, end);

		Query query = new Query();
		query.addCriteria(Criteria.where("_id").in(itemIdentifiers));
		MongoItemReader<Registration> reader = new MongoItemReader<>();
		reader.setTemplate(mongoTemplate);
		reader.setTargetType(Registration.class);
		reader.setQuery(query);
		reader.setPageSize(CHUNK_SIZE);
		return reader;
	}

	@Bean
	@StepScope
	public MongoItemReader<Registration> mongoOldEpochExpositionsItemReader(MongoTemplate mongoTemplate,
																	   @Value("#{stepExecutionContext[name]}") final String name,
																	   @Value("#{stepExecutionContext[start]}") final long start,
																	   @Value("#{stepExecutionContext[end]}") final long end) {
		log.info("{} currently reading registrations from itemId collections from id={} - to id= {} ", name, start, end);

		List<byte[]> itemIdentifiers = (List<byte[]>)itemIdMappingService.getItemIdMappingsBetweenIds(start, end);

		Query query = new Query();
		query.addCriteria(Criteria.where("_id").in(itemIdentifiers));
		MongoItemReader<Registration> reader = new MongoItemReader<>();
		reader.setTemplate(mongoTemplate);
		reader.setTargetType(Registration.class);
		reader.setQuery(query);
		reader.setPageSize(CHUNK_SIZE);
		return reader;
	}


	private Map<String, Sort.Direction> initSorts() {
		Map<String, Sort.Direction> sorts = new HashMap<>();
		sorts.put("_id", Direction.DESC);

		return sorts;
	}

	public ItemWriter<Registration> mongoRegistrationItemWriter() {
		return new RegistrationItemWriter(this.registrationService, TOTAL_REGISTRATION_COUNT_KEY);
	}

	public ItemWriter<Registration> mongoRegistrationForPurgeItemWriter() {
		return new RegistrationItemWriter(this.registrationService, TOTAL_REGISTRATION_FOR_PURGE_COUNT_KEY);
	}

	public ItemWriter<Contact> mongoContactItemWriter() {
		return new ContactItemWriter(this.contactService);
	}

	public ItemProcessor<Contact, Contact> contactsProcessor() {
		return new ContactProcessor(
				this.serverConfigurationService,
				this.registrationService,
				this.cryptoServerClient,
				this.scoringStrategyService,
				this.propertyLoader) {
		};
	}

	public ItemProcessor<Registration, Registration> registrationsProcessor() {
		return new RegistrationProcessor(
				this.serverConfigurationService,
				this.scoringStrategyService,
				this.propertyLoader) {
		};
	}

	public ItemProcessor<Registration, Registration> purgeOldExpositionsProcessor() {
		return new PurgeOldEpochExpositionsProcessor(
				this.serverConfigurationService,
				this.propertyLoader) {
		};
	}

	@Bean
	public MongoItemReader<Registration> mongoRegistrationIdMappingItemReader(MongoTemplate mongoTemplate) {

		MongoItemReader<Registration> reader = new MongoItemReader<>();

		reader.setTemplate(mongoTemplate);
		reader.setPageSize(CHUNK_SIZE);
		reader.setSort(initSorts());
		reader.setTargetType(Registration.class);
		reader.setQuery("{exposedEpochs: {$ne: []}}");

		return reader;
	}

	@Bean
	public MongoItemWriter<ItemIdMapping> mongoRegistrationIdMappingItemWriter(MongoTemplate mongoTemplate) {
		return new MongoItemWriterBuilder<ItemIdMapping>().template(mongoTemplate)
				.collection("itemIdMapping").build();
	}

	public ItemProcessor<Registration, ItemIdMapping<byte[]>> registrationIdMappingProcessor() {
		return new RegistrationIdMappingProcessor() {
		};
	}

	@Bean
	public MongoItemReader<Contact> mongoContactIdMappingItemReader(MongoTemplate mongoTemplate) {

		MongoItemReader<Contact> reader = new MongoItemReader<>();

		reader.setTemplate(mongoTemplate);
		reader.setPageSize(CHUNK_SIZE);
		reader.setSort(initSorts());
		reader.setTargetType(Contact.class);
		reader.setQuery("{}");

		return reader;
	}

	@Bean
	public MongoItemWriter<ItemIdMapping> mongoContactIdMappingItemWriter(MongoTemplate mongoTemplate) {
		return new MongoItemWriterBuilder<ItemIdMapping>().template(mongoTemplate)
				.collection("itemIdMapping").build();
	}

	public ItemProcessor<Contact, ItemIdMapping<String>> contactIdMappingProcessor() {
		return new ContactIdMappingProcessor() {
		};
	}

	@Bean
	public MongoItemReader<Registration> mongoRegistrationIdMappingForPurgeItemReader(MongoTemplate mongoTemplate) {
		int currentEpochId = TimeUtils.getCurrentEpochFrom(serverConfigurationService.getServiceTimeStart());
		int contagiousPeriod = this.propertyLoader.getContagiousPeriod();
		int minEpochId = currentEpochId - contagiousPeriod * 96;
		String query = "{exposedEpochs:{$elemMatch:{epochId:{$lte:"+minEpochId+"}}}}}";

		MongoItemReader<Registration> reader = new MongoItemReader<>();

		reader.setTemplate(mongoTemplate);
		reader.setPageSize(CHUNK_SIZE);
		reader.setSort(initSorts());
		reader.setTargetType(Registration.class);
		reader.setQuery(query);

		return reader;
	}

	private enum BatchMode {
		NONE,
		FULL_REGISTRATION_SCAN_COMPUTE_RISK,
		SCORE_CONTACTS_AND_COMPUTE_RISK,
		PURGE_OLD_EPOCH_EXPOSITIONS;
	}
}
