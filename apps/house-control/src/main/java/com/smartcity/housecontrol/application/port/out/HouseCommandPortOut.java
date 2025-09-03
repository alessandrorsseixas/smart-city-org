package com.smartcity.housecontrol.application.port.out;

import com.smartcity.housecontrol.domain.DeviceCommand;

public interface HouseCommandPortOut {
    void sendDeviceCommand(DeviceCommand command);
}
