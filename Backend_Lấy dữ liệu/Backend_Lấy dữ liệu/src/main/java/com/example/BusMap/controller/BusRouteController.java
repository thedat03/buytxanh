package com.example.BusMap.controller;

import com.example.BusMap.Model.BusRouting;
import com.example.BusMap.service.BusRoutingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/bus-routes")
@CrossOrigin(origins = "*")
public class BusRouteController {

    private final BusRoutingService busRoutingService;

    @Autowired
    public BusRouteController(BusRoutingService busRoutingService) {
        this.busRoutingService = busRoutingService;
    }

    @GetMapping("/polyline")
    public ResponseEntity<BusRouting> getBusRoutePolyline(
            @RequestParam int busId) {
        List<BusRouting> routings = busRoutingService.getBusRoutingByBusId(busId);
        
        if (!routings.isEmpty()) {
            return ResponseEntity.ok(routings.get(0));
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/check-saved-routings")
    public ResponseEntity<List<BusRouting>> checkSavedRoutings() {
        List<BusRouting> allRoutings = busRoutingService.getAllBusRoutings();
        return ResponseEntity.ok(allRoutings);
    }

    @PostMapping("/generate-polylines")
    public ResponseEntity<String> generateAllBusRoutePolylines() {
        try {
            busRoutingService.generateAndSaveAllBusRoutePolylines();
            return ResponseEntity.ok("Successfully generated and saved all bus route polylines");
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error generating polylines: " + e.getMessage());
        }
    }
} 