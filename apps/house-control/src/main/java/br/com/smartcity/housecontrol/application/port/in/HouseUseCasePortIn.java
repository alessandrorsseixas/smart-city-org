package br.com.smartcity.housecontrol.application.port.in;

import br.com.smartcity.housecontrol.domain.House;
import br.com.smartcity.housecontrol.domain.DeviceCommand;

import java.util.List;
import java.util.Optional;

public interface HouseUseCasePortIn {
    List<House> getAllHouses();
    Optional<House> getHouseById(String houseId);
    void updateDeviceState(String houseId, String deviceId, DeviceCommand command);
}
