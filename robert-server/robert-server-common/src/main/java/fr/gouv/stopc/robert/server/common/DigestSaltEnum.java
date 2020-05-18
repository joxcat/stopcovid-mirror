package fr.gouv.stopc.robert.server.common;

import java.util.HashMap;
import java.util.Map;

public enum DigestSaltEnum {
    HELLO((byte)0x01),
    STATUS((byte)0x02),
    UNREGISTER((byte)0x03),
    DELETE_HISTORY((byte)0x04);

    private final byte salt;
    private static Map map = new HashMap<>();
    DigestSaltEnum(byte salt) {
        this.salt = salt;
    }

    public byte getValue() { return salt; }

    static {
        for (DigestSaltEnum digestSalt : DigestSaltEnum.values()) {
            map.put(digestSalt.salt, digestSalt);
        }
    }

    public static DigestSaltEnum valueOf(byte val) {
        return (DigestSaltEnum) map.get(val);
    }
}
