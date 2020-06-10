package fr.gouv.stopc.robert.crypto.grpc.server.service;

public interface ICryptoServerConfigurationService {

	/**
	 * TpStart in NTP seconds
	 * 
	 * @return the time the ROBERT service was started (permanent, never changes,
	 *         not tied to an instance)
	 */
	long getServiceTimeStart();

}
