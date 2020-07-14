package fr.gouv.stopc.robert.server.batch.processor;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

import org.springframework.batch.item.ItemProcessor;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetInfoFromHelloMessageRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.messaging.GetInfoFromHelloMessageResponse;
import fr.gouv.stopc.robert.server.batch.exception.RobertScoringException;
import fr.gouv.stopc.robert.server.batch.model.ScoringResult;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.batch.utils.ScoringUtils;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.HelloMessageDetail;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class ContactProcessor implements ItemProcessor<Contact, Contact> {

    private IServerConfigurationService serverConfigurationService;

    private IRegistrationService registrationService;

    private ICryptoServerGrpcClient cryptoServerClient;

    private ScoringStrategyService scoringStrategy;

    private PropertyLoader propertyLoader;

    private int nbToBeProcessed;

    private int nbToBeDiscarded;


    public ContactProcessor(
            final IServerConfigurationService serverConfigurationService,
            final IRegistrationService registrationService,
             final ICryptoServerGrpcClient cryptoServerClient,
            final ScoringStrategyService scoringStrategy,
            final PropertyLoader propertyLoader) {

        this.serverConfigurationService = serverConfigurationService;
        this.registrationService = registrationService;
         this.cryptoServerClient = cryptoServerClient;
        this.scoringStrategy = scoringStrategy;
        this.propertyLoader = propertyLoader;
    }


    /**
     * NOTE:
     * validation step order has evolved from spec because of delegation of validation of messages to crypto back-end
     * @param contact
     * @return
     * @throws RobertServerCryptoException
     * @throws RobertScoringException
     */
    @Override
    public Contact process(Contact contact) throws RobertServerCryptoException, RobertScoringException {
        log.info("Contact processing started");

        if (CollectionUtils.isEmpty(contact.getMessageDetails())) {
            log.warn("No messages in contact; discarding contact");
            return contact;
        }

        byte[] serverCountryCode = new byte[1];
        serverCountryCode[0] = this.serverConfigurationService.getServerCountryCode();
        List<HelloMessageDetail> toBeDiscarded = new ArrayList<>();

        Registration registration = null;
        Integer epoch = null;
        this.nbToBeProcessed = contact.getMessageDetails().size();

        log.info("{} HELLO message(s) to process", this.nbToBeProcessed);
        for (HelloMessageDetail helloMessageDetail : contact.getMessageDetails()) {
            GetInfoFromHelloMessageRequest request = GetInfoFromHelloMessageRequest.newBuilder()
                    .setEcc(ByteString.copyFrom(contact.getEcc()))
                    .setEbid(ByteString.copyFrom(contact.getEbid()))
                    .setTimeSent(helloMessageDetail.getTimeFromHelloMessage())
                    .setMac(ByteString.copyFrom(helloMessageDetail.getMac()))
                    .setTimeReceived(helloMessageDetail.getTimeCollectedOnDevice())
                    .setServerCountryCode(ByteString.copyFrom(new byte[] { this.serverConfigurationService.getServerCountryCode() }))
                    .build();

            // Step #8: Validate message
            Optional<GetInfoFromHelloMessageResponse> response = this.cryptoServerClient.getInfoFromHelloMessage(request);

            if (response.isPresent()) {
                GetInfoFromHelloMessageResponse helloMessageResponse = response.get();

                if(helloMessageResponse.hasError() && Objects.nonNull(helloMessageResponse.getError()) &&
                        helloMessageResponse.getError().getCode() > 0) {
                    log.error("{}, discarding the hello message", helloMessageResponse.getError().getDescription());
                    toBeDiscarded.add(helloMessageDetail);
                }
                // Check step #2: is contact managed by this server?
                if (!Arrays.equals(helloMessageResponse.getCountryCode().toByteArray(), serverCountryCode)) {
                    log.info(
                            "Country code {} is not managed by this server ({}); rerouting contact to federation network",
                            helloMessageResponse.getCountryCode(),
                            serverCountryCode);

                    // TODO: send the message to the dedicated country server
                    // remove the message from the database
                    return contact;
                } else {
                    byte[] idA = helloMessageResponse.getIdA().toByteArray();
                    epoch = helloMessageResponse.getEpochId();

                    // Check step #4: check once if registration exists
                    if (Objects.isNull(registration)) {
                        Optional<Registration> registrationRecord = registrationService.findById(idA);

                        if (!registrationRecord.isPresent()) {
                            log.info("Recovered id_A is unknown (fake or now unregistered?): {}; discarding contact", idA);
                            return contact;
                        } else {
                            registration = registrationRecord.get();
                        }
                    }

                    // Check steps #5, #6
                    if (!step5CheckDeltaTaAndTimeABelowThreshold(helloMessageDetail)
                        || !step6CheckTimeACorrespondsToEpochiA(
                                helloMessageResponse.getEpochId(),
                                helloMessageDetail.getTimeCollectedOnDevice())) {
                        toBeDiscarded.add(helloMessageDetail);
                    }
                }
            } else {
                log.warn("The HELLO message could not be validated; discarding it");
                toBeDiscarded.add(helloMessageDetail);
            }
        }

        this.removeInvalidHelloMessages(contact, toBeDiscarded);
        if (CollectionUtils.isEmpty(contact.getMessageDetails())) {
            log.warn("Contact did not contain any valid messages; discarding contact");
            this.displayStatus();
            return contact;
        }

        List<EpochExposition> epochsToKeep = step9ScoreAndAddContactInListOfExposedEpochs(contact, epoch, registration);

        ScoringUtils.updateRegistrationIfRisk(
                registration,
                epochsToKeep,
                this.serverConfigurationService.getServiceTimeStart(),
                this.propertyLoader.getRiskThreshold(),
                this.scoringStrategy
        );

        this.registrationService.saveRegistration(registration);

        this.displayStatus();

        return contact;
    }

    /**
     *  Robert Spec Step #5: check that the delta between tA (16 bits) & timeA (32 bits) [truncated to 16bits] is below threshold.
     */
    private boolean step5CheckDeltaTaAndTimeABelowThreshold(HelloMessageDetail helloMessageDetail) {
        // Process 16-bit values for sanity check
        final long timeFromHelloNTPsecAs16bits = castIntegerToLong(helloMessageDetail.getTimeFromHelloMessage(), 2);
        final long timeFromDeviceAs16bits = castLong(helloMessageDetail.getTimeCollectedOnDevice(), 2);
        final int timeDiffTolerance = this.propertyLoader.getHelloMessageTimeStampTolerance();

        if (TimeUtils.toleranceCheckWithWrap(timeFromHelloNTPsecAs16bits, timeFromDeviceAs16bits, timeDiffTolerance)) {
            return true;
        }

        log.warn("Time tolerance was exceeded: |{} (HELLO) vs {} (receiving device)| > {}; discarding HELLO message",
                timeFromHelloNTPsecAs16bits,
                timeFromDeviceAs16bits,
                timeDiffTolerance);
        return false;
    }



    /**
     *  Robert Spec Step #6
     */
    private boolean step6CheckTimeACorrespondsToEpochiA(int epochId, long timeFromDevice) {
        final long tpstStartNTPsec = this.serverConfigurationService.getServiceTimeStart();
        long epochIdFromMessage = TimeUtils.getNumberOfEpochsBetween(tpstStartNTPsec, timeFromDevice);

        // Check if epochs match with a limited tolerance
        if (Math.abs(epochIdFromMessage - epochId) > 1) {
            log.warn("Epochid from message {}  vs epochid from ebid  {} > 1 (tolerance); discarding HELLO message",
                    epochIdFromMessage,
                    epochId);
            return false;
        }
        return true;
    }

    /**
     * Robert spec Step #9: add i_A in LEE_A
     */
    private List<EpochExposition> step9ScoreAndAddContactInListOfExposedEpochs(Contact contact, int epochIdFromEBID, Registration registrationRecord) throws RobertScoringException {
        List<EpochExposition> exposedEpochs = registrationRecord.getExposedEpochs();

        // Exposed epochs should be empty, never null
        if (Objects.isNull(exposedEpochs)) {
            exposedEpochs = new ArrayList<>();
        }

        // Add EBID's epoch to exposed epochs list
        Optional<EpochExposition> epochToAddTo = exposedEpochs.stream()
                .filter(item -> item.getEpochId() == epochIdFromEBID)
                .findFirst();

        ScoringResult scoredRisk =  this.scoringStrategy.execute(contact);
        if (epochToAddTo.isPresent()) {
            List<Double> epochScores = epochToAddTo.get().getExpositionScores();
            epochScores.add(scoredRisk.getRssiScore());
        } else {
            exposedEpochs.add(EpochExposition.builder()
                    .expositionScores(Arrays.asList(scoredRisk.getRssiScore()))
                    .epochId(epochIdFromEBID)
                    .build());
        }

        int currentEpochId = TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart());
        List<EpochExposition> epochsToKeep = ScoringUtils.getExposedEpochsWithoutEpochsOlderThanContagiousPeriod(
                exposedEpochs,
                currentEpochId,
                this.propertyLoader.getContagiousPeriod(),
                this.serverConfigurationService.getEpochDurationSecs());
        registrationRecord.setExposedEpochs(epochsToKeep);
        return epochsToKeep;
    }

    private void removeInvalidHelloMessages(final Contact contact,final List<HelloMessageDetail> toBeDiscarded) {
        Optional.ofNullable(contact)
        .filter(processedContact -> !CollectionUtils.isEmpty(processedContact.getMessageDetails()))
        .filter(processedContact -> !CollectionUtils.isEmpty(toBeDiscarded))
        .ifPresent(processingContact -> {
            List<HelloMessageDetail> receivedHelloMessage =  new ArrayList<>(processingContact.getMessageDetails());
            this.nbToBeDiscarded = toBeDiscarded.size();
            toBeDiscarded.stream().forEach(helloMessage -> {
                int index = receivedHelloMessage.indexOf(helloMessage);
                receivedHelloMessage.remove(index);
            });
            contact.setMessageDetails(receivedHelloMessage);
        });
    }

    private void displayStatus() {
        log.info("{} HELLO message(s) discarded", this.nbToBeDiscarded);
        log.info("{} HELLO message(s) successfull processed", (this.nbToBeProcessed - this.nbToBeDiscarded));
    }

    private long castIntegerToLong(int x, int nbOfSignificantBytes) {
        int shift = nbOfSignificantBytes * 8;
        return Integer.toUnsignedLong(x << shift >>> shift);
    }

    private long castLong(long x, int nbOfSignificantBytes) {
        int shift = (Long.BYTES - nbOfSignificantBytes) * 8;
        return x << shift >>> shift;
    }

}
