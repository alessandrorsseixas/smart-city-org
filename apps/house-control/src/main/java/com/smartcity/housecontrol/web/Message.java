package com.smartcity.housecontrol.web;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class Message {
    private String title;
    private String detail;
}
