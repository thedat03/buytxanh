package com.example.BusMap.service;


import com.example.BusMap.Model.Bus;
import com.example.BusMap.Model.BusStation;
import com.example.BusMap.repository.BusRepository;
import com.example.BusMap.repository.BusStationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

@Service
public class BusService {

    @Autowired
    private BusRepository busRepository;

    @Autowired
    private BusStationRepository busStationRepository;

    // Hàm tạo biển số xe ngẫu nhiên
    private String generateBusNumberPlate() {
        return "29" + (char) ('A' + new Random().nextInt(26)) + String.format("%05d", new Random().nextInt(100000));
    }

    // Hàm nội suy vị trí giữa hai điểm
    private double[] interpolatePosition(double lat1, double lon1, double lat2, double lon2) {
        double lat = lat1 + (lat2 - lat1) * new Random().nextDouble();
        double lon = lon1 + (lon2 - lon1) * new Random().nextDouble();
        return new double[]{lat, lon};
    }

    @Transactional
    public void generateAndInsertBusData() {
        // Lấy tất cả các tuyến xe buýt khác nhau từ database
        List<String> distinctBusNumbers = busStationRepository.findAll().stream()
                .map(BusStation::getBusNumber)
                .distinct()
                .collect(Collectors.toList());

        for (String busNumber : distinctBusNumbers) {
            // Xử lý cho cả hai hướng (0 và 1)
            for (int direction = 0; direction <= 1; direction++) {
                // Lấy danh sách trạm xe buýt cho mỗi hướng
                List<BusStation> busStationsList = busStationRepository.findByBusNumberAndDirectionOrderByBusStationId(busNumber, direction);
                
                if (!busStationsList.isEmpty()) {
                    // Lấy tên tuyến xe từ trạm đầu tiên
                    String busNumberName = busStationsList.get(0).getBusNumberName();
                    
                    // Tạo dữ liệu cho bảng Bus
                    String driverName = generateBusNumberPlate();
                    int stopIndex = new Random().nextInt(busStationsList.size() - 1);
                    BusStation startStop = busStationsList.get(stopIndex);
                    BusStation endStop = busStationsList.get(stopIndex + 1);

                    double[] position = interpolatePosition(startStop.getLatitude(), startStop.getLongitude(), endStop.getLatitude(), endStop.getLongitude());
                    double latitude = position[0];
                    double longitude = position[1];

                    int currentPassengerAmount = new Random().nextInt(21);  // Số lượng hành khách ngẫu nhiên từ 0 đến 20
                    int maxPassengerAmount = 20; // Giả sử số lượng hành khách tối đa là 20
                    double speed = 5 + new Random().nextDouble() * (20 - 5);  // Tốc độ ngẫu nhiên từ 5 đến 20 km/h

                    // Tạo đối tượng Bus và lưu vào cơ sở dữ liệu
                    Bus bus = new Bus();
                    bus.setBusNumber(busNumber);
                    bus.setDriverName(driverName);
                    bus.setCurrentLatitude(latitude);
                    bus.setCurrentLongitude(longitude);
                    bus.setCurrentPassengerAmount(currentPassengerAmount);
                    bus.setMaxPassengerAmount(maxPassengerAmount);
                    bus.setSpeed(speed);
                    bus.setDirection(direction);
                    bus.setBusNumberName(busNumberName);
                    bus.setCreatedAt(new Date());
                    bus.setUpdatedAt(new Date());

                    // Kiểm tra sự tồn tại của bus với driverName và busNumber
                    if (!busRepository.existsByBusNumberAndDriverName(busNumber, driverName)) {
                        busRepository.save(bus);
                        System.out.println("Inserted bus: " + driverName + " with coordinates (" + latitude + ", " + longitude + ") for direction " + direction);
                    } else {
                        System.out.println(driverName + " already exists in the database.");
                    }
                }
            }
        }
    }
}
