package fr.gouv.stopc.robert.server.crypto.model;

/**
 * Structure aggregating values that are returned to apps for consumption.
 * Each (EBID, ECC) tuple is tied to an epoch id.
 * Once the values are set at instantiation they cannot be change to preserve their integrity between each other
 */
public class EphemeralTuple {
    private final int epochId;
    private final byte[] ebid;
    private final byte[] encryptedCountryCode;

    /**
     * Default constructor given the three link attributes epoch, ebid, ecc
     * @param epochId Identifier of the epoch for which EBID and ECC are valid
     * @param ebid Ephemeral Bluetooth IDentifier of user UA for the given epoch
     * @param encryptedCountryCode Encrypted Country Code used by UA for the given epoch
     */
    public EphemeralTuple(int epochId, byte[] ebid, byte[] encryptedCountryCode) {
        this.epochId = epochId;
        this.ebid = ebid;
        this.encryptedCountryCode = encryptedCountryCode;
    }

    public int getEpoch() {
        return epochId;
    }

    public byte[] getEbid() {
        return ebid;
    }

    public byte[] getEncryptedCountryCode() {
        return encryptedCountryCode;
    }
}
