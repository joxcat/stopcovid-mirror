package fr.gouv.stopc.robertserver.ws.dto.mapper;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.bson.internal.Base64;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;

import com.google.protobuf.ByteString;

import fr.gouv.stopc.robert.crypto.grpc.server.messaging.Tuple;
import fr.gouv.stopc.robertserver.ws.dto.EpochKeyBundleDto;
import fr.gouv.stopc.robertserver.ws.dto.EpochKeyDto;

@Component
public class EpochKeyBundleDtoMapper {

	public Optional<EpochKeyBundleDto> convert(Tuple tuple) {

		return Optional.ofNullable(tuple)
				.map(item -> {

					return EpochKeyBundleDto.builder()
							.epochId(item.getEpochId())
							.key(EpochKeyDto.builder()
							     .ebid(encode(item.getEbid()))
							     .ecc(encode(item.getEcc()))
							     .build())
							.build();
				});
	}

	public List<EpochKeyBundleDto> convert(List<Tuple> tuples){

		if (CollectionUtils.isEmpty(tuples)) {

			return Collections.emptyList();
		}

		return tuples.stream()
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
