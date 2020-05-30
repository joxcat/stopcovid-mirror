package test.fr.gouv.stopc.robert.server.common.utils;

import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

public class TimeUtilsTest {

    @Test
    void testGetDateFromEpochNowSucceeds() {
        long startTime = System.currentTimeMillis() / 1000 + TimeUtils.SECONDS_FROM_01_01_1900;
        assertEquals(LocalDate.now(), TimeUtils.getDateFromEpoch(0, startTime));
    }

    @Test
    void testGetDateFromEpochSetSucceeds() {
        assertEquals(LocalDate.of(2020, 5, 26), TimeUtils.getDateFromEpoch(4080, 3795804000L));
    }

    @Test
    void testGetDateFromEpochSetFails() {
        assertNotEquals(LocalDate.of(2020, 5, 26), TimeUtils.getDateFromEpoch(3984, 3795804000L));
    }
}
