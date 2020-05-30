package fr.gouv.stopc.robertserver.ws.config;

import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestTemplate;
import org.springframework.context.annotation.Configuration;

@Configuration
public class Config {

    @Bean
    public RestTemplate restTemplate() {

        return new RestTemplate();
    }
}
