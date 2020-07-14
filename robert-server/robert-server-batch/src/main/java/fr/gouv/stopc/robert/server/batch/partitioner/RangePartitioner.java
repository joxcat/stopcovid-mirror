package fr.gouv.stopc.robert.server.batch.partitioner;

import fr.gouv.stopc.robert.server.batch.configuration.ContactsProcessingConfiguration;
import fr.gouv.stopc.robert.server.batch.utils.ItemProcessingCounterUtils;
import org.springframework.batch.core.partition.support.Partitioner;
import org.springframework.batch.item.ExecutionContext;

import java.util.HashMap;
import java.util.Map;

public class RangePartitioner implements Partitioner {

    @Override
    public Map<String, ExecutionContext> partition(int gridSize) {

        Map<String, ExecutionContext> result = new HashMap<>(gridSize);

        long itemIdMappingCount = ItemProcessingCounterUtils.getInstance().getCurrentIdFromItemIdMapping();
        long elementCountByPartition = (long)Math.ceil((double)itemIdMappingCount/
                (double) ContactsProcessingConfiguration.GRID_SIZE);
        long start = 1;
        long end = elementCountByPartition;

        for (int i = 0; i < gridSize; i++) {
            ExecutionContext value = new ExecutionContext();
            value.putLong("start", start);
            value.putLong("end", end);
            value.putString("name", "Thread " + i);
            result.put("Partition " + i, value);

            start += elementCountByPartition;
            end += elementCountByPartition;
        }

        return result;
    }
}
