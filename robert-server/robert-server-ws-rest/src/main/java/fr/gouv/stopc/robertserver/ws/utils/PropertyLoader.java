package fr.gouv.stopc.robertserver.ws.utils;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import lombok.Getter;

@Getter
@Component
public class PropertyLoader {

    @Value("${robert.crypto.server.host}")
    private String cryptoServerHost;

    @Value("${robert.crypto.server.port}")
    private String cryptoServerPort;

    /**
     * @return the verification URL for the internal captcha service
     */
    @Value("${captcha.internal.verify.url}")
    private String captchaVerificationUrl;

    @Value("${captcha.internal.hostname}")
    private String captchaHostname;

    /**
     * @return the successful code from the verification by the internal captcha service
     */
    @Value("${captcha.internal.success.code}")
    private String captchaSuccessCode;

    @Value("${submission.code.server.host}")
    private String serverCodeHost;

    @Value("${submission.code.server.port}")
    private String serverCodePort;

    @Value("${submission.code.server.verify.path}")
    private String serverCodeVerificationPath;

    @Value("${robert.esr.limit}")
    private Integer esrLimit;

    @Value("${robert.server.request-time-delta-tolerance}")
    private Integer requestTimeDeltaTolerance;

    @Value("${robert.server.captcha-challenge-timestamp-tolerance}")
    private Integer captchaChallengeTimestampTolerance;

    @Value("${controller.internal.path.prefix}")
    private String internalPathPrefix;

    @Value("${push.server.host}")
    private String pushServerHost;

    @Value("${push.server.port}")
    private String pushServerPort;

    @Value("${push.api.version}")
    private String pushApiVersion;

    @Value("${push.api.path}")
    private String pushApiPath;

    @Value("${push.api.path.token}")
    private String pushApiTokenPath;

}
