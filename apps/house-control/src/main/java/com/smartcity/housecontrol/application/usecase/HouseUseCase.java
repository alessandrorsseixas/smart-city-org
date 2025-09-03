package com.smartcity.housecontrol.application.usecase;

import com.smartcity.housecontrol.application.port.in.HouseUseCasePortIn;
import com.smartcity.housecontrol.application.port.out.HouseCommandPortOut;
import com.smartcity.housecontrol.application.port.out.HouseStatePortOut;
import com.smartcity.housecontrol.domain.DeviceCommand;
import com.smartcity.housecontrol.domain.House;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class HouseUseCase implements HouseUseCasePortIn {

    private final HouseStatePortOut houseStatePort;
    private final HouseCommandPortOut houseCommandPort;

    @Override
    public List<House> getAllHouses() {
        return houseStatePort.findAll();
    }

    @Override
    public java.util.Optional<House> getHouseById(String houseId) {
        return houseStatePort.findById(houseId);
    }

    @Override
    public void updateDeviceState(String houseId, String deviceId, DeviceCommand command) {
        var houseOpt = houseStatePort.findById(houseId);
        var house = houseOpt.orElseThrow(() -> new RuntimeException("Casa não encontrada"));
        // domain validations could be more complex
        // create enriched command and send
        command.setDeviceId(deviceId);
        houseCommandPort.sendDeviceCommand(command);
    }
}
