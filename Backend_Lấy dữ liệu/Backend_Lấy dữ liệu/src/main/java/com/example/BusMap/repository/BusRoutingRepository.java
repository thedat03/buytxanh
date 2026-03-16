package com.example.BusMap.repository;

import com.example.BusMap.Model.Bus;
import com.example.BusMap.Model.BusRouting;
import com.example.BusMap.Model.BusStation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BusRoutingRepository extends JpaRepository<BusRouting, Long> {
    List<BusRouting> findByBusBusId(int busId);
    List<BusRouting> findByBusBusIdAndDirection(int busId, int direction);
}