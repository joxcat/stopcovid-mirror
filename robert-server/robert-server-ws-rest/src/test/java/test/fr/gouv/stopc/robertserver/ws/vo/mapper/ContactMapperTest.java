package test.fr.gouv.stopc.robertserver.ws.vo.mapper;

import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import fr.gouv.stopc.robertserver.database.model.Contact;
import fr.gouv.stopc.robertserver.ws.RobertServerWsRestApplication;
import fr.gouv.stopc.robertserver.ws.vo.DistinctiveHelloInfoWithinEpochForSameEBIDVo;
import fr.gouv.stopc.robertserver.ws.vo.GroupedHellosReportVo;
import fr.gouv.stopc.robertserver.ws.vo.mapper.ContactMapper;
import lombok.extern.slf4j.Slf4j;
import org.bson.internal.Base64;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.util.CollectionUtils;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(SpringExtension.class)
@Slf4j
public class ContactMapperTest {
    @InjectMocks
    private ContactMapper contactMapper;

    private final String sampleMac = "mac";
    private final String sampleEcc = "ecc";
    private final String sampleEbid = "ebid";
    private final int sampleRssiRaw = -100;
    private final int sampleRssiCalibrated = -127;

    @Test
    public void testMapEmptyListReturnsEmpty() {
        assertTrue(CollectionUtils.isEmpty(this.contactMapper.convertToEntity(Collections.emptyList())));
    }

    @Test
    public void testMapSizeSuccess() {
        ArrayList<GroupedHellosReportVo> contacts = new ArrayList<>();

        contacts.add(generateContact());
        contacts.add(generateContact());
        contacts.add(generateContact());

        int size = contacts.size();
        assertEquals(size, this.contactMapper.convertToEntity(contacts).size());
    }

    @Test
    public void testMapContentSuccess() {
        Optional<Contact> contact = this.contactMapper.convertToEntity(generateContact());

        assertTrue(contact.isPresent());
        assertTrue(Arrays.equals(sampleEbid.getBytes(), contact.get().getEbid()));
        assertTrue(Arrays.equals(sampleEcc.getBytes(), contact.get().getEcc()));
        assertFalse(CollectionUtils.isEmpty(contact.get().getMessageDetails()));
        assertTrue(Arrays.equals(sampleMac.getBytes(), contact.get().getMessageDetails().get(0).getMac()));
        assertEquals(sampleRssiCalibrated, contact.get().getMessageDetails().get(0).getRssiCalibrated());
        assertEquals(sampleRssiRaw, contact.get().getMessageDetails().get(0).getRssiRaw());
    }

    private DistinctiveHelloInfoWithinEpochForSameEBIDVo generateHelloMessage() {
        return DistinctiveHelloInfoWithinEpochForSameEBIDVo.builder()
                .timeCollectedOnDevice(TimeUtils.convertUnixMillistoNtpSeconds(System.currentTimeMillis()))
                .timeFromHelloMessage(1)
                .mac(Base64.encode(sampleMac.getBytes()))
                .rssiCalibrated(sampleRssiCalibrated)
                .rssiRaw(sampleRssiRaw)
                .build();
    }

    private List<DistinctiveHelloInfoWithinEpochForSameEBIDVo> generateHelloMessages() {
        ArrayList<DistinctiveHelloInfoWithinEpochForSameEBIDVo> list = new ArrayList<>();
        list.add(generateHelloMessage());
        list.add(generateHelloMessage());
        list.add(generateHelloMessage());
        return list;
    }

    private GroupedHellosReportVo generateContact() {
        return GroupedHellosReportVo.builder()
                .ebid(Base64.encode(sampleEbid.getBytes()))
                .ecc(Base64.encode(sampleEcc.getBytes()))
                .ids(generateHelloMessages())
                .build();
    }
}
