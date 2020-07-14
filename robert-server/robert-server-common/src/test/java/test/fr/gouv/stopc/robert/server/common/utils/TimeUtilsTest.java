package test.fr.gouv.stopc.robert.server.common.utils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;


@Slf4j
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

    public long getServiceTimeStart() {
        final LocalDateTime ldt = LocalDateTime.of(2020, 6, 1, 00, 00);
        final ZonedDateTime zdt = ldt.atZone(ZoneId.of("UTC"));
        return TimeUtils.convertUnixMillistoNtpSeconds(zdt.toInstant().toEpochMilli());
    }
    @Test
    void testGetDateFromEpochTimezone() {
        for (int i = 0; i < 96 * 2; i++) {
            log.info("{}: {}", i, TimeUtils.getDateFromEpoch(i, getServiceTimeStart()));
            log.info("{}", 1 + (96 + 87 - (i % 96)) % 96);
        }
    }

    @Test
    void testGetDateFromEpochBeforeChange() {
        for (int i = 940; i < 1200; i++) {
            log.info("{}; i={}",  TimeUtils.getDateFromEpoch(i, getServiceTimeStart()), i);
        }
    }

    private static int MAX_TEST = 96 * 13;
    @Test
    void testCompareGetDateAndRemaining() {
        LocalDate[] dates = new LocalDate[MAX_TEST];
        int[] remainingEpochsForDay = new int[MAX_TEST];
        for (int i = 0; i < MAX_TEST; i++) {
            dates[i] = TimeUtils.getDateFromEpoch(i, getServiceTimeStart());
        }

        boolean error = false;
        int i = 0;
        while (i < MAX_TEST) {
            int j = i + 1;
            while (j < MAX_TEST && dates[i].isEqual(dates[j])) {
                j++;
            }
            for (int k = i; k < j; k++) {
                remainingEpochsForDay[k] = j - k;
            }
            i = j;
        }
        for (i = 0; i < MAX_TEST; i++) {
            int i1 = remainingEpochsForDay[i];
            int i2 = TimeUtils.remainingEpochsForToday(i);
            if (i1 != i2) {
                error = true;
            }
        }
        assertTrue(!error);
    }
}
