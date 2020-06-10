package fr.gouv.stopc.robert.server.batch.processor;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

import fr.gouv.stopc.robert.crypto.grpc.server.messaging.*;
import org.springframework.batch.item.ItemProcessor;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.client.service.ICryptoServerGrpcClient;
import fr.gouv.stopc.robert.server.batch.exception.RobertScoringException;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.batch.utils.PropertyLoader;
import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robert.server.crypto.exception.RobertServerCryptoException;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.EpochExposition;
import fr.gouv.stopc.robertserver.database.model.HelloMessageDetail;
import fr.gouv.stopc.robertserver.database.model.Registration;
import fr.gouv.stopc.robertserver.database.service.ContactService;
import fr.gouv.stopc.robertserver.database.service.IRegistrationService;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@AllArgsConstructor
public class ContactProcessor implements ItemProcessor<Contact, Contact> {

    private IServerConfigurationService serverConfigurationService;

    private IRegistrationService registrationService;

    private ContactService contactService;

    private ICryptoServerGrpcClient cryptoServerClient;

    private ScoringStrategyService scoringStrategy;

    private PropertyLoader propertyLoader;

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
            this.contactService.delete(contact);
            return null;
        }

        byte[] serverCountryCode = new byte[1];
        serverCountryCode[0] = this.serverConfigurationService.getServerCountryCode();

        Registration registration = null;
        Integer epoch = null;
        for (HelloMessageDetail helloMessageDetail : contact.getMessageDetails()) {
            GetInfoFromHelloMessageRequest request = GetInfoFromHelloMessageRequest.newBuilder()
                    .setEcc(ByteString.copyFrom(contact.getEcc()))
                    .setEbid(ByteString.copyFrom(contact.getEbid()))
                    .setTimeSent(helloMessageDetail.getTimeFromHelloMessage())
                    .setMac(ByteString.copyFrom(helloMessageDetail.getMac()))
                    .setTimeReceived(helloMessageDetail.getTimeCollectedOnDevice())
                    .build();

            // Step #8: Validate message
            Optional<GetInfoFromHelloMessageResponse> response = this.cryptoServerClient.getInfoFromHelloMessage(request);

            if (response.isPresent()) {
                GetInfoFromHelloMessageResponse helloMessageResponse = response.get();

                // Check step #2: is contact managed by this server?
                if (!Arrays.equals(helloMessageResponse.getCountryCode().toByteArray(), serverCountryCode)) {
                    log.info(
                            "Country code {} is not managed by this server ({}); rerouting contact to federation network",
                            helloMessageResponse.getCountryCode(),
                            serverCountryCode);

                    // TODO: send the message to the dedicated country server
                    // remove the message from the database
                    this.contactService.delete(contact);
                    return null;
                } else {
                    byte[] idA = helloMessageResponse.getIdA().toByteArray();
                    epoch = helloMessageResponse.getEpochId();

                    // Check step #4: check once if registration exists
                    if (Objects.isNull(registration)) {
                        Optional<Registration> registrationRecord = registrationService.findById(idA);

                        if (!registrationRecord.isPresent()) {
                            log.info("Recovered id_A is unknown (fake or now unregistered?): {}; discarding contact", idA);
                            contactService.delete(contact);
                            return null;
                        } else {
                            registration = registrationRecord.get();
                        }
                    }

                    // Check steps #5, #6
                    if (!step5CheckDeltaTaAndTimeABelowThreshold(helloMessageDetail)
                        || !step6CheckTimeACorrespondsToEpochiA(
                                helloMessageResponse.getEpochId(),
                                helloMessageDetail.getTimeCollectedOnDevice())) {
                        contactService.delete(contact);
                        return null;
                    }
                }
            } else {
                log.warn("At least one HELLO message could not be validated; discarding contact");
                this.contactService.delete(contact);
                return null;
            }
        }

        List<EpochExposition> epochsToKeep = step9ScoreAndAddContactInListOfExposedEpochs(contact, epoch, registration);
        int latestRiskEpoch = registration.getLatestRiskEpoch();

        // Only consider epochs that are after the last notification for scoring
        List<EpochExposition> scoresSinceLastNotif = CollectionUtils.isEmpty(epochsToKeep) ?
                new ArrayList<>()
                : epochsToKeep.stream()
                .filter(ep -> ep.getEpochId() > latestRiskEpoch)
                .collect(Collectors.toList());

        Double totalRisk = scoresSinceLastNotif.stream()
                .map(EpochExposition::getExpositionScores)
                .map(item -> item.stream().mapToDouble(Double::doubleValue).sum())
                .reduce(0.0, (a,b) -> a + b);

        registration.setAtRisk(totalRisk > this.propertyLoader.getRiskThreshold());

        this.registrationService.saveRegistration(registration);
        this.contactService.delete(contact);
        return null;

        // Step 1 (parsing) has already been executed

        //if (!step2CheckCountryCodeManagedByServer(contact)) return null;

        // step 3
        //EncryptedEBID encryptedEBID = new EncryptedEBID(contact).decrypt();
        //byte[] epochId = encryptedEBID.getEpochId();
        //byte[] idA = encryptedEBID.getIdA();

        //if (!step4CheckIfidAIsARegisteredUser(contact, idA, registration)) return null;

        // Scoring: discard whole contact if any HELLO message fails validation
        // Robert spec steps 5 to 8
