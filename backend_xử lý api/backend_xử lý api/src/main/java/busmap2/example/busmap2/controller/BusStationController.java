package busmap2.example.busmap2.controller;

import busmap2.example.busmap2.Model.BusStation;
import busmap2.example.busmap2.service.BusStationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
public class BusStationController {

    @Autowired
    private BusStationService busStationService;

    @GetMapping("/get_all_bus_station")
    public ResponseEntity<?> getAllBusStations() {
        return busStationService.getAllBusStations();
    }

    @PostMapping("/bus_station")
    public ResponseEntity<?> BusStationView(@RequestBody BusStation busStation) {
        return busStationService.BusStationView(busStation);
    }

    @GetMapping("/get_station_id")
    public ResponseEntity<?> GetBusStationIdView(
            @RequestParam String name) {
        return busStationService.GetBusStationIdView(name);
    }

    @GetMapping("/get_station_by_bus_number")
    public ResponseEntity<?> GetStationByBusNumber(
            @RequestParam(required = false, defaultValue = "") String busNumber) {
        return busStationService.GetStationByBusNumber(busNumber);
    }

    @GetMapping("/get_bus_station_by_name")
    public ResponseEntity<?> GetBusStationByNameView(
            @RequestParam String name) {
        return busStationService.GetBusStationByNameView(name);
    }

    @GetMapping("/get_bus_station_by_bus_number")
    public ResponseEntity<?> GetBusStationByBusNumberView(
            @RequestParam(required = false, defaultValue = "") String busNumber,
            @RequestParam(required = false) Integer direction) {
        return busStationService.GetBusStationByBusNumberView(busNumber, direction);
    }

    @GetMapping("/get_upcoming_bus_information")
    public ResponseEntity<?> GetUpcomingBusInfomationView(
            @RequestParam(required = false, defaultValue = "") String busStationName) {
        return busStationService.GetUpcomingBusInfomationView(busStationName);
    }
    @GetMapping("/find_bus_station_by_name")
    public ResponseEntity<?> FindBusStationByNameView(
            @RequestParam(required = false, defaultValue = "") String name) {
        return busStationService.FindBusStationByNameView(name);
    }
} 