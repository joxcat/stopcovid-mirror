package fr.gouv.stopc.robertserver.ws.service.impl.utils;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.stream.Collectors;

import org.springframework.http.client.ClientHttpResponse;
import org.springframework.web.client.DefaultResponseErrorHandler;

import com.fasterxml.jackson.databind.ObjectMapper;

import fr.gouv.stopc.robertserver.ws.service.impl.CaptchaInternalErrorMessage;

public class CaptchaInternalErrorHandler extends DefaultResponseErrorHandler {

	private ObjectMapper mapper = new ObjectMapper();

	@Override
	public void handleError(ClientHttpResponse response) throws IOException {
		if (response.getStatusCode().is4xxClientError() || response.getStatusCode().is5xxServerError()) {
			try (BufferedReader reader = new BufferedReader(new InputStreamReader(response.getBody()))) {
				String httpBodyResponse = reader.lines().collect(Collectors.joining(""));

				CaptchaInternalErrorMessage errorReceived = mapper.readValue(httpBodyResponse, getErrorMessageClass());

				String errorResponse = httpBodyResponse;

				throw new CaptchaInternalAccessException(response.getStatusCode(), errorReceived, errorResponse);
			}
		}
	}
	
	protected Class<? extends CaptchaInternalErrorMessage> getErrorMessageClass(){
		return CaptchaInternalErrorMessage.class;
	}
}