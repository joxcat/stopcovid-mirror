package fr.gouv.stopc.robertserver.ws.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotNull;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class UnregisterResponseDto {
    @NotNull
    private Boolean success;
    private String message;

}
