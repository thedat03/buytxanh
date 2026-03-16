package busmap2.example.busmap2.repository;

import busmap2.example.busmap2.Model.Ticket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TicketRepository extends JpaRepository<Ticket, Integer> {
    List<Ticket> findByStatusAndBusId(Integer status, Integer busId);
} 