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
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import fr.gouv.stopc.robert.server.common.service.IServerConfigurationService;
import fr.gouv.stopc.robertserver.ws.dto.CaptchaDto;
import fr.gouv.stopc.robertserver.ws.service.CaptchaService;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.RegisterVo;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class CaptchaServiceImpl implements CaptchaService {

	private RestTemplate restTemplate;

	private IServerConfigurationService serverConfigurationService;

	private PropertyLoader propertyLoader;

	@Inject
	public CaptchaServiceImpl(RestTemplate restTemplate,
							  IServerConfigurationService serverConfigurationService,
							  PropertyLoader propertyLoader) {

		this.restTemplate = restTemplate;
		this.serverConfigurationService = serverConfigurationService;
		this.propertyLoader = propertyLoader;
	}

	@Override
	public boolean verifyCaptcha(final RegisterVo registerVo) {

		// This part of the code should be removed before any public use. For security reason.
		// TODO: remove this as far as it is no more needed for test.
		if (this.hasMagicNumber(registerVo)) return true;

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

	/**
	 *
	 * Method checks if captcha in RegisterVo should be ignore.
	 * This part of the code should be removed before any public use. For security reason.
	 * TODO: Remove this as far as it is no more needed for tests
	 */
	private boolean hasMagicNumber(RegisterVo registerVo) {

		return Optional.ofNullable(registerVo).map(RegisterVo::getCaptcha).map(
				captcha -> {
					if(!StringUtils.isEmpty(this.propertyLoader.getMagicNumber())) {
						return this.propertyLoader.getMagicNumber().equals(captcha);
					} else{
						return false;
					}
				}
		).orElse(false);
	}

	private boolean isSuccess(CaptchaDto captchaDto, Date sendingDate) {

		return this.propertyLoader.getCaptchaHostname().equals(captchaDto.getHostname())
				&& Math.abs(sendingDate.getTime()
						- captchaDto.getChallengeTimestamp()
									.getTime()) <= this.serverConfigurationService.getCaptchaChallengeTimestampTolerance()
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
