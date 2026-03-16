package busmap2.example.busmap2.repository;

import busmap2.example.busmap2.Model.OnBusData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OnBusDataRepository extends JpaRepository<OnBusData, Integer> {
    OnBusData findByTicketId(Integer ticketId);
} 