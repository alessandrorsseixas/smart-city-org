package smart.city.org.eletric.control.controller;


import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import smart.city.org.eletric.control.entities.Battery;
import smart.city.org.eletric.control.entities.EnergySource;
import smart.city.org.eletric.control.services.BatteryService;
import smart.city.org.eletric.control.services.EnergySourceService;

import java.util.List;

@RestController
@RequestMapping("/bateries")
public class BatteryController {


    @Autowired
    private BatteryService batteryService;

    @GetMapping
    public ResponseEntity<List<Battery>> findAll() {
        List<Battery> bateries = batteryService.findAll();

        return ResponseEntity.ok(bateries);
    }

    @PostMapping
    public ResponseEntity<Battery> save(@Valid @RequestBody Battery battery) {

        Battery newBattery = batteryService.create(battery);

        return ResponseEntity.created(null).body(newBattery);
    }
}
