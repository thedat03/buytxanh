package com.example.BusMap.service;

import com.example.BusMap.Model.BusStation;
import com.example.BusMap.repository.BusStationRepository;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import io.github.bonigarcia.wdm.WebDriverManager;

import java.util.List;

@Service
public class BusStationService {

    @Autowired
    private BusStationRepository busStationRepository;

    public void fetchBusStations() {
        // Cài đặt WebDriver với WebDriverManager
        WebDriverManager.chromedriver().setup();

        // Cấu hình ChromeOptions để không mở cửa sổ trình duyệt
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--headless"); // Chạy chế độ không hiển thị cửa sổ

        // Khởi tạo WebDriver
        WebDriver driver = new ChromeDriver(options);

        try {
            // Mở trang web
            driver.get("https://map.busmap.vn/hn/route/1");

            // Đợi trang web tải (giới hạn thời gian)
            Thread.sleep(5000); // 5 giây

            // Tìm tất cả các phần tử trạm xe buýt có class name 'name'
            List<org.openqa.selenium.WebElement> stations = driver.findElements(By.className("name"));

            // Lặp qua các trạm và lưu vào cơ sở dữ liệu
            for (org.openqa.selenium.WebElement station : stations) {
                String stationName = station.getText();

                // Tạo đối tượng BusStation và lưu vào cơ sở dữ liệu
                BusStation busStation = new BusStation();
                busStation.setName(stationName);
                // Các trường khác có thể được thêm vào tùy theo yêu cầu

                // Lưu vào cơ sở dữ liệu
                busStationRepository.save(busStation);
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            // Đóng trình duyệt
            driver.quit();
        }
    }
}
