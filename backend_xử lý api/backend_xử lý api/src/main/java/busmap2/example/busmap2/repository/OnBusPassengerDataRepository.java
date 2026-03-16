package busmap2.example.busmap2.repository;

import busmap2.example.busmap2.Model.OnBusPassengerData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OnBusPassengerDataRepository extends JpaRepository<OnBusPassengerData, Long> {
}