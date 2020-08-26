package fr.gouv.stopc.robertserver.ws.service.impl;

import java.net.URI;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

import javax.inject.Inject;

import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import fr.gouv.stopc.robertserver.ws.dto.VerifyResponseDto;
import fr.gouv.stopc.robertserver.ws.service.IRestApiService;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.PushInfoVo;
import io.micrometer.core.instrument.util.StringUtils;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class RestApiServiceImpl implements IRestApiService {

    private final PropertyLoader propertyLoader;

    private final RestTemplate restTemplate;

    @Inject
    public RestApiServiceImpl(final PropertyLoader propertyLoader, final RestTemplate restTemplate) {
        this.propertyLoader = propertyLoader;
        this.restTemplate = restTemplate;
    }

    @Override
    public Optional<VerifyResponseDto> verifyReportToken(String token, String type) {

        if(StringUtils.isEmpty(token) || StringUtils.isEmpty(type)) {
            return Optional.empty();
        }

        try {
            ResponseEntity<VerifyResponseDto> response = restTemplate.getForEntity(buildReportTokenVerificationURI(token, type),
                    VerifyResponseDto.class);

            return Optional.ofNullable(response.getBody());
        } catch (RestClientException e) {
            log.error("Unable to verify the token due to {}", e.getMessage());
        }

        return Optional.empty();
    }

    private URI buildReportTokenVerificationURI(String token, String type) {

        return UriComponentsBuilder.newInstance().scheme("http")
                .host(this.propertyLoader.getServerCodeHost())
                .port(this.propertyLoader.getServerCodePort())
                .path(this.propertyLoader.getServerCodeVerificationPath())
                .queryParam("code", token)
                .queryParam("type", type)
                .build()
                .encode()
                .toUri();
    }

    private URI buildRegistertPushNotifURI() {

        return UriComponentsBuilder.newInstance().scheme("http")
                .host(this.propertyLoader.getPushServerHost())
                .port(this.propertyLoader.getPushServerPort())
                .path(this.propertyLoader.getInternalPathPrefix())
                .path(this.propertyLoader.getPushApiVersion())
                .path(this.propertyLoader.getPushApiPath())
                .build()
                .encode()
                .toUri();
    }

    private URI buildUnregistertPushNotifURI(String pushToken) {

        Map<String, String> parameters = new HashMap<>();
        parameters.put("token", pushToken);

        return UriComponentsBuilder.fromUri(this.buildRegistertPushNotifURI())
                .path(this.propertyLoader.getPushApiTokenPath())
                .build(parameters);
    }

    @Override
    public void registerPushNotif(PushInfoVo pushInfoVo) {

        if (Objects.nonNull(pushInfoVo)) {

            try {
                this.restTemplate.postForEntity(this.buildRegistertPushNotifURI(),
                        pushInfoVo, Object.class);

                log.info("Register to push notification successful");
            } catch (RestClientException e) {
                log.error("Register to push notification failed due to {}", e.getMessage());
            }
        }
    }

    @Override
    public void unregisterPushNotif(String pushToken) {

        if(StringUtils.isNotBlank(pushToken)) {
            try {
                this.restTemplate.exchange(this.buildUnregistertPushNotifURI(pushToken),
                        HttpMethod.DELETE, null, Object.class);

                log.info("Unregister to push notification successful");
            } catch (RestClientException e) {
                log.error("Unregister to push notification failed due to {}", e.getMessage());
            }
        }
    }

}
