package smart.city.org.eletric.control.controller;

import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import smart.city.org.eletric.control.entities.EnergySource;
import smart.city.org.eletric.control.services.EnergySourceService;

import java.util.List;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

@RestController
@RequestMapping("/energysources")
public class EnergySourceController {

    @Autowired
    private EnergySourceService energySourceService;


    @GetMapping
    public ResponseEntity<List<EnergySource>> findAll() {
        List<EnergySource> energySources = energySourceService.findAll();

        return ResponseEntity.ok(energySources);
    }

    @PostMapping
    public ResponseEntity<EnergySource> save(@Valid @RequestBody EnergySource energySource) {

        EnergySource newEnergySource = energySourceService.create(energySource);

        return ResponseEntity.created(null).body(newEnergySource);
    }




}
