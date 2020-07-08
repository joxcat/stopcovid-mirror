package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.net.URI;
import java.util.HashMap;

import javax.inject.Inject;
import javax.validation.Valid;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.MediaType;
import org.springframework.http.RequestEntity;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import fr.gouv.stopc.robertserver.ws.controller.ICaptchaController;
import fr.gouv.stopc.robertserver.ws.dto.CaptchaInternalCreationDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.CaptchaInternalCreationVo;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@ConditionalOnProperty("captcha.internal.gateway.enabled")
public class CaptchaControllerImpl implements ICaptchaController {

    private final RestTemplate restTemplate;
    private final PropertyLoader propertyLoader;

    @Inject
    public CaptchaControllerImpl(RestTemplate restTemplate,
                                 PropertyLoader propertyLoader) {
        this.restTemplate = restTemplate;
        this.propertyLoader = propertyLoader;
    }

    @Override
    public ResponseEntity<CaptchaInternalCreationDto> createCaptcha(
            @Valid CaptchaInternalCreationVo captchaInternalCreationVo) throws RobertServerException {

        ResponseEntity<CaptchaInternalCreationDto> response = null;
        try {
            response = restTemplate.postForEntity(
                    UriComponentsBuilder.fromHttpUrl(
                            this.propertyLoader.getCaptchaInternalHostname() + "/private/api/v1/captcha").build().toUri(),
                    captchaInternalCreationVo,
                    CaptchaInternalCreationDto.class);
            log.info("Captcha creation response: {}", response);
        } catch (RestClientException e) {
            log.error("Could not create captcha with type {} and locale {}; {}",
                    captchaInternalCreationVo.getType(),
                    captchaInternalCreationVo.getLocale(),
                    e.getMessage());
            return ResponseEntity.badRequest().build();
        }
        return response;
    }

    @Override
    public ResponseEntity<byte[]> getCaptchaImage(String captchaId) throws RobertServerException {
        return this.getCaptchaCommon(captchaId, "image");
    }

    @Override
    public ResponseEntity<byte[]> getCaptchaAudio(String captchaId) throws RobertServerException {
        return this.getCaptchaCommon(captchaId, "audio");
    }

    private ResponseEntity<byte[]> getCaptchaCommon(String captchaId, String mediaType) {
        log.info("Getting captcha {} as {}", captchaId, mediaType);
        HashMap<String, String> uriVariables = new HashMap<String, String>();
        uriVariables.put("captchaId", captchaId);

        try {
            URI uri = UriComponentsBuilder.fromHttpUrl(
                    this.propertyLoader.getCaptchaInternalHostname() + "/public/api/v1/captcha/{captchaId}." + (mediaType == "audio" ? "wav" : "png"))
                    .build(uriVariables);

            log.info("Getting captcha from URL: {}", uri);

            RestTemplate restTemplate = new RestTemplate();
            RequestEntity<Void> request = RequestEntity
                    .get(uri)
                    .accept(mediaType == "image" ? MediaType.IMAGE_PNG : MediaType.ALL)
                    .build();
            ResponseEntity<byte[]> response = restTemplate.exchange(request, byte[].class);

            //ResponseEntity<Object> response = restTemplate.getForEntity(uri, Object.class);
            //ResponseEntity<Object> response = restTemplate.exchange(uri, HttpMethod.GET, entity, Object.class);
            log.info("Captcha resource access response: {}", response);
            return response;
        } catch (RestClientException e) {
            log.error("Could not get resource type {} for captcha {}; {}", mediaType, captchaId, e.getMessage());
            return ResponseEntity.notFound().build();
        }
    }
}
