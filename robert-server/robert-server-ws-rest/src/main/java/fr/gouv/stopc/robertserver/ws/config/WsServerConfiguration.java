package fr.gouv.stopc.robertserver.ws.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.ToString;

/*
 * Global configuration of the Robert Server WS application, which is editable through Consul.
 */
@Getter
@ToString
@Component
@RefreshScope
public class WsServerConfiguration {

	@Value("${robert.epoch-bundle-duration-in-days}")
	private Integer epochBundleDurationInDays;

	@Value("${robert.server.status-request-minimum-epoch-gap}")
	private Integer statusRequestMinimumEpochGap;

}
