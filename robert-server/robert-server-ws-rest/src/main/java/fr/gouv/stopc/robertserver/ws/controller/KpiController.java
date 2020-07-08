package fr.gouv.stopc.robertserver.ws.controller;

import static fr.gouv.stopc.robertserver.ws.config.Config.API_V1;

import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import fr.gouv.stopc.robertserver.ws.service.IKpiService;
import fr.gouv.stopc.robertserver.ws.vo.RobertServerKpi;

/**
 * Endpoint definition for Kpi generation
 * 
 *
 */
@RestController
@RequestMapping(value = "${controller.internal.path.prefix}" + API_V1, consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
public class KpiController {

	/**
	 * The service for Kpi Generation
	 */
	private IKpiService kpiService;

	/**
	 * Spring Injection contructor
	 * 
	 * @param kpiService the Kpi service bean to use
	 */
	public KpiController(IKpiService kpiService) {
		this.kpiService = kpiService;
	}

	/**
	 * Generates the Kpis for Robert Server on a period
	 * 
	 * @param fromDate start date of the period
	 * @param toDate   end date of the period
	 */
	@GetMapping("/kpi")
	public ResponseEntity<List<RobertServerKpi>> getKpi(
			@RequestParam(name = "fromDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fromDate,
			@RequestParam(name = "toDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate) {
		return ResponseEntity.ok(kpiService.computeKpi(fromDate, toDate));
	}
}
