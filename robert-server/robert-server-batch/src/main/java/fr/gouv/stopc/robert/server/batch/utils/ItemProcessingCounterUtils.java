package fr.gouv.stopc.robert.server.batch.utils;

import lombok.Getter;

@Getter
public class ItemProcessingCounterUtils {

    /** Holder for multithreading*/
    private static class ItemProcessingCounterUtilsHolder {
        private final static ItemProcessingCounterUtils instance = new ItemProcessingCounterUtils();
    }


    private long currentIdFromItemIdMapping = 0;

    public int numberOfProcessedContacts = 0;

    public int numberOfProcessedRegistrations = 0;

    private ItemProcessingCounterUtils() {
    }

    public static ItemProcessingCounterUtils getInstance() {
        return ItemProcessingCounterUtilsHolder.instance;
    }

    public int addNumberOfProcessedContacts(int contactCount) {
        numberOfProcessedContacts += contactCount;
        return numberOfProcessedContacts;
    }

    public int addNumberOfProcessedRegistrations(int registrationCount) {
        numberOfProcessedRegistrations += registrationCount;
        return numberOfProcessedRegistrations;
    }

    public long incrementCurrentIdOfItemIdMapping() {
        currentIdFromItemIdMapping++;
        return currentIdFromItemIdMapping;
    }
}
