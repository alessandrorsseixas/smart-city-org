package br.com.smartcity.housecontrol.application.port.out;

import br.com.smartcity.housecontrol.domain.DeviceCommand;

public interface HouseCommandPortOut {
    void sendDeviceCommand(DeviceCommand command);
}
