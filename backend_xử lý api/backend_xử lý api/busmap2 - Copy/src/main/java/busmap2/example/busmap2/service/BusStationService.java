package busmap2.example.busmap2.service;

import busmap2.example.busmap2.Model.BusStation;
import busmap2.example.busmap2.Model.Bus;
import busmap2.example.busmap2.Model.Ticket;
import busmap2.example.busmap2.Model.OnBusData;
import busmap2.example.busmap2.repository.BusStationRepository;
import busmap2.example.busmap2.repository.BusRepository;
import busmap2.example.busmap2.repository.TicketRepository;
import busmap2.example.busmap2.repository.OnBusDataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


@Service
public class BusStationService {

    @Autowired
    private BusStationRepository busStationRepository;

    @Autowired
    private BusRepository busRepository;

    @Autowired
    private TicketRepository ticketRepository;

    @Autowired
    private OnBusDataRepository onBusDataRepository;

    public ResponseEntity<?> GetOnBusView(String ticketId, String busId) {
        OnBusData onBusData = onBusDataRepository.findByTicketId(Integer.parseInt(ticketId));
        if (onBusData != null) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 400);
            response.put("message", "this user is on bus");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        Ticket ticket = ticketRepository.findById(Integer.parseInt(ticketId)).orElse(null);
        if (ticket == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 400);
            response.put("message", "this ticket is not valid");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        ticket.setBusId(Integer.parseInt(busId));
        ticketRepository.save(ticket);

        Bus bus = busRepository.findById(Integer.parseInt(busId)).orElse(null);
        if (bus != null) {
            bus.setCurrentPassengerAmount(bus.getCurrentPassengerAmount() + 1);
            busRepository.save(bus);
        }

