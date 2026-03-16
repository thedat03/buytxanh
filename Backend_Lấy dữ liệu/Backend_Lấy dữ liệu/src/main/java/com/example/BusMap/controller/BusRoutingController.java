package com.example.BusMap.controller;

import com.example.BusMap.service.BusRoutingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.example.BusMap.Model.BusRouting;
import java.util.List;

@RestController
@RequestMapping("/busrouting")
public class BusRoutingController {

    @Autowired
    private BusRoutingService busRoutingService;

    @PostMapping("/save")
    public ResponseEntity<String> saveBusRouting() {
        try {
            busRoutingService.saveBusRouting();
            return ResponseEntity.ok("Bus routing data saved successfully.");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error saving bus routing data: " + e.getMessage());
        }
    }

    @PutMapping("/updateDetails")
    public ResponseEntity<BusRouting> updateBusRoutingDetails(@RequestBody BusRouting busRouting) {
        try {
            BusRouting updatedBusRouting = busRoutingService.updateBusRoutingWithDetails(
                    busRouting.getId(),
                    busRouting.getOperator(),
                    busRouting.getFrequency(),
                    busRouting.getPrice(),
                    busRouting.getOperatingHoursWeekday(),
                    busRouting.getOperatingHoursWeekend(),
                    busRouting.getRouteDescription(),
                    busRouting.getDepartureTimes()
            );
            return ResponseEntity.ok(updatedBusRouting);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(null);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }

    @GetMapping("/bus/{busId}")
    public ResponseEntity<List<BusRouting>> getBusRoutingByBusId(@PathVariable int busId) {
        try {
            List<BusRouting> busRoutings = busRoutingService.getBusRoutingByBusId(busId);
            if (busRoutings.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
            }
            return ResponseEntity.ok(busRoutings);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<BusRouting> getBusRoutingById(@PathVariable Long id) {
        try {
            BusRouting busRouting = busRoutingService.getBusRoutingById(id);
            return ResponseEntity.ok(busRouting);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(null);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    @GetMapping("/all")
    public ResponseEntity<List<BusRouting>> getAllBusRoutings() {
        try {
            List<BusRouting> busRoutings = busRoutingService.getAllBusRoutings();
            return ResponseEntity.ok(busRoutings);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
}
