package fr.gouv.stopc.robertserver.ws.service.impl;

import java.net.URI;
import java.util.Date;
import java.util.Objects;
import java.util.Optional;

import javax.inject.Inject;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import fr.gouv.stopc.robertserver.ws.dto.CaptchaDto;
import fr.gouv.stopc.robertserver.ws.service.CaptchaService;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.RegisterVo;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class CaptchaServiceImpl implements CaptchaService {

	private RestTemplate restTemplate;

	private PropertyLoader propertyLoader;

	@Inject
	public CaptchaServiceImpl(RestTemplate restTemplate,
							  PropertyLoader propertyLoader) {

		this.restTemplate = restTemplate;
		this.propertyLoader = propertyLoader;
	}

	@Override
	public boolean verifyCaptcha(final RegisterVo registerVo) {

		return Optional.ofNullable(registerVo).map(RegisterVo::getCaptcha).map(captcha -> {

			HttpEntity request = new HttpEntity(initHttpHeaders());
			Date sendingDate = new Date();

			ResponseEntity<CaptchaDto> response = null;
			try {
				response = this.restTemplate.postForEntity(constructUri(captcha), request, CaptchaDto.class);
			} catch (RestClientException e) {
				log.error(e.getMessage());
				return false;
			}

			return Optional.ofNullable(response)
						   .map(ResponseEntity::getBody)
						   .filter(captchaDto -> Objects.nonNull(captchaDto.getChallengeTimestamp()))
						   .map(captchaDto -> {

							   return isSuccess(captchaDto, sendingDate);
						   })
						   .orElse(false);

		}).orElse(false);
	}

	private HttpHeaders initHttpHeaders() {

		HttpHeaders headers = new HttpHeaders();
		headers.setContentType(MediaType.APPLICATION_JSON);

		return headers;
	}

	private boolean isSuccess(CaptchaDto captchaDto, Date sendingDate) {

		return this.propertyLoader.getCaptchaHostname().equals(captchaDto.getHostname())
				&& Math.abs(sendingDate.getTime()
						- captchaDto.getChallengeTimestamp()
									.getTime()) <= this.propertyLoader.getCaptchaChallengeTimestampTolerance()
											* 1000L;
	}

	private URI constructUri(String captcha) {


	    return UriComponentsBuilder.fromHttpUrl(this.propertyLoader.getCaptchaVerificationUrl())
                .queryParam("secret", this.propertyLoader.getCaptchaSecret())
                .queryParam("response", captcha)
                .build()
                .encode()
                .toUri();
	}

}