//        if (!validateContactHelloMessages(contact, registration.get(), epochId)) {
//            contactService.delete(contact);
//            return null;
//        }

//        Registration registrationRecord = registration.get();
//
//        List<EpochExposition> epochsToKeep = step9ScoreAndAddContactInListOfExposedEpochs(contact, epochId, registrationRecord);
//        int latestRiskEpoch = registrationRecord.getLatestRiskEpoch();
//
//        // Only consider epochs that are after the last notification for scoring
//        List<EpochExposition> scoresSinceLastNotif = CollectionUtils.isEmpty(epochsToKeep) ?
//                new ArrayList<>()
//                : epochsToKeep.stream()
//                .filter(ep -> ep.getEpochId() > latestRiskEpoch)
//                .collect(Collectors.toList());
//
//        Double totalRisk = scoresSinceLastNotif.stream()
//                .map(EpochExposition::getExpositionScores)
//                .map(item -> item.stream().mapToDouble(Double::doubleValue).sum())
//                .reduce(0.0, (a,b) -> a + b);
//
//        registrationRecord.setAtRisk(totalRisk > this.serverConfigurationService.getRiskThreshold());
//
//        this.registrationService.saveRegistration(registrationRecord);
//        this.contactService.delete(contact);
//        return null;
    }

//    /**
//     * Robert spec Step #2: decrypts ECC_A, using K_G, to recover the message country code, CC_A
//     */
//    private boolean step2CheckCountryCodeManagedByServer(Contact contact) {
//        byte[] serverCountryCode = new byte [] { this.serverConfigurationService.getServerCountryCode() };
//
//        if(Stream.of(contact.getEbid(), contact.getEcc()).anyMatch(Objects::isNull)) {
//            log.info("HELLO message data inconsistency; deleting contact");
//            contactService.delete(contact);
//            return false;
//        }
//
//        DecryptCountryCodeRequest request = DecryptCountryCodeRequest.newBuilder()
//                .setEbid(ByteString.copyFrom(contact.getEbid()))
//                .setEncryptedCountryCode(ByteString.copyFrom(contact.getEcc()))
//                .build();
//
//        byte decryptedCountryCode = this.cryptoServerClient.decryptCountryCode(request);
//
//        final byte[] countryCode = new byte[] { decryptedCountryCode };
//        // Check if country codes match
//        if (!Arrays.equals(serverCountryCode, countryCode)) {
//            log.info(
//                    "Country code {} is not managed by this server ({}); rerouting contact to federation network",
//                    countryCode,
//                    serverCountryCode);
//
//            // TODO: send the message to the dedicated country server
//            // remove the message from the database
//            contactService.delete(contact);
//            return false;
//        }
//        return true;
//    }

