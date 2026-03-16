package com.example.BusMap.controller;


import com.example.BusMap.service.BusStationService;
import com.example.BusMap.service.BusStationService3;
import com.example.BusMap.service.BusStationServices;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;

@RestController
public class BusStationController {

    @Autowired
    private BusStationService busStationService;
    @Autowired
    private BusStationServices busStationServices;

    @GetMapping("/stationslv")
    public String fetchBusStations2() {
        busStationServices.fetchBusStationss();
        return "Bus stations fetched and saved to database";
    }
    @GetMapping("/fetch-bus-stations")
    public String fetchBusStations() {
        busStationService.fetchBusStations();
        return "Bus stations fetched and saved to database";
    }

    private final BusStationService3 busStationService3;

    public BusStationController(BusStationService3 busStationService3) {
        this.busStationService3 = busStationService3;
    }

    @GetMapping("/insert-bus-stations")
    public String insertBusStations(@RequestParam String busNumber) {
        List<String> locations = Arrays.asList(
                "Đại Học Mỏ",
                "Đối diện Học viện Tài Chính",
                "Đối diện Công ty CP cơ điện HN",
                "Ngã 3 nhà máy bê tông Chèm, Xóm 7 Đông Ngạc",
                "Đình Làng Liên Ngạc",
                "Ngã 3 Dốc Kẻ Chèm (Cạnh Bưu điện Hồng Ngự)",
                "Trường tiểu học Đông Ngạc A Chèm",
                "Xóm Đình Nhật Tảo (Qua Đình Nhật Tảo 100m)",
                "Làng Thượng Thụy",
                "327-329 An Dương Vương",
                "Lối rẽ vào UBND xã Phú Thượng",
                "Trạm thú y Tây Hồ",
                "Đối diện ngõ 58 An Dương Vương",
                "525 Âu Cơ (Qua ngã 3 Lạc Long Quân)",
                "Đình Nhật Tân",
                "Hồ Quảng Bá",
                "Ngã 3 Âu Cơ - Xuân Diệu - Tô Ngọc Vân",
                "215B Âu Cơ (Đối diện Chợ hoa Quảng An)",
                "111 Đường Âu Cơ",
                "33 Âu Cơ",
                "Đối diện Đền Bảo An, Nghi Tàm",
                "Đối diện Chợ Yên Phụ, Nghi Tàm",
                "Trường Mạc Đĩnh Chi - Yên Phụ (đường xe buýt)",
                "Nhà Máy Nước - Yên Phụ",
                "Trước nút giao Hàng Than 70m",
                "Điểm trung chuyển Long Biên (E3.1)",
                "22C Hàng Lược",
                "56 Hàng Cân",
                "24A Bà Triệu",
                "58B Bà Triệu",
                "92-94 Bà Triệu",
                "180 - 182 Bà Triệu",
                "Đối diện Vincom Tower",
                "B13 KTX Bách Khoa",
                "Qua Viện tin học pháp ngữ 20m, Lê Thanh Nghị",
                " Đại học Bách Khoa"
        );

        busStationService3.insertBusStations(locations, busNumber);
        return "Bus stations inserted successfully.";
    }

}
