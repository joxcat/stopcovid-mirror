package fr.gouv.stopc.robertserver.ws.controller;

import javax.validation.Valid;
import javax.ws.rs.Consumes;
import javax.ws.rs.Produces;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import fr.gouv.stopc.robertserver.ws.dto.CaptchaInternalCreationDto;
import fr.gouv.stopc.robertserver.ws.exception.RobertServerException;
import fr.gouv.stopc.robertserver.ws.utils.UriConstants;
import fr.gouv.stopc.robertserver.ws.vo.CaptchaInternalCreationVo;

@RestController
@RequestMapping(value = {"${controller.path.prefix}" + UriConstants.API_V2})
public interface ICaptchaController {

    @PostMapping(value = UriConstants.CAPTCHA)
    @Consumes(MediaType.APPLICATION_JSON_VALUE)
    @Produces(MediaType.APPLICATION_JSON_VALUE)
    ResponseEntity<CaptchaInternalCreationDto> createCaptcha(
            @Valid @RequestBody(required=true) CaptchaInternalCreationVo captchaInternalCreationVo)
            throws RobertServerException;

    @GetMapping(value = UriConstants.CAPTCHA + "/{captchaId}/image")
    //@Produces(MediaType.IMAGE_PNG_VALUE)
    ResponseEntity<byte[]> getCaptchaImage(
            @PathVariable("captchaId") String captchaId)
            throws RobertServerException;

    @GetMapping(value = UriConstants.CAPTCHA + "/{captchaId}/audio")
    //@Produces("audio/wav")
    ResponseEntity<byte[]> getCaptchaAudio(
            @PathVariable("captchaId") String captchaId)
            throws RobertServerException;
}