//    /**
//     * Robert spec step 4: verifies that idA corresponds to the ID of a registered user
//     */
//    private boolean step4CheckIfidAIsARegisteredUser(Contact contact, byte[] idA, Optional<Registration> registration) {
//        // Check if id_A exists in DB
//        if (!registration.isPresent()) {
//            log.info("Recovered id_A is unknown (fake or now unregistered?): {}; discarding contact", idA);
//            contactService.delete(contact);
//            return false;
//        }
//        return true;
//    }

    /**
     *  Robert Spec Step #5: check that the delta between tA (16 bits) & timeA (32 bits) [truncated to 16bits] is below threshold.
     */
    private boolean step5CheckDeltaTaAndTimeABelowThreshold(HelloMessageDetail helloMessageDetail) {
        // Process 16-bit values for sanity check
        final long timeFromHelloNTPsecAs16bits = castIntegerToLong(helloMessageDetail.getTimeFromHelloMessage(), 2);
        final long timeFromDeviceAs16bits = castLong(helloMessageDetail.getTimeCollectedOnDevice(), 2);
        final int timeDiffTolerance = this.propertyLoader.getHelloMessageTimeStampTolerance();

        if (Math.abs(timeFromHelloNTPsecAs16bits - timeFromDeviceAs16bits) > timeDiffTolerance) {
            log.warn("Time tolerance was exceeded: |{} (HELLO) vs {} (receiving device)| > {}; discarding HELLO message",
                    timeFromHelloNTPsecAs16bits,
                    timeFromDeviceAs16bits,
                    timeDiffTolerance);
            return false;
        }
        return true;
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

    // TODO: delete comments
//    private boolean step6CheckTimeACorrespondsToEpochiA(byte[] epochId, long timeFromDevice) {
//        final int epochIdFromEBID = ByteUtils.convertEpoch24bitsToInt(epochId);
//
//        return this.step6CheckTimeACorrespondsToEpochiA(epochIdFromEBID, timeFromDevice);
//    }

//        /**
//         *  Robert Spec Step #8: verify if the MAC, macA, is valid
//         */
//    private boolean step8VerifyMACIsValid(byte[] ebid, byte[] encryptedCodeCountry, HelloMessageDetail helloMessageDetail, Registration registration) {
//        byte[] timeMessage32Bytes = ByteUtils.intToBytes(helloMessageDetail.getTimeFromHelloMessage());
//        byte[] timeMessage16Bytes = new byte[] { timeMessage32Bytes[timeMessage32Bytes.length - 2],
//                timeMessage32Bytes[timeMessage32Bytes.length - 1] };
//
//        byte[] part1 = ByteUtils.addAll(encryptedCodeCountry, ebid);
//        byte[] part2 = ByteUtils.addAll(timeMessage16Bytes, helloMessageDetail.getMac());
//
//        MacHelloValidationRequest request = MacHelloValidationRequest.newBuilder()
//                .setKa(ByteString.copyFrom(registration.getSharedKey()))
//                .setDataToValidate(ByteString.copyFrom(ByteUtils.addAll(part1, part2)))
//                .build();
//        boolean validMAC = cryptoServerClient.validateMacHello(request);
//
//        if (!validMAC) {
//            // fail silently
//            log.warn("MAC of message is invalid; discarding HELLO message");
//            return false;
//        }
//        return true;
//    }

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

        Double scoredRisk =  this.scoringStrategy.execute(contact);
        if (epochToAddTo.isPresent()) {
            List<Double> epochScores = epochToAddTo.get().getExpositionScores();
            epochScores.add(scoredRisk);
        } else {
            exposedEpochs.add(EpochExposition.builder()
                    .expositionScores(Arrays.asList(scoredRisk))
                    .epochId(epochIdFromEBID)
                    .build());
        }

        List<EpochExposition> epochsToKeep = getExposedEpochsWithoutEpochsOlderThanContagiousPeriod(exposedEpochs);
        registrationRecord.setExposedEpochs(epochsToKeep);
        return epochsToKeep;
    }

    /**
     * Keep epochs within the contagious period
     * @param exposedEpochs
     * @return
     */
    private List<EpochExposition> getExposedEpochsWithoutEpochsOlderThanContagiousPeriod(List<EpochExposition> exposedEpochs) {
        int currentEpochId = TimeUtils.getCurrentEpochFrom(this.serverConfigurationService.getServiceTimeStart());

        // Purge exposed epochs list from epochs older than contagious period (C_T)
        return CollectionUtils.isEmpty(exposedEpochs) ?
                new ArrayList<>()
                : exposedEpochs.stream().filter(epoch -> {
            int nbOfEpochsToKeep = (this.propertyLoader.getContagiousPeriod() * 24 * 3600)
                    / this.serverConfigurationService.getEpochDurationSecs();
            return (currentEpochId - epoch.getEpochId()) <= nbOfEpochsToKeep;
        }).collect(Collectors.toList());
    }

