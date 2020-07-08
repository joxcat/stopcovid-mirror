package fr.gouv.stopc.robert.server.common.utils;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;

public final class TimeUtils {
    //  Number of seconds to fill the gap between UNIX timestamp (1/1/1970) and NTP timestamp (1/1/1900)
    public final static long SECONDS_FROM_01_01_1900 = 2208988800L;

    // Epoch duration is 15 minutes so 15 * 60 = 900 seconds
    public final static int EPOCH_DURATION_SECS = 900;

    private TimeUtils() {
        throw new AssertionError();
    }

    public static long convertNTPSecondsToUnixMillis(long ntpTime) {
        return (ntpTime - SECONDS_FROM_01_01_1900) * 1000;
    }

    /**
     * Convert UNIX timestamp in milliseconds to NTP seconds
     * @param unixTimeInMillis UNIX time in millis
     * @return time converted in NTP in seconds
     */
    public static long convertUnixMillistoNtpSeconds(final long unixTimeInMillis) {
        return (unixTimeInMillis / 1000) + SECONDS_FROM_01_01_1900;
    }

    /**
     * ref {@see <a href="https://stackoverflow.com/questions/29112071/how-to-convert-ntp-time-to-unix-epoch-time-in-c-language-linux/29138806#29138806">Stackoverflow NTP to unix time interval</a>}
     * @param from the timestamp from which to calculate the number of epochs (e.g. ROBERT service time start); as NTP timestamp in seconds
     * @param to the timestamp until which to calculate the number of epochs (e.g. current time); as NTP timestamp in seconds
     * @return number of epochs between the two dates (i.e. current epoch)
     */
    public static int getNumberOfEpochsBetween(final long from, final long to) {
        long numberEpochs =  (to - from) / EPOCH_DURATION_SECS;
        return Integer.parseInt(Long.toString(numberEpochs));
    }

    /**
     * Easier way to get the current epoch from the provided start time
     * @param timeStart as NTP timestamp in *seconds*
     * @return current epoch
     */
    public static int getCurrentEpochFrom(final long timeStart) {
        return getNumberOfEpochsBetween(timeStart, convertUnixMillistoNtpSeconds(System.currentTimeMillis()));
    }

    /**
     *
     * @param epoch
     * @param timeStart in NTP seconds
     * @return
     */
    public static LocalDate getDateFromEpoch(int epoch, long timeStart) {

        String timezone = epoch < 960 ? "Europe/Paris" : "UTC";

        long fromInNtpSecs = (EPOCH_DURATION_SECS * epoch) + timeStart;
        long fromUnixMillis = (fromInNtpSecs - SECONDS_FROM_01_01_1900) * 1000;
        return Instant.ofEpochMilli(fromUnixMillis).atZone(ZoneId.of(timezone)).toLocalDate();
    }

    public final static int EPOCHS_PER_DAY = 4 * 24;
    public static int remainingEpochsForToday(int epochId) {
        if (epochId >= 960) {
            return EPOCHS_PER_DAY - epochId % EPOCHS_PER_DAY;
        }
        else if (epochId >= 952) {
            return (960 - epochId) + 96;
        } else {
            return 1 + (EPOCHS_PER_DAY + 87 - (epochId % EPOCHS_PER_DAY)) % EPOCHS_PER_DAY;
        }
    }

    public static int USHORT_MAX = 65535;
    public static boolean toleranceCheckWithWrap(long ts, long tr, int tolerance) {
        if (tr == ts) {
            return true;
        }

        // ts will always be inferior to tr
        if (tr < ts) {
            long temp = ts;
            ts = tr;
            tr = temp;
        }

        // If value is not in min/max zones that may cause overflow
        if (Math.abs(tr - ts) <= tolerance) {
            return true;
        } else {
            // Overflow risk

            // ts is in min zone, value may overflow to max zone
            if (ts < tolerance) {
                // tr is between 0 and ts
                if (tr < ts) {
                    return true;
                }
                else {
                    // tr is in max zone but within tolerance
                    if (tr > USHORT_MAX - (tolerance - ts)) {
                        return true;
                    } else {
                        // tr is in max zone but outside tolerance
                        return false;
                    }
                }
            }
        }
        return false;
    }
}
