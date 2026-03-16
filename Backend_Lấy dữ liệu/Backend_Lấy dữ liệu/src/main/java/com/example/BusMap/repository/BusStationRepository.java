package com.example.BusMap.repository;

import com.example.BusMap.Model.BusStation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BusStationRepository extends JpaRepository<BusStation, Long> {
    boolean existsByNameAndBusNumber(String name, String busNumber);
    boolean existsByName(String name);
    List<BusStation> findByNameAndDirection(String name, int direction);

    List<BusStation> findByBusNumberAndDirectionOrderByBusStationIdAsc(String busNumber, Integer direction);

    @Query("SELECT DISTINCT b.busNumber FROM BusStation b")
    List<String> findAllBusNumbers();

    List<BusStation> findByBusNumberAndDirectionOrderByBusStationId(String busNumber, int direction);

    List<BusStation> findByBusBusNumber(String busNumber);

    List<BusStation> findByBusStationId(Long busStationId);

    List<BusStation> findByBusNumber(String busNumber);


}