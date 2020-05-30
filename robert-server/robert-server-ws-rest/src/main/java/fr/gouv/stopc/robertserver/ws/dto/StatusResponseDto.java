package fr.gouv.stopc.robertserver.ws.dto;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.Singular;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

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
}
