package busmap2.example.busmap2.controller;

import busmap2.example.busmap2.Model.BusRouting;
import busmap2.example.busmap2.service.BusRoutingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/bus-routing")
public class BusRoutingController {

    @Autowired
    private BusRoutingService busRoutingService;

    @GetMapping("/{busId}")
    public ResponseEntity<BusRouting> getBusRoutingDetails(@PathVariable int busId) {
        try {
            BusRouting busRouting = busRoutingService.getBusRoutingDetails(busId);
            return ResponseEntity.ok(busRouting);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/all")
    public ResponseEntity<List<BusRouting>> getAllBusRoutings() {
        List<BusRouting> busRoutings = busRoutingService.getAllBusRoutings();
        return ResponseEntity.ok(busRoutings);
    }

    @PutMapping("/{id}")
    public ResponseEntity<BusRouting> updateBusRoutingDetails(
            @PathVariable Long id,
            @RequestParam String operator,
            @RequestParam String frequency,
            @RequestParam String price,
            @RequestParam String operatingHoursWeekday,
            @RequestParam String operatingHoursWeekend,
            @RequestParam String routeDescription,
            @RequestParam String departureTimes) {
        try {
            BusRouting updatedBusRouting = busRoutingService.updateBusRoutingDetails(
                    id, operator, frequency, price, operatingHoursWeekday,
                    operatingHoursWeekend, routeDescription, departureTimes);
            return ResponseEntity.ok(updatedBusRouting);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}
