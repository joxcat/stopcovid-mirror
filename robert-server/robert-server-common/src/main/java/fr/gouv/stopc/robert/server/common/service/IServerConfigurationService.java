package fr.gouv.stopc.robert.server.common.service;

public interface IServerConfigurationService {

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
     * @return The duration of an epoch (in seconds)
     */
    int getEpochDurationSecs();

    /**
     *
     * @return The duration that must be covered by an epoch bundle returned in /register and /status (in days)
     */
    int getEpochBundleDurationInDays();

}
