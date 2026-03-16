package com.example.BusMap.controller;

import com.example.BusMap.service.BusStationService5;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class BusStationController5 {

    private final BusStationService5 busStationService5;
    @Autowired
    public BusStationController5(BusStationService5 busStationService5) {
        this.busStationService5 = busStationService5;
    }

    @GetMapping("/updateBusNumbers")
    public String updateBusNumbers() {
        busStationService5.updateBusNumbers();
        return "Bus numbers updated successfully!";
    }
}
