package busmap2.example.busmap2.repository;

import busmap2.example.busmap2.Model.BusStation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BusStationRepository extends JpaRepository<BusStation, Long> {
    List<BusStation> findByNameContaining(String name);
    List<BusStation> findByBusNumber(String busNumber);
    List<BusStation> findByBusNumberAndDirection(String busNumber, Integer direction);
    BusStation findByNameAndBusNumber(String name, String busNumber);
} 