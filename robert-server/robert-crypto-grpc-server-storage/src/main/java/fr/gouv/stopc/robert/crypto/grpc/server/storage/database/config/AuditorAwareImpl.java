package fr.gouv.stopc.robert.crypto.grpc.server.storage.database.config;

import java.util.Optional;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.AuditorAware;


public class AuditorAwareImpl implements AuditorAware<String> {

  @Value("robert")
  private String user;

  @Override
  public Optional<String> getCurrentAuditor() {

    return Optional.of(this.user);
  }

}
