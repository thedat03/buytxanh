package busmap2.example.busmap2.controller;

import busmap2.example.busmap2.Model.Bus;
import busmap2.example.busmap2.service.BusService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
public class BusController {

    @Autowired
    private BusService busService;

    @GetMapping("/get_bus_id")
    public ResponseEntity<?> getBusIdByBusNumberAndDriver(@RequestParam(required = true) String busNumber,
                                                         @RequestParam(required = true) String driverName) {
        return busService.getBusIdByBusNumberAndDriver(busNumber, driverName);
    }

    @GetMapping("/get_bus_info_by_bus_number")
    public ResponseEntity<?> getBusInformationByBusNumber(@RequestParam(value = "bus_number", required = true) String busNumber) {
        return busService.getBusInformationByBusNumber(busNumber);
    }

    @GetMapping("/get_bus_information_by_id")
    public ResponseEntity<?> getBusInformationById(@RequestParam(required = true) Integer busId) {
        return busService.getBusInformationById(busId);
    }

    @GetMapping("/get_list_bus_bus_number")
    public ResponseEntity<?> getBusNumber(@RequestParam(required = true) String bus_number) {
        return busService.getBusNumber(bus_number);
    }

}
