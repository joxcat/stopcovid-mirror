package fr.gouv.stopc.robert.server.common.service;

public interface IServerConfigurationService {

    /**
     *
     * @return The server key (192 bits, 24 bytes)
     */
    byte[] getServerKey();

    /**
     *
     * @return The federation key (256 bits, 32 bytes)
     */
    byte[] getFederationKey();

    /**
     * TpStart in NTP seconds
     * @return the time the ROBERT service was started (permanent, never changes, not tied to an instance)
     */
    long getServiceTimeStart();

    /**
     * Country code of the current application (1 byte)
     * @return
     */
    byte getServerCountryCode();

    /**
     * 
     * @return the time tolerance for the validation of helloMessage timestamp
     */
    int getHelloMessageTimeStampTolerance();

    /**
     * @return The duration of the contagious period CT (in days)
     */
    int getContagiousPeriod();

    /**
     * @return The duration of an epoch (in seconds)
     */
    int getEpochDurationSecs();

    /**
     *
     * @return The duration that must be covered by an epoch bundle returned in /register and /status (in days)
     */
    int getEpochBundleDurationInDays();

    /**
     * Get the tolerable time difference between a timestamp sent by the client and the current time on the server
     * @return
     */
    int getRequestTimeDeltaTolerance();

    /**
     * Get the minimum amount of epochs between two ESR requests
     * @return
     */
    int getStatusRequestMinimumEpochGap();

    /**
     *
     * @return the accepted time delay between the solving of a captcha and the verification
     */
    int getCaptchaChallengeTimestampTolerance();

    /**
     *
     * @return the risk threshold (theta) determining whether someone is at risk
     */
    double getRiskThreshold();
}
