package br.com.smartcity.housecontrol.domain;

import lombok.Data;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;

@Data
@Entity
public class Device {
    @Id
    private String id;
    private String name;
    private DeviceType type;
    private DeviceState state;
    private Integer value;
}
