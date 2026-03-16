package com.example.BusMap.service;

import com.example.BusMap.Model.Bus;
import com.example.BusMap.Model.BusRouting;
import com.example.BusMap.Model.BusStation;
import com.example.BusMap.repository.BusRepository;
import com.example.BusMap.repository.BusRoutingRepository;
import com.example.BusMap.repository.BusStationRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class BusRoutingService {

    private final BusRepository busRepository;
    private final BusStationRepository busStationRepository;
    private final BusRoutingRepository busRoutingRepository;
    private final RestTemplate restTemplate;

    public BusRoutingService(RestTemplate restTemplate,
                           BusRepository busRepository,
                           BusStationRepository busStationRepository,
                           BusRoutingRepository busRoutingRepository) {
        this.restTemplate = restTemplate;
        this.busRepository = busRepository;
        this.busStationRepository = busStationRepository;
        this.busRoutingRepository = busRoutingRepository;
    }

    public void saveBusRouting() {
        List<Bus> buses = busRepository.findAll();

        for (Bus bus : buses) {
            List<BusStation> busStations = busStationRepository.findByBusNumber(bus.getBusNumber());

            if (busStations.size() >= 2) {
                BusRouting busRouting = new BusRouting();
                busRouting.setBus(bus);
                busRouting.setDirection(bus.getDirection());
                busRouting.setCreatedAt(LocalDateTime.now());
                busRouting.setUpdatedAt(LocalDateTime.now());

                busRoutingRepository.save(busRouting);
            }
        }
    }

    public BusRouting updateBusRoutingWithDetails(Long id, String operator, String frequency, String price, 
            String operatingHoursWeekday, String operatingHoursWeekend, String routeDescription, String departureTimes) {
        BusRouting busRouting = busRoutingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("BusRouting not found with id " + id));

        busRouting.setOperator(operator);
        busRouting.setFrequency(frequency);
        busRouting.setPrice(price);
        busRouting.setOperatingHoursWeekday(operatingHoursWeekday);
        busRouting.setOperatingHoursWeekend(operatingHoursWeekend);
        busRouting.setRouteDescription(routeDescription);
        busRouting.setDepartureTimes(departureTimes);
        busRouting.setUpdatedAt(LocalDateTime.now());

        return busRoutingRepository.save(busRouting);
    }

    public List<BusRouting> getBusRoutingByBusId(int busId) {
        return busRoutingRepository.findByBusBusId(busId);
    }

    public BusRouting getBusRoutingById(Long id) {
        return busRoutingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("BusRouting not found with id " + id));
    }

    public List<BusRouting> getAllBusRoutings() {
        return busRoutingRepository.findAll();
    }

    /**
     * Tự động tạo và lưu polyline cho tất cả các tuyến xe buýt
     * Mỗi busNumber có 2 tuyến (đi và về), mỗi tuyến sẽ có một polyline riêng
     */
    public void generateAndSaveAllBusRoutePolylines() {
        // Lấy tất cả các busNumber
        List<String> allBusNumbers = busStationRepository.findAllBusNumbers();
        
        for (String busNumber : allBusNumbers) {
            // Lấy danh sách xe buýt cho busNumber này (cả đi và về)
            List<Bus> buses = busRepository.findByBusNumber(busNumber);
            
            for (Bus bus : buses) {
                // Lấy danh sách điểm dừng cho tuyến này
                List<BusStation> stations = busStationRepository.findByBusNumberAndDirectionOrderByBusStationIdAsc(
                    busNumber, bus.getDirection());
                
                if (stations.size() >= 2) {
                    // Tạo chuỗi polyline từ các điểm dừng
                    StringBuilder polylinePoints = new StringBuilder();
                    for (BusStation station : stations) {
                        if (polylinePoints.length() > 0) {
                            polylinePoints.append(";");
                        }
                        polylinePoints.append(station.getLatitude())
                                    .append(",")
                                    .append(station.getLongitude());
                    }

                    // Tìm hoặc tạo mới BusRouting cho tuyến này
                    List<BusRouting> existingRoutings = busRoutingRepository.findByBusBusId(bus.getBusId());
                    BusRouting busRouting;
                    
                    if (existingRoutings.isEmpty()) {
                        // Tạo mới nếu chưa tồn tại
                        busRouting = new BusRouting();
                        busRouting.setBus(bus);
                        busRouting.setDirection(bus.getDirection());
                        busRouting.setCreatedAt(LocalDateTime.now());
                    } else {
                        // Cập nhật nếu đã tồn tại
                        busRouting = existingRoutings.get(0);
                    }

                    // Cập nhật thông tin polyline
                    busRouting.setPolyline(polylinePoints.toString());
                    busRouting.setUpdatedAt(LocalDateTime.now());

                    // Lưu vào database
                    busRoutingRepository.save(busRouting);
                }
            }
        }
    }
}
