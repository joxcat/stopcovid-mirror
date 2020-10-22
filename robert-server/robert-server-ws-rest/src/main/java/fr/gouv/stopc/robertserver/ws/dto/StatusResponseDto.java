package fr.gouv.stopc.robertserver.ws.dto;

import java.util.List;

import javax.validation.constraints.NotNull;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.Singular;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class StatusResponseDto {
    @NotNull
    private boolean atRisk;

    @NotNull
    private String tuples;

    @Singular("config")
    private List<ClientConfigDto> config;

    private long lastExposureTimeframe;

    private String message;

    private int riskEpoch;
}
