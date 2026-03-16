package busmap2.example.busmap2.repository;

import busmap2.example.busmap2.Model.Bus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BusRepository extends JpaRepository<Bus, Integer> {
    Optional<Bus> findByBusNumberAndDriverName(String busNumber, String driverName);
    List<Bus> findByBusNumberContaining(String busNumber);
    List<Bus> findByBusNumberAndDirection(String busNumber, Integer direction);
    List<Bus> findByBusNumber(String busNumber);
}