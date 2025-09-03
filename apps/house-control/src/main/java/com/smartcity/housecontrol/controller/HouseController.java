package com.smartcity.housecontrol.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/house")
public class HouseController {

    @GetMapping("/status")
    public String status() {
        return "House Control OK";
    }
}
