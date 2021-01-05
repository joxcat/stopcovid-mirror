package fr.gouv.stopc.robertserver.ws.controller.impl;

import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Date;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import fr.gouv.stopc.robertserver.ws.config.WsServerConfiguration;
import fr.gouv.stopc.robertserver.ws.controller.IReportControllerV4;
import fr.gouv.stopc.robertserver.ws.dto.ReportBatchResponseV4Dto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.service.ContactDtoService;
import fr.gouv.stopc.robertserver.ws.utils.MessageConstants;
import fr.gouv.stopc.robertserver.ws.vo.ReportBatchRequestVo;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class ReportControllerV4Impl implements IReportControllerV4 {

    public static final SignatureAlgorithm signatureAlgo = SignatureAlgorithm.RS256;

    private final  WsServerConfiguration wsServerConfiguration;

    private final ReportControllerDelegate delegate;

    private final ContactDtoService contactDtoService;

    private PrivateKey jwtPrivateKey;

    public ReportControllerV4Impl(final ContactDtoService contactDtoService,
            final WsServerConfiguration wsServerConfiguration,
            final ReportControllerDelegate delegate) {

        this.contactDtoService = contactDtoService;
        this.wsServerConfiguration = wsServerConfiguration;
        this.delegate = delegate;
    }

    @Override
    public ResponseEntity<ReportBatchResponseV4Dto> reportContactHistory(ReportBatchRequestVo reportBatchRequestVo) throws RobertServerException {
        if ( ! delegate.isReportRequestValid(reportBatchRequestVo) ) 
            return ResponseEntity.badRequest().build();

        contactDtoService.saveContacts(reportBatchRequestVo.getContacts());

        String token = generateJWT(reportBatchRequestVo);

        ReportBatchResponseV4Dto reportBatchResponseDto = ReportBatchResponseV4Dto.builder()
                .message(MessageConstants.SUCCESSFUL_OPERATION.getValue())
                .reportValidationToken(token)
                .success(Boolean.TRUE)
                .build();

        return ResponseEntity.ok(reportBatchResponseDto);
    }

    private String generateJWT(ReportBatchRequestVo reportBatchRequestVo) throws RobertServerException {
        try {
            Date now = new Date();
            Date expiration = new Date(now.getTime() + this.wsServerConfiguration.getJwtLifeTime() * 60000);

            String token = Jwts.builder()
                    .setHeaderParam("type", "JWT")
                    .setIssuedAt(now)
                    .setExpiration(expiration)
                    .signWith(this.getJwtPrivateKey(), signatureAlgo)
                    .compact();

            return token;
        } catch (Exception e) {
            log.error("JWT token generation failed!", e);
            // Avoid to send an HTTP Error code to the client if only the report validation token generation fails
            return ""; 
        }
    }

    protected PrivateKey getJwtPrivateKey() throws NoSuchAlgorithmException, InvalidKeySpecException {
        if (this.jwtPrivateKey != null)
            return this.jwtPrivateKey;

        if (this.wsServerConfiguration.getJwtUseTransientKey()) {
            // In test mode, we generate a transient key
            KeyPair keyPair = Keys.keyPairFor(signatureAlgo);
            this.jwtPrivateKey = keyPair.getPrivate();
        } else {
            byte[] encoded = Decoders.BASE64.decode(this.wsServerConfiguration.getJwtPrivateKey());
            KeyFactory keyFactory = KeyFactory.getInstance(signatureAlgo.getFamilyName());
            PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(encoded);
            this.jwtPrivateKey = keyFactory.generatePrivate(keySpec);
        }
        return this.jwtPrivateKey;
    }
}
