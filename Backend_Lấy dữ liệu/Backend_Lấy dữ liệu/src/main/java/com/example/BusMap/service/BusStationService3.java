package com.example.BusMap.service;

import com.example.BusMap.Model.BusStation;
import com.example.BusMap.repository.BusStationRepository;
import com.google.maps.GeoApiContext;
import com.google.maps.GeocodingApi;
import com.google.maps.model.GeocodingResult;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class BusStationService3 {

    @Value("${google.api.key}")
    private String googleApiKey;

    private final BusStationRepository busStationRepository;

    public BusStationService3(BusStationRepository busStationRepository) {
        this.busStationRepository = busStationRepository;
    }

    private double[] getCoordinates(String address) {
        GeoApiContext context = new GeoApiContext.Builder().apiKey(googleApiKey).build();
        try {
            GeocodingResult[] results = GeocodingApi.geocode(context, address).await();
            if (results.length > 0) {
                return new double[]{results[0].geometry.location.lat, results[0].geometry.location.lng};
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private boolean locationExists(String name, String busNumber) {
        return busStationRepository.existsByNameAndBusNumber(name, busNumber);
    }

    @Transactional
    public void insertBusStations(List<String> locations, String busNumber) {
        for (String location : locations) {
            if (!locationExists(location, busNumber)) {
                double[] coordinates = getCoordinates(location);
                if (coordinates != null) {
                    BusStation busStation = new BusStation();
                    busStation.setName(location);
                    busStation.setLatitude(coordinates[0]);
                    busStation.setLongitude(coordinates[1]);
                    busStation.setBusNumber(busNumber);
                    busStation.setDirection(1); // Fixed value for direction
                    busStation.setPrice(10000); // Example price
                    busStation.setCreatedAt(new Date());
                    busStation.setUpdatedAt(new Date());
                    // Gán giá trị cụ thể cho busNumberName
                    String busNumberName = "Bách Khoa - Chèm (ĐH Mỏ)";  // Ví dụ giá trị cụ thể
                    busStation.setBusNumberName(busNumberName);  // Gán giá trị busNumberName
                    busStationRepository.save(busStation);
                    System.out.println("Inserted: " + location);
                } else {
                    System.out.println("Failed to get coordinates for: " + location);
                }
            } else {
                System.out.println(location + " already exists in the database.");
            }
        }
    }
}
