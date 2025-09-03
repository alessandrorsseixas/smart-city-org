package com.smartcity.housecontrol.domain;

import lombok.Data;

@Data
public class Device {
    private String id;
    private String name;
    private DeviceType type;
    private DeviceState state;
    private int value;
}
