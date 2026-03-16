package com.example.BusMap.controller;

import com.example.BusMap.service.BusStationService4;
import com.example.BusMap.service.BusStationService5;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class BusStationController4 {

    private final BusStationService4 busStationService4;

    public BusStationController4(BusStationService4 busStationService4) {
        this.busStationService4 = busStationService4;
    }

    // API để bắt đầu quá trình tạo và cập nhật danh sách số tuyến
    @GetMapping("/create-bus-number-list")
    public String createBusNumberList() {
        busStationService4.createBusNumberList();
        return "Bus number lists created and updated successfully.";
    }

}