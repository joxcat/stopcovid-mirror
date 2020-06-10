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
     * 
     * @return the verification URL for the captcha
     */
    @Value("${captcha.verify.url}")
    private String captchaVerificationUrl;

    /**
     * 
     * @return the secret to be sent to the captcha server along with challenge response
     */
    @Value("${captcha.secret}")
    private String captchaSecret;

    /**
     * 
     * @return the hostname of the site to check against the response from the captcha server
     */
    @Value("${captcha.hostname}")
    private String captchaHostname;


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

    @Value("${robert.server.status-request-minimum-epoch-gap}")
    private Integer statusRequestMinimumEpochGap;

    @Value("${robert.server.captcha-challenge-timestamp-tolerance}")
    private Integer captchaChallengeTimestampTolerance;
}