        Map<String, Object> response = new HashMap<>();
        response.put("status", 200);
        response.put("message", "Get on bus successfully");
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    public ResponseEntity<?> GetOffBusView(String busStationId, String busId) {
        if (busStationId == null || busId == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 400);
            response.put("message", "bus_station_id, bus_id is required");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            List<Ticket> ticketList = ticketRepository.findByStatusAndBusId(0, Integer.parseInt(busId));
            if (ticketList.isEmpty()) {
                Map<String, Object> response = new HashMap<>();
                response.put("status", 400);
                response.put("message", "this bus is empty");
                return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
            }

            Bus bus = busRepository.findById(Integer.parseInt(busId)).orElse(null);
            if (bus == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("status", 400);
                response.put("message", "bus number not found");
                return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
            }

            int count = 0;
            for (Ticket ticket : ticketList) {
                Integer ticketId = ticket.getTicketId();
                // Logic for getting off bus
                OnBusData onBusData = onBusDataRepository.findByTicketId(ticketId);
                if (onBusData != null) {
                    onBusDataRepository.delete(onBusData);
                    bus.setCurrentPassengerAmount(bus.getCurrentPassengerAmount() - 1);
                    busRepository.save(bus);
                    count++;
                }
            }

            if (count == 0) {
                Map<String, Object> response = new HashMap<>();
                response.put("status", 400);
                response.put("message", "get of 0 passenger");
                return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("status", 200);
            response.put("message", "Get off bus successfully");
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 400);
            response.put("message", "this user is not on bus");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }
    }

    public ResponseEntity<?> getAllBusStations() {
        try {
            List<BusStation> stations = busStationRepository.findAll();
            List<Map<String, Object>> formattedStations = new ArrayList<>();

            for (BusStation station : stations) {
                Map<String, Object> stationData = new HashMap<>();
                stationData.put("bus_station_id", station.getBusStationId());
                stationData.put("name", station.getName());
                stationData.put("latitude", station.getLatitude());
                stationData.put("longitude", station.getLongitude());
                stationData.put("bus_number", station.getBusNumber());
                stationData.put("direction", station.getDirection());
                
                // Tạo danh sách số xe buýt cho lượt đi và lượt về
                List<String> busNumbersGo = new ArrayList<>();
                List<String> busNumbersReturn = new ArrayList<>();
                
                // Lấy tất cả các trạm có cùng tên
                List<BusStation> sameNameStations = busStationRepository.findByNameContaining(station.getName());
                for (BusStation s : sameNameStations) {
                    if (s.getDirection() == 0) {
                        busNumbersGo.add(s.getBusNumber());
                    } else {
                        busNumbersReturn.add(s.getBusNumber());
                    }
                }
                
                stationData.put("bus_number_list_go", busNumbersGo);
                stationData.put("bus_number_list_return", busNumbersReturn);
                
                formattedStations.add(stationData);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("status", 200);
            response.put("data", formattedStations);
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 500);
            response.put("message", "Lỗi khi lấy danh sách trạm xe buýt: " + e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    public ResponseEntity<?> BusStationView(BusStation busStation) {
        try {
            if (busStation.getName() == null || 
                busStation.getLatitude() == 0.0 || 
                busStation.getLongitude() == 0.0 || 
                busStation.getBusNumber() == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("status", 400);
                response.put("message", "bus_number, name, latitude, longitude are required");
                return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
            }

            BusStation existingStation = busStationRepository.findByNameAndBusNumber(
                busStation.getName(), busStation.getBusNumber());
            
            if (existingStation != null) {
                Map<String, Object> response = new HashMap<>();
                response.put("status", 400);
                response.put("message", "bus station is existed");
                return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
            }

            busStationRepository.save(busStation);
            Map<String, Object> response = new HashMap<>();
            response.put("status", 200);
            response.put("message", "add bus station successfully");
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 400);
            response.put("message", "add bus station failed: " + e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }
    }

    public ResponseEntity<?> GetBusStationIdView(String name) {
        if (name == null || name.trim().isEmpty()) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 400);
            response.put("message", "Tên trạm là bắt buộc");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            List<BusStation> stations = busStationRepository.findByNameContaining(name.trim());
            if (stations.isEmpty()) {
                Map<String, Object> response = new HashMap<>();
                response.put("status", 404);
                response.put("message", "Không tìm thấy trạm xe buýt");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("status", 200);
            response.put("data", stations);
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 500);
            response.put("message", "Lỗi khi tìm kiếm trạm xe buýt: " + e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    public ResponseEntity<?> GetStationByBusNumber(String busNumber) {
        // If busNumber is empty, return all stations
        if (busNumber == null || busNumber.trim().isEmpty()) {
            List<BusStation> allStations = busStationRepository.findAll();
            Map<String, Object> response = new HashMap<>();
            response.put("status", 200);
            response.put("data", allStations);
            return new ResponseEntity<>(response, HttpStatus.OK);
        }

        List<BusStation> stations = busStationRepository.findByBusNumber(busNumber);
        Map<String, Object> response = new HashMap<>();
        response.put("status", 200);
        response.put("data", stations);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    public ResponseEntity<?> GetBusStationByNameView(String name) {
        if (name == null || name.trim().isEmpty()) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 400);
            response.put("message", "Tên trạm là bắt buộc");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            List<BusStation> stations = busStationRepository.findByNameContaining(name.trim());
            if (stations.isEmpty()) {
                Map<String, Object> response = new HashMap<>();
                response.put("status", 404);
                response.put("message", "Không tìm thấy trạm xe buýt");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            List<Map<String, Object>> formattedStations = new ArrayList<>();
            for (BusStation station : stations) {
                Map<String, Object> stationData = new HashMap<>();
                stationData.put("bus_station_id", station.getBusStationId());
                stationData.put("name", station.getName());
                stationData.put("latitude", station.getLatitude());
                stationData.put("longitude", station.getLongitude());
                stationData.put("bus_number", station.getBusNumber());
                stationData.put("direction", station.getDirection());

                // Get bus information including busId
                List<Bus> buses = busRepository.findByBusNumber(station.getBusNumber());
                if (!buses.isEmpty()) {
                    Bus bus = buses.get(0);
                    stationData.put("bus_id", bus.getBusId());
                    stationData.put("bus_number_name", bus.getBusNumberName());
                    stationData.put("driver_name", bus.getDriverName());
                    stationData.put("current_passenger_amount", bus.getCurrentPassengerAmount());
                    stationData.put("max_passenger_amount", bus.getMaxPassengerAmount());
                    stationData.put("current_latitude", bus.getCurrentLatitude());
                    stationData.put("current_longitude", bus.getCurrentLongitude());
                    stationData.put("speed", bus.getSpeed());
                }

                formattedStations.add(stationData);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("status", 200);
            response.put("data", formattedStations);
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 500);
            response.put("message", "Lỗi khi tìm kiếm trạm xe buýt: " + e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    public ResponseEntity<?> GetBusStationByBusNumberView(String busNumber, Integer direction) {
        try {
            List<BusStation> stations;
            
            // If busNumber is empty, return all stations
            if (busNumber == null || busNumber.trim().isEmpty()) {
                stations = busStationRepository.findAll();
            }
            // If direction is null, return stations by bus number only
            else if (direction == null) {
                stations = busStationRepository.findByBusNumber(busNumber);
            }
            // Return stations by bus number and direction
            else {
                stations = busStationRepository.findByBusNumberAndDirection(busNumber, direction);
            }

            List<Map<String, Object>> formattedStations = new ArrayList<>();
            for (BusStation station : stations) {
                Map<String, Object> stationData = new HashMap<>();
                stationData.put("bus_station_id", station.getBusStationId());
                stationData.put("name", station.getName());
                stationData.put("latitude", station.getLatitude());
                stationData.put("longitude", station.getLongitude());
                stationData.put("bus_number", station.getBusNumber());
                stationData.put("direction", station.getDirection());

                // Get bus information including busId
                List<Bus> buses = busRepository.findByBusNumber(station.getBusNumber());
                if (!buses.isEmpty()) {
                    Bus bus = buses.get(0);
                    stationData.put("bus_id", bus.getBusId());
                    stationData.put("bus_number_name", bus.getBusNumberName());
                    stationData.put("driver_name", bus.getDriverName());
                    stationData.put("current_passenger_amount", bus.getCurrentPassengerAmount());
                    stationData.put("max_passenger_amount", bus.getMaxPassengerAmount());
                    stationData.put("current_latitude", bus.getCurrentLatitude());
                    stationData.put("current_longitude", bus.getCurrentLongitude());
                    stationData.put("speed", bus.getSpeed());
                }

                formattedStations.add(stationData);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("status", 200);
            response.put("data", formattedStations);
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 500);
            response.put("message", "Lỗi khi lấy thông tin trạm xe buýt: " + e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    public ResponseEntity<?> GetUpcomingBusInfomationView(String busStationName) {
        // If busStationName is empty, return empty list
        if (busStationName == null || busStationName.trim().isEmpty()) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 200);
            response.put("upcoming_buses", new ArrayList<>());
            return new ResponseEntity<>(response, HttpStatus.OK);
        }

        BusStation busStation = busStationRepository.findByNameContaining(busStationName).stream().findFirst().orElse(null);
        if (busStation == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", 200);
            response.put("upcoming_buses", new ArrayList<>());
            return new ResponseEntity<>(response, HttpStatus.OK);
        }

        // Get all buses that pass through this station
        List<BusStation> stations = busStationRepository.findByBusNumber(busStation.getBusNumber());
        List<Map<String, Object>> upcomingBuses = new ArrayList<>();

        for (BusStation station : stations) {
            if (station.getDirection() == busStation.getDirection()) {
                // Calculate distance and duration using Google Maps API
                String origin = busStation.getLatitude() + "," + busStation.getLongitude();
                String destination = station.getLatitude() + "," + station.getLongitude();
                
                try {
                    // Make request to Google Maps Distance Matrix API
                    String apiKey = System.getenv("GOOGLE_MAPS_API_KEY");
                    String url = String.format(
                        "https://maps.googleapis.com/maps/api/distancematrix/json?origins=%s&destinations=%s&key=%s",
                        origin, destination, apiKey
                    );

                    // Create HTTP client and request
                    HttpClient client = HttpClient.newHttpClient();
                    HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(url))
                        .GET()
                        .build();

                    // Send request and get response
                    HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
                    
                    // Parse JSON response
                    ObjectMapper mapper = new ObjectMapper();
                    JsonNode root = mapper.readTree(response.body());
                    
                    if (root.get("status").asText().equals("OK")) {
                        JsonNode elements = root.get("rows").get(0).get("elements").get(0);
                        if (elements.get("status").asText().equals("OK")) {
                            Map<String, Object> busInfo = new HashMap<>();
                            busInfo.put("station_name", station.getName());
                            busInfo.put("distance", elements.get("distance").get("text").asText());
                            busInfo.put("duration", elements.get("duration").get("text").asText());
                            upcomingBuses.add(busInfo);
                        }
                    }
                } catch (Exception e) {
                    // Log error but continue processing other stations
                    System.err.println("Error calculating distance: " + e.getMessage());
                }
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("status", 200);
        response.put("upcoming_buses", upcomingBuses);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }

    public ResponseEntity<?> FindBusStationByNameView(String name) {
        // If name is empty, return all stations
        if (name == null || name.trim().isEmpty()) {
            List<BusStation> allStations = busStationRepository.findAll();
            Map<String, Object> response = new HashMap<>();
            response.put("status", 200);
            response.put("data", allStations);
            return new ResponseEntity<>(response, HttpStatus.OK);
        }

        List<BusStation> stations = busStationRepository.findByNameContaining(name);
        Map<String, Object> response = new HashMap<>();
        response.put("status", 200);
        response.put("data", stations);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }
} 