package com.example.BusMap.controller;

import com.example.BusMap.service.BusService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class BusController {

    @Autowired
    private BusService busService;

    @GetMapping("/generate-bus-data")
    public String generateBusData() {
        busService.generateAndInsertBusData();
        return "Bus data generated successfully!";
    }
}