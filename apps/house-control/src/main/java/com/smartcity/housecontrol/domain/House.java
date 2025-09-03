package com.smartcity.housecontrol.domain;

import lombok.Data;
import org.springframework.hateoas.RepresentationModel;

import java.util.List;

@Data
public class House extends RepresentationModel<House> {
    private String id;
    private String name;
    private List<Device> devices;
}
