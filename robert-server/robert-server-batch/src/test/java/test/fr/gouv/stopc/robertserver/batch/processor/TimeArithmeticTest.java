package test.fr.gouv.stopc.robertserver.batch.processor;

import fr.gouv.stopc.robert.server.common.utils.TimeUtils;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;

import java.util.Random;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

@Slf4j
public class TimeArithmeticTest {
    private final static int TOLERANCE = 180;

    @Test
    void testTSandTRInTheMiddleSucceeds() {
        for (int i = 0; i < 10000; i++) {
            Random r = new Random();
            long ts = r.nextInt(TimeUtils.USHORT_MAX - 2 * TOLERANCE + 1) + TOLERANCE;
            long tr = r.nextInt(2 * TOLERANCE + 1) - TOLERANCE + ts;

            assertTrue(TimeUtils.toleranceCheckWithWrap(ts, tr, TOLERANCE));
        }
    }

    @Test
    void testTSAtBeginningAndTRAtEndSucceeds() {
        for (int i = 0; i < 10000; i++) {
            Random r = new Random();
            long ts = r.nextInt(TOLERANCE + 1);
            long overflow = TOLERANCE - ts;
            long tr = (TimeUtils.USHORT_MAX - r.nextInt((int)overflow + 1) + 1) % 65536;

            assertTrue(TimeUtils.toleranceCheckWithWrap(ts, tr, TOLERANCE));
            assertTrue(TimeUtils.toleranceCheckWithWrap(180, 0, TOLERANCE));
        }
    }

    @Test
    void testTSAtBeginningAndTRAtEndOrMiddleFails() {
        for (int i = 0; i < 10000; i++) {
            Random r = new Random();
            long ts = r.nextInt(TOLERANCE + 1);
            long overflow = TOLERANCE - ts;
            long tr = r.nextInt(TimeUtils.USHORT_MAX + 1 - (int)overflow - (TOLERANCE + (int)ts + 1)) + TOLERANCE + ts + 1;

            assertFalse(TimeUtils.toleranceCheckWithWrap(ts, tr, TOLERANCE));
        }
    }

    @Test
    void testTSAtBeginningAndTRInMiddleSucceeds() {
        for (int i = 0; i < 10000; i++) {
            Random r = new Random();
            long ts = r.nextInt(TOLERANCE + 1);
            long tr = r.nextInt( TOLERANCE + 1) + (int)ts;

            assertTrue(TimeUtils.toleranceCheckWithWrap(ts, tr, TOLERANCE));
        }
    }
}
