package com.example.BusMap.service;

import com.example.BusMap.Model.BusStation;

import com.example.BusMap.repository.BusStationRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;


import java.util.List;
import java.util.stream.Collectors;

@Service
public class BusStationService5 {

    @Autowired
    private BusStationRepository busStationRepository;

    @Transactional
    public void updateBusNumbers() {
        // Lấy danh sách tất cả trạm xe buýt
        List<BusStation> stations = busStationRepository.findAll();

        for (BusStation station : stations) {
            // Lấy số xe buýt cho hướng đi (direction=0)
            List<String> busNumbersGo = getBusNumbers(station.getName(), 0);
            String busNumberListGo = String.join(",", busNumbersGo);
            station.setBusNumberListGo(busNumberListGo);

            // Lấy số xe buýt cho hướng về (direction=1)
            List<String> busNumbersReturn = getBusNumbers(station.getName(), 1);
            String busNumberListReturn = String.join(",", busNumbersReturn);
            station.setBusNumberListReturn(busNumberListReturn);

            // Cập nhật lại thông tin vào cơ sở dữ liệu
            busStationRepository.save(station);
        }
    }

    // Phương thức này sẽ lấy danh sách số xe buýt từ cơ sở dữ liệu theo tên trạm và hướng đi
    private List<String> getBusNumbers(String stationName, int direction) {
        // Truy vấn cơ sở dữ liệu để lấy tất cả số xe buýt có tên trạm và hướng đi
        List<BusStation> busStations = busStationRepository.findByNameAndDirection(stationName, direction);

        // Lấy ra chỉ danh sách số xe buýt từ các bản ghi được trả về
        return busStations.stream()
                .map(BusStation::getBusNumber) // Lấy số xe buýt từ mỗi đối tượng BusStation
                .collect(Collectors.toList()); // Chuyển thành danh sách
    }
}
