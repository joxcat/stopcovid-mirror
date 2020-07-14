package fr.gouv.stopc.robert.server.batch.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
@Document(value = "itemIdMapping")
public class ItemIdMapping<T> {
    @Id
    private Long id;

    private T itemId;
}
