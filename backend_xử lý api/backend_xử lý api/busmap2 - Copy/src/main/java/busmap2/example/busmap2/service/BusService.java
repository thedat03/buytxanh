package busmap2.example.busmap2.service;

import busmap2.example.busmap2.Model.Bus;
import busmap2.example.busmap2.Model.OnBusPassengerData;
import busmap2.example.busmap2.repository.BusRepository;
import busmap2.example.busmap2.repository.OnBusPassengerDataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class BusService {

    @Autowired
    private BusRepository busRepository;

    @Autowired
    private OnBusPassengerDataRepository onBusPassengerDataRepository;

    // Get bus information by bus_number and driver_name
    public ResponseEntity<?> getBusInformation(String busNumber, String driverName) {
        Optional<Bus> busOpt = busRepository.findByBusNumberAndDriverName(busNumber, driverName);
        if (!busOpt.isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "Bus not found"));
        }

        Bus bus = busOpt.get();
        Map<String, Object> response = new HashMap<>();
        response.put("current_passenger_amount", bus.getCurrentPassengerAmount());
        response.put("max_passenger_amount", bus.getMaxPassengerAmount());
        response.put("speed", bus.getSpeed());
        response.put("status", 200);
        return ResponseEntity.ok(response);
    }

    // Update bus information
    public ResponseEntity<?> updateBus(Bus bus) {
        if (bus.getBusId() == 0 || bus.getSpeed() == 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "bus_number, driver_name, speed are required"));
        }

        Optional<Bus> existingBusOpt = busRepository.findById(bus.getBusId());
        if (existingBusOpt.isPresent()) {
            Bus existingBus = existingBusOpt.get();
            existingBus.setSpeed(bus.getSpeed());
            existingBus.setCurrentLongitude(bus.getCurrentLongitude());
            existingBus.setCurrentLatitude(bus.getCurrentLatitude());
            busRepository.save(existingBus);
            return ResponseEntity.ok(Map.of("status", 200, "message", "Update bus successfully"));
        } else {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "Bus not found"));
        }
    }

    // Update current passenger amount
    public ResponseEntity<?> updateCurrentPassengerAmount(Integer busId, int getOffAmount, int typeUpdate) {
        Optional<Bus> busOpt = busRepository.findById(busId);
        if (!busOpt.isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "Bus not found"));
        }

        Bus bus = busOpt.get();
        if (typeUpdate == 0) {
            bus.setCurrentPassengerAmount(0);
        } else {
            bus.setCurrentPassengerAmount(bus.getCurrentPassengerAmount() - getOffAmount);
        }
        busRepository.save(bus);
        return ResponseEntity.ok(Map.of("status", 200, "message", "Update current_passenger_amount successfully"));
    }

    // Get bus id by bus_number and driver_name
    public ResponseEntity<?> getBusIdByBusNumberAndDriver(String busNumber, String driverName) {
        if (busNumber == null || driverName == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "param bus_number, driver_name are required"));
        }

        Optional<Bus> busOpt = busRepository.findByBusNumberAndDriverName(busNumber, driverName);
        if (!busOpt.isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "Bus not found"));
        }

        Bus bus = busOpt.get();
        return ResponseEntity.ok(Map.of("bus_id", bus.getBusId(), "status", 200));
    }

    // Get bus information by bus_number
    public ResponseEntity<?> getBusInformationByBusNumber(String busNumber) {
        if (busNumber == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "param bus_number is required"));
        }

        List<Bus> busList = busRepository.findByBusNumberContaining(busNumber);
        if (busList.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "Bus not found"));
        }

        List<Map<String, Object>> result = busList.stream().map(bus -> {
            Map<String, Object> busData = new HashMap<>();
            busData.put("bus_id", bus.getBusId());
            busData.put("bus_number", bus.getBusNumber());
            busData.put("driver_name", bus.getDriverName());
            busData.put("speed", bus.getSpeed());
            busData.put("current_latitude", bus.getCurrentLatitude());
            busData.put("current_longitude", bus.getCurrentLongitude());
            busData.put("current_passenger_amount", bus.getCurrentPassengerAmount());
            busData.put("max_passenger_amount", bus.getMaxPassengerAmount());
            busData.put("bus_number_name", bus.getBusNumberName());
            busData.put("direction", bus.getDirection());
            return busData;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(Map.of("status", 200, "data", result));
    }

    // Get bus information by bus_id
    public ResponseEntity<?> getBusInformationById(Integer busId) {
        if (busId == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "param bus_id is required"));
        }

        Optional<Bus> busOpt = busRepository.findById(busId);
        if (!busOpt.isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "Bus not found"));
        }

        Bus bus = busOpt.get();
        Map<String, Object> busData = new HashMap<>();
        busData.put("bus_number", bus.getBusNumber());
        busData.put("driver_name", bus.getDriverName());
        busData.put("speed", bus.getSpeed());
        busData.put("current_longitude", bus.getCurrentLongitude());
        busData.put("current_latitude", bus.getCurrentLatitude());
        busData.put("current_passenger_amount", bus.getCurrentPassengerAmount());
        busData.put("max_passenger_amount", bus.getMaxPassengerAmount());
        busData.put("bus_number_name", bus.getBusNumberName());
        busData.put("direction", bus.getDirection());
        busData.put("status", 200);

        return ResponseEntity.ok(busData);
    }

    // Get bus numbers by bus_number
    @Transactional
    public ResponseEntity<?> getBusNumber(String busNumber) {
        try {
            List<Bus> buses = busRepository.findByBusNumberContaining(busNumber);
            
            if (buses.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            
            List<Map<String, Object>> result = buses.stream().map(bus -> {
                Map<String, Object> busData = new HashMap<>();
                busData.put("bus_id", bus.getBusId());
                busData.put("bus_number", bus.getBusNumber());
                busData.put("driver_name", bus.getDriverName());
                busData.put("speed", bus.getSpeed());
                busData.put("current_latitude", bus.getCurrentLatitude());
                busData.put("current_longitude", bus.getCurrentLongitude());
                busData.put("current_passenger_amount", bus.getCurrentPassengerAmount());
                busData.put("max_passenger_amount", bus.getMaxPassengerAmount());
                busData.put("direction", bus.getDirection());
                busData.put("bus_number_name", bus.getBusNumberName());
                return busData;
            }).collect(Collectors.toList());
            
            return ResponseEntity.ok(Map.of("status", 200, "data", result));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error retrieving bus information: " + e.getMessage());
        }
    }

    // Update passenger amount and save it
    public ResponseEntity<?> updatePassengerAmount(Integer busId, String busNumber) {
        Optional<Bus> busOpt = busRepository.findById(busId);
        if (!busOpt.isPresent()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "Bus not found"));
        }

        Bus bus = busOpt.get();
        OnBusPassengerData passengerData = new OnBusPassengerData();
        passengerData.setBusId(busId);
        passengerData.setBusNumber(busNumber);
        passengerData.setPassengerAmount(bus.getCurrentPassengerAmount());
        
        try {
            onBusPassengerDataRepository.save(passengerData);
            return ResponseEntity.ok(Map.of("status", 200, "message", "Update passenger amount successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "Update passenger amount failed"));
        }
    }
}
