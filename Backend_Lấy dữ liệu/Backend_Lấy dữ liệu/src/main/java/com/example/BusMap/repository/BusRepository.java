package com.example.BusMap.repository;

import com.example.BusMap.Model.Bus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BusRepository extends JpaRepository<Bus, Integer> {
    boolean existsByBusNumberAndDriverName(String busNumber, String driverName);
    List<Bus> findAll();

    List<Bus> findByBusNumber(String busNumber);

    Optional<Object> findByBusNumberAndDirection(String busNumber, Integer directionInteger);
}
