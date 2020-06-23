package test.fr.gouv.stopc.robertserver.batch.scoring;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.mongo.embedded.EmbeddedMongoAutoConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ContextConfiguration;

import com.opencsv.CSVReader;
import com.opencsv.exceptions.CsvException;

import fr.gouv.stopc.robert.server.batch.RobertServerBatchApplication;
import fr.gouv.stopc.robert.server.batch.exception.RobertScoringException;
import fr.gouv.stopc.robert.server.batch.service.ScoringStrategyService;
import fr.gouv.stopc.robert.server.batch.model.ScoringResult;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.database.model.HelloMessageDetail;
import lombok.extern.slf4j.Slf4j;

import static org.junit.jupiter.api.Assertions.*;

@Slf4j
@ContextConfiguration(classes = RobertServerBatchApplication.class)
@EnableAutoConfiguration(exclude = EmbeddedMongoAutoConfiguration.class)
@SpringBootTest(properties = "robert.scoring.algo-version=2")
public class ScoringAlgorithmV2Test {

    @Autowired
    private ScoringStrategyService serviceScoring;

    @Test
    public void test_C4_20_A() {
        String directory = "input_v2/C4_20_A";

        List<ScoringResult> expectedOutput = new ArrayList<>();
        expectedOutput.add(ScoringResult.builder().rssiScore(0.11556942265181178).duration(8).nbContacts(4).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.3229067671860443).duration(5).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(1.0).duration(8).nbContacts(9).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.941392043740963).duration(5).nbContacts(6).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(1.0).duration(7).nbContacts(4).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.35967921691503046).duration(5).nbContacts(6).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.7564266561578571).duration(8).nbContacts(9).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(1.0).duration(3).nbContacts(4).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(1.0).duration(11).nbContacts(8).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.057754450877641854).duration(5).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.39818091219734414).duration(5).nbContacts(6).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.009797860399408692).duration(5).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.26874716417803873).duration(5).nbContacts(4).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.03702302713136917).duration(8).nbContacts(5).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.42720215504342757).duration(8).nbContacts(9).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.10028595878253897).duration(8).nbContacts(5).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.06408216875196332).duration(5).nbContacts(6).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.07546335918764831).duration(8).nbContacts(8).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(5).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.005495250780545454).duration(5).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.006556325324440052).duration(5).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.016607740845802552).duration(8).nbContacts(4).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.041219350276851696).duration(8).nbContacts(5).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.004171986838835206).duration(5).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(5).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.02539924468717017).duration(5).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(5).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.18147692305337412).duration(5).nbContacts(6).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.08987367221784223).duration(5).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.004784906247089645).duration(8).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.12421508579978256).duration(8).nbContacts(6).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.13711138208459778).duration(5).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.01615483358205426).duration(9).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.6940357271487697).duration(14).nbContacts(7).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.7249324561015698).duration(0).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.15590766159792765).duration(8).nbContacts(5).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(7).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(5).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.3354095835431747).duration(3).nbContacts(4).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(4.285074627067092E-4).duration(8).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(5).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(5).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(5).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(5).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(5).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(1.0).duration(5).nbContacts(6).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(1.0).duration(8).nbContacts(9).build());

        for (ScoringResult scoringResult : expectedOutput) {
            double rssiScore= scoringResult.getRssiScore() * scoringResult.getDuration();
            log.info("rssi score: {}", rssiScore);
            scoringResult.setRssiScore(rssiScore);
        }

        launchTestsOnDirectoryAndExpectOutput(directory, expectedOutput, 0.43701722115091);
    }

    private List<Contact> retrieveContacts(String dir) throws URISyntaxException, IOException, CsvException {
        List<Contact> contacts = new ArrayList<>();
        File[] files = new File(getClass().getClassLoader().getResource(dir).toURI()).listFiles();
        List<File> sortedFiles2 = Arrays.asList(files).stream().sorted(Comparator.comparing(File::getName)).collect(Collectors.toList());
        for (File input : sortedFiles2) {
            // Read the current file corresponding to a contact
            CSVReader reader = new CSVReader(new FileReader(input));
            // Skip the header
            reader.skip(1);
            List<String[]> lines = reader.readAll();
            // Each line is a HelloMessageDetail
            List<HelloMessageDetail> hellos = lines.stream()
                    .map(line -> HelloMessageDetail.builder().timeCollectedOnDevice(Long.parseLong(line[1].trim()))
                            .timeFromHelloMessage(Integer.parseInt(line[2].trim()))
                            .rssiCalibrated(Integer.parseInt(line[3].trim())).build())
                    .collect(Collectors.toList());
            // Add the contact
            contacts.add(Contact.builder().messageDetails(hellos).build());
            reader.close();
        }

        return contacts;
    }

    @Test
    public void test_R1_AA() {
        String directory = "input_v2/R1_AA";

        List<ScoringResult> expectedOutput = new ArrayList<>();

        expectedOutput.add(ScoringResult.builder().rssiScore(0.2259471044964842).duration(3).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.042329639114379036).duration(12).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.10650857766721923).duration(12).nbContacts(8).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(1.0).duration(3).nbContacts(3).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.09273966763679818).duration(12).nbContacts(6).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.37133818098372).duration(3).nbContacts(4).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.3311951204731387).duration(12).nbContacts(8).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0789962559100572).duration(3).nbContacts(3).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(1.0).duration(3).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.273538599276163).duration(12).nbContacts(5).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.002744278271541257).duration(12).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.08118925486303318).duration(3).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.27973109082195263).duration(3).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.11413323165980317).duration(12).nbContacts(7).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.1320433444537647).duration(12).nbContacts(8).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.15560317361598303).duration(3).nbContacts(3).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(12).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(2).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.03075350717796424).duration(12).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.01621210327136334).duration(3).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.006039454671881747).duration(12).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.07633639917572335).duration(3).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0733546277032031).duration(12).nbContacts(4).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.022966487702374996).duration(3).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.13477851024721602).duration(12).nbContacts(10).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.4772384344935852).duration(3).nbContacts(3).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.016616187323681017).duration(3).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(12).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(2).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(12).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.030815354827299996).duration(12).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(3).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(9).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(11).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.5337258000363373).duration(3).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(12).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0021829966957378354).duration(3).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.004833588165450613).duration(10).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(1).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.031191271280426064).duration(3).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(12).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.8956579583812733).duration(3).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(12).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.025114430265707404).duration(12).nbContacts(1).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(3).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(9).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(3).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(8).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(12).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(3).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(4).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(11).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(0).nbContacts(0).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.2463398180057588).duration(1).nbContacts(2).build());
        expectedOutput.add(ScoringResult.builder().rssiScore(0.0).duration(1).nbContacts(0).build());

        for (ScoringResult scoringResult : expectedOutput) {
            scoringResult.setRssiScore(scoringResult.getRssiScore() * scoringResult.getDuration());
        }

        launchTestsOnDirectoryAndExpectOutput(directory, expectedOutput, 0.20538514229166882);
    }

    private void launchTestsOnDirectoryAndExpectOutput(String directory,
                                                       List<ScoringResult> expectedOutput,
                                                       double expectedFinalRisk) {
        log.info("Launching test on directory {}", directory);

        try {
            List<Contact> contacts = retrieveContacts(directory);
            List<ScoringResult> risks = contacts.stream().map(contact -> {
                try {
                    return serviceScoring.execute(contact);
                } catch (RobertScoringException e) {
                    return null;
                }
            }).collect(Collectors.toList());

            for (int i = 0; i < risks.size(); i++) {
                if (risks.get(i).equals(expectedOutput.get(i))) {
                    log.error("Values differ; expected={}; found={}", expectedOutput.get(i), risks.get(i));
                }
            }

            assertTrue(Arrays.equals(expectedOutput.toArray(), risks.toArray()));
            assertEquals(expectedFinalRisk,
                    this.serviceScoring.aggregate(risks
                            .stream()
                            .map(a -> a.getRssiScore())
                            .collect(Collectors.toList())));
        } catch (URISyntaxException | IllegalStateException | IOException | CsvException e) {
            fail(e);
        }
    }
}