//    private boolean validateContactHelloMessages(Contact contact, Registration registration, byte[] epochId) {
//
//        if(CollectionUtils.isEmpty(contact.getMessageDetails())) {
//            log.info("Discarding contacts no HELLO messages");
//            return false;
//        }
//
//        return contact.getMessageDetails().stream()
//                .map(item -> validateHelloMessage(contact.getEbid(), contact.getEcc(), item, registration, epochId))
//                .allMatch(item -> item == true);
//    }

//    private boolean validateHelloMessage(byte[] ebid,
//                                         byte[] encryptedCodeCountry,
//                                         HelloMessageDetail helloMessageDetail,
//                                         Registration registration,
//                                         byte[] epochId) {
//        final long timeFromDevice = helloMessageDetail.getTimeCollectedOnDevice();
//        if (!step5CheckDeltaTaAndTimeABelowThreshold(helloMessageDetail)
//                || !step6CheckTimeACorrespondsToEpochiA(epochId, timeFromDevice)
//                // Step #7: retrieve from IDTable, KA, the key associated with idA
//                || !step8VerifyMACIsValid(ebid, encryptedCodeCountry, helloMessageDetail, registration)) {
//            return false;
//        }
//        return true;
//    }

//    private class EncryptedEBID {
//        private Contact contact;
//        private byte[] epochId;
//        private byte[] idA;
//
//        public EncryptedEBID(Contact contact) {
//            this.contact = contact;
//        }
//
//        public byte[] getEpochId() {
//            return epochId;
//        }
//
//        public byte[] getIdA() {
//            return idA;
//        }
//
//        public EncryptedEBID decrypt() {
//            // Step #3: decode (KS; ebidA) to retrieve iA | idA
//            DecryptEBIDRequest decryptEbidRequest = DecryptEBIDRequest.newBuilder()
//                    .setEbid(ByteString.copyFrom(contact.getEbid())).build();
//
//            final byte[] decryptedEBID = ContactProcessor.this.cryptoServerClient.decryptEBID(decryptEbidRequest);
//
//            // Get tuple epoch and ida of decrypted ebid
//            // epoch 24bits long is returned
//            epochId = new byte[4];
//            idA = new byte[5];
//            System.arraycopy(decryptedEBID, 0, epochId, 1, epochId.length - 1);
//            System.arraycopy(decryptedEBID, epochId.length - 1, idA, 0, idA.length);
//            return this;
//        }
//    }

    private long castIntegerToLong(int x, int nbOfSignificantBytes) {
        int shift = nbOfSignificantBytes * 8;
        return Integer.toUnsignedLong(x << shift >>> shift);
    }

    private long castLong(long x, int nbOfSignificantBytes) {
        int shift = (Long.BYTES - nbOfSignificantBytes) * 8;
        return x << shift >>> shift;
    }
}
