package com.example.BusMap.service;


import com.example.BusMap.Model.BusStation;
import com.example.BusMap.repository.BusStationRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;


import java.util.Arrays;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

@Service
public class BusStationService4 {

    @Autowired
    private BusStationRepository busStationRepository;

    // Hàm tạo biển số xe ngẫu nhiên
    private String generateBusNumberPlate() {
        Random rand = new Random();
        char randomLetter = (char) ('A' + rand.nextInt(26));
        String randomNumbers = String.format("%05d", rand.nextInt(100000));
        return "29" + randomLetter + randomNumbers;
    }

    // Hàm nội suy vị trí giữa hai điểm (giả lập)
    private double[] interpolatePosition(double lat1, double lon1, double lat2, double lon2) {
        Random rand = new Random();
        double lat = lat1 + (lat2 - lat1) * rand.nextDouble();
        double lon = lon1 + (lon2 - lon1) * rand.nextDouble();
        return new double[]{lat, lon};
    }

    // Hàm cập nhật danh sách số tuyến cho các trạm
    @Transactional
    public void createBusNumberList() {
        // Lấy tất cả tên các trạm
        List<BusStation> busStations = busStationRepository.findAll();

        for (BusStation station : busStations) {
            String stationName = station.getName();

            // Giả lập việc lấy danh sách số tuyến (direction = 0 - đi và direction = 1 - về)
            List<String> busNumbersGo = Arrays.asList("03", "22", "34");  // Giả lập dữ liệu
            List<String> busNumbersReturn = Arrays.asList("03", "22", "34"); // Giả lập dữ liệu

            // Chuyển danh sách thành chuỗi, nối với dấu phẩy
            String busNumberListGo = busNumbersGo.stream().collect(Collectors.joining(","));
            String busNumberListReturn = busNumbersReturn.stream().collect(Collectors.joining(","));

            // Cập nhật các trường trong bảng bus_routing_busstation
            station.setBusNumberListGo(busNumberListGo);
            station.setBusNumberListReturn(busNumberListReturn);

            // Lưu vào cơ sở dữ liệu
            busStationRepository.save(station);

            System.out.println("Updated " + stationName + " with bus numbers: " + busNumberListGo + " (Go), " + busNumberListReturn + " (Return)");
        }
    }
}