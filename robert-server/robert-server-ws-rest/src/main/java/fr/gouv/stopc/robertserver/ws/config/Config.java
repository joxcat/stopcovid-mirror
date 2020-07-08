package fr.gouv.stopc.robertserver.ws.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class Config {
	
	public static final String API_V1 = "/v1";

	public static final String API_V2 = "/v2";

    @Bean
    public RestTemplate restTemplate() {

        return new RestTemplate();
    }
}
