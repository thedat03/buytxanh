package busmap2.example.busmap2.controller;

import busmap2.example.busmap2.service.OnBusService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/on-bus")
public class OnBusController {

    @Autowired
    private OnBusService onBusService;

    @PostMapping("/get-on")
    public ResponseEntity<?> getOnBus(@RequestBody Map<String, Integer> request) {
        Integer ticketId = request.get("ticket_id");
        Integer busId = request.get("bus_id");
        return onBusService.getOnBus(ticketId, busId);
    }

    @PostMapping("/get-off")
    public ResponseEntity<?> getOffBus(@RequestBody Map<String, Integer> request) {
        Integer busStationId = request.get("bus_station_id");
        Integer busId = request.get("bus_id");
        return onBusService.getOffBus(busStationId, busId);
    }
} 