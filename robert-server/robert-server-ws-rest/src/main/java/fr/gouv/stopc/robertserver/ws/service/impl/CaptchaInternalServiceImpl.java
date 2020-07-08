package fr.gouv.stopc.robertserver.ws.service.impl;

import java.net.URI;
import java.util.HashMap;
import java.util.Objects;
import java.util.Optional;

import javax.inject.Inject;
import javax.validation.constraints.NotNull;

import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import fr.gouv.stopc.robertserver.ws.dto.CaptchaInternalDto;
import fr.gouv.stopc.robertserver.ws.service.CaptchaInternalService;
import fr.gouv.stopc.robertserver.ws.service.impl.utils.CaptchaInternalAccessException;
import fr.gouv.stopc.robertserver.ws.service.impl.utils.CaptchaInternalErrorHandler;
import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import fr.gouv.stopc.robertserver.ws.utils.PropertyLoader;
import fr.gouv.stopc.robertserver.ws.vo.RegisterInternalVo;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.ToString;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class CaptchaInternalServiceImpl implements CaptchaInternalService {

	private RestTemplate restTemplate;

	private PropertyLoader propertyLoader;

	@Inject
	public CaptchaInternalServiceImpl(RestTemplate restTemplate,
							  PropertyLoader propertyLoader) {

//		this.restTemplate = new RestTemplateBuilder().errorHandler(new RestAccessErrorHandler()).configure(restTemplate);
		this.restTemplate = restTemplate;
		this.restTemplate.setErrorHandler(new CaptchaInternalErrorHandler());
		this.propertyLoader = propertyLoader;
	}

	@AllArgsConstructor
	@Data
	protected class CaptchaInternalServiceDto{
		@NotNull
		@ToString.Exclude
		private String answer;
	}
	
	@Override
	public boolean verifyCaptcha(final RegisterInternalVo registerVo) {

		return Optional.ofNullable(registerVo).map(captcha -> {

			HttpEntity<CaptchaInternalServiceDto> request = new HttpEntity<CaptchaInternalServiceDto>(
					new CaptchaInternalServiceDto(captcha.getCaptcha()), initHttpHeaders());

			ResponseEntity<CaptchaInternalDto> response = null;
			try {
				response = this.restTemplate.postForEntity(constructUri(captcha.getCaptchaId()), request, CaptchaInternalDto.class);
			} catch (CaptchaInternalAccessException e) {
				// exception only related to restTemplate and produced by the errorHandler
				boolean isUnvalid = Optional.ofNullable(e).map(CaptchaInternalAccessException::getErrorMessage)
					.filter(error -> Objects.nonNull(error) && Objects.equals("0002", error.getCode()) 
							&& Objects.equals(HttpStatus.NOT_FOUND, e.getStatusCode()))
					.map(error -> {
						log.error("Captcha not validated => {} : {} ", MessageConstants.INVALID_DATA.getValue(), e.getErrorMessage().getMessage());
						return true;
					}).orElse(false);
			
				boolean isUnauthorized = Optional.ofNullable(e).map(CaptchaInternalAccessException::getErrorMessage)
					.filter(error -> Objects.nonNull(error) && ((Objects.equals("0001", error.getCode()) 
							&& Objects.equals(HttpStatus.NOT_FOUND, e.getStatusCode()))) || (Objects.equals(HttpStatus.GONE, e.getStatusCode())))
					.map(error -> {
						log.error("Captcha not validated => {} : {}", MessageConstants.UNAUTHORIZED_OPERATION.getValue(), e.getErrorMessage().getMessage());
						return true;
					}).orElse(false);
				// or else
					if (!isUnvalid && !isUnauthorized) { // None of the above, but still an error
						log.error("Captcha not validated => {} : {}", MessageConstants.ERROR_OCCURED.getValue(),
								e.getErrorMessage().getMessage());
					}
					return false;
			} catch (RestClientException e) {
				// used only if errorHandler is disabled
				log.error("Captcha not validated => {} : {}", MessageConstants.ERROR_OCCURED.getValue(), e.getMessage());
				return false;
			}

			boolean isSuccess = Optional.ofNullable(response)
			   .map(ResponseEntity::getBody)
			   .filter(captchaDto -> Objects.nonNull(captchaDto.getResult()) && Objects.equals(captchaDto.getResult(),this.propertyLoader.getCaptchaInternalSuccessCode()))
			   .map(captchaDto -> {
					log.info("Captcha validated => {}", MessageConstants.SUCCESSFUL_OPERATION.getValue());
				   return true; // Response 200 with SUCCESS
			   }).orElse(false);

			boolean hasFailed = Optional.ofNullable(response)
			   .map(ResponseEntity::getBody)
			   .filter(captchaDto -> Objects.nonNull(captchaDto.getResult()) && !Objects.equals(captchaDto.getResult(),this.propertyLoader.getCaptchaInternalSuccessCode()))
			   .map(captchaDto -> {
					log.info("Captcha not validated => {}", MessageConstants.UNSUCCESSFUL_OPERATION.getValue());
				   return true; // Response 200 with FAILED
			   }).orElse(false);
			
			return isSuccess && !hasFailed;

		}).orElse(false); // Empty validation request
	}

	private HttpHeaders initHttpHeaders() {

		HttpHeaders headers = new HttpHeaders();
		headers.setContentType(MediaType.APPLICATION_JSON);

		return headers;
	}

	
	private URI constructUri(String captchaId) {
		HashMap<String, String> uriVariables = new HashMap<String, String>();
		uriVariables.put("captchaId", captchaId);
	    return UriComponentsBuilder.fromHttpUrl(this.propertyLoader.getCaptchaInternalVerificationUrl())
                .build(uriVariables);
	}

}
