package fr.gouv.stopc.robertserver.ws.utils;

public final class UriConstants {

    private UriConstants() {

        throw new AssertionError();
    }

    public static final String REPORT = "/report";

    public static final String STATUS = "/status";

    public static final String REGISTER = "/register";

    public static final String UNREGISTER = "/unregister";

    public static final String DELETE_HISTORY = "/deleteExposureHistory";

    public static final String CAPTCHA = "/captcha";

    public static final String API_V1 = "/v1";

    public static final String API_V2 = "/v2";

    public static final String API_V3 = "/v3";

}
