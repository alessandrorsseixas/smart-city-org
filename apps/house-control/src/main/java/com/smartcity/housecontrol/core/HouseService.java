package com.smartcity.housecontrol.core;

import org.springframework.stereotype.Service;

@Service
public class HouseService {

    public String getStatus(){
        return "All systems operational";
    }
}
