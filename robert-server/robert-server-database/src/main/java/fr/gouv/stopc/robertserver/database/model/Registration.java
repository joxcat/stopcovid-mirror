package fr.gouv.stopc.robertserver.database.model;

import java.util.ArrayList;
import java.util.List;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
@Document(value = "idTable")
public class Registration {

    @Id
    @ToString.Exclude
    private byte[] permanentIdentifier;

    private boolean isNotified;

    private boolean atRisk;

    private int lastStatusRequestEpoch;

    private int latestRiskEpoch;

    private int lastFailedStatusRequestEpoch;

    private String lastFailedStatusRequestMessage;

    /**
     * Record the time difference perceived between the server time and the client time
     * To be set by any request that can be tied to an ID
     */
    private long lastTimestampDrift;

    @Builder.Default
    private List<EpochExposition> exposedEpochs = new ArrayList<>();

}
