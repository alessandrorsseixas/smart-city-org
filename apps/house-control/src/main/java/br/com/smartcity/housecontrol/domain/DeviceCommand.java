package br.com.smartcity.housecontrol.domain;

import lombok.Data;

@Data
public class DeviceCommand {
    private String deviceId;
    private String action; // e.g. ON, OFF, SET_TEMPERATURE
    private Integer value; // optional
}
