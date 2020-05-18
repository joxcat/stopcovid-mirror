package fr.gouv.stopc.robertserver.ws.dto.mapper;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.bson.internal.Base64;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.response.EphemeralTupleResponse;
import fr.gouv.stopc.robertserver.ws.dto.EpochKeyBundleDto;
import fr.gouv.stopc.robertserver.ws.dto.EpochKeyDto;

@Component
public class EpochKeyBundleDtoMapper {

	public Optional<EpochKeyBundleDto> convert(EphemeralTupleResponse ephemeralTupleResponse) {

		return Optional.ofNullable(ephemeralTupleResponse)
				.map(response -> {

					return EpochKeyBundleDto.builder()
							.epochId(ephemeralTupleResponse.getEpochId())
							.key(EpochKeyDto.builder()
							     .ebid(encode(ephemeralTupleResponse.getEbid()))
							     .ecc(encode(ephemeralTupleResponse.getEcc()))
							     .build())
							.build();
				});
	}

	public List<EpochKeyBundleDto> convert(List<EphemeralTupleResponse> ephemeralTupleResponses){

		if (CollectionUtils.isEmpty(ephemeralTupleResponses)) {

			return Collections.emptyList();
		}

		return ephemeralTupleResponses.stream()
				.map(this::convert)
				.filter(Optional::isPresent)
				.map(Optional::get)
				.collect(Collectors.toList());
	}

	private String encode(ByteString byteString) {

		return Optional.ofNullable(byteString)
				.map(ByteString::toByteArray)
				.map(Base64::encode)
				.orElse(null);
	}

}
