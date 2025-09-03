package com.smartcity.housecontrol.adapter.in.web;

import com.smartcity.housecontrol.application.port.in.HouseUseCasePortIn;
import com.smartcity.housecontrol.domain.DeviceCommand;
import com.smartcity.housecontrol.domain.House;
import com.smartcity.housecontrol.web.ApiResponse;
import com.smartcity.housecontrol.web.Message;
import lombok.RequiredArgsConstructor;
import org.springframework.hateoas.server.mvc.WebMvcLinkBuilder;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/houses")
@RequiredArgsConstructor
public class HouseController {

    private final HouseUseCasePortIn houseUseCase;

    @GetMapping
    public ResponseEntity<ApiResponse<List<House>>> getAll() {
        var houses = houseUseCase.getAllHouses();
        houses.forEach(h -> h.add(WebMvcLinkBuilder.linkTo(WebMvcLinkBuilder.methodOn(HouseController.class).getAll()).withSelfRel()));
        return ResponseEntity.ok(ApiResponse.ofSuccess(houses, new Message("Sucesso","Lista de casas")));
    }

    @GetMapping("/{houseId}")
    public ResponseEntity<ApiResponse<House>> getById(@PathVariable String houseId) {
        var house = houseUseCase.getHouseById(houseId).orElseThrow(() -> new RuntimeException("Casa não encontrada"));
        house.add(WebMvcLinkBuilder.linkTo(WebMvcLinkBuilder.methodOn(HouseController.class).getById(houseId)).withSelfRel());
        return ResponseEntity.ok(ApiResponse.ofSuccess(house, new Message("Sucesso","Casa encontrada")));
    }

    @PatchMapping("/{houseId}/devices/{deviceId}")
    public ResponseEntity<ApiResponse<Void>> patchDevice(@PathVariable String houseId, @PathVariable String deviceId, @RequestBody DeviceCommand command) {
        houseUseCase.updateDeviceState(houseId, deviceId, command);
        return ResponseEntity.accepted().body(ApiResponse.ofSuccess(null, new Message("Comando Enviado","O comando foi enfileirado")));
    }
}
