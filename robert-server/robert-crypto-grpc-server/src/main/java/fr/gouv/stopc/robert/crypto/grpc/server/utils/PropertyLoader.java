package fr.gouv.stopc.robert.crypto.grpc.server.utils;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import lombok.Getter;


@Getter
@Component
public class PropertyLoader {

  @Value("${robert.crypto.server.port}")
  private String cryptoServerPort;


}
