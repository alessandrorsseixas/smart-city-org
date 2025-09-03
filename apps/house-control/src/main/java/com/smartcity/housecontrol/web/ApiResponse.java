package com.smartcity.housecontrol.web;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApiResponse<T> {
    private boolean success;
    private T data;
    private Message message;

    public static <T> ApiResponse<T> ofSuccess(T data, Message message) {
        return new ApiResponse<>(true, data, message);
    }
}
