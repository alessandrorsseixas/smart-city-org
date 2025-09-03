package com.smartcity.housecontrol.application.port.out;

import com.smartcity.housecontrol.domain.House;

import java.util.List;
import java.util.Optional;

public interface HouseStatePortOut {
    List<House> findAll();
    Optional<House> findById(String houseId);
    void save(House house);
}
