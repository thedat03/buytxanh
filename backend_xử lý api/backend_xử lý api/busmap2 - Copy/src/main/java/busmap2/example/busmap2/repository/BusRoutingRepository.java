package busmap2.example.busmap2.repository;

import busmap2.example.busmap2.Model.BusRouting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BusRoutingRepository extends JpaRepository<BusRouting, Long> {
    List<BusRouting> findByBusBusId(int busId);
} 