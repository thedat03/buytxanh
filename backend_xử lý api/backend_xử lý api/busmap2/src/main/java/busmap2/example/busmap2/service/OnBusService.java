package busmap2.example.busmap2.service;

import busmap2.example.busmap2.Model.Bus;
import busmap2.example.busmap2.Model.OnBusData;
import busmap2.example.busmap2.Model.Ticket;
import busmap2.example.busmap2.repository.BusRepository;
import busmap2.example.busmap2.repository.OnBusDataRepository;
import busmap2.example.busmap2.repository.TicketRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class OnBusService {

    @Autowired
    private OnBusDataRepository onBusDataRepository;

    @Autowired
    private TicketRepository ticketRepository;

    @Autowired
    private BusRepository busRepository;

    public ResponseEntity<?> getOnBus(Integer ticketId, Integer busId) {
        OnBusData existingData = onBusDataRepository.findByTicketId(ticketId);
        if (existingData != null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "this user is on bus"));
        }

        Ticket ticket = ticketRepository.findById(ticketId).orElse(null);
        if (ticket == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "this ticket is not valid"));
        }

        ticket.setBusId(busId);
        ticketRepository.save(ticket);

        Bus bus = busRepository.findById(busId).orElse(null);
        if (bus != null) {
            bus.setCurrentPassengerAmount(bus.getCurrentPassengerAmount() + 1);
            busRepository.save(bus);
        }

        return ResponseEntity.ok(Map.of("status", 200, "message", "Get on bus successfully"));
    }

    public ResponseEntity<?> getOffBus(Integer busStationId, Integer busId) {
        if (busStationId == null || busId == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "bus_station_id, bus_id is required"));
        }

        try {
            var ticketList = ticketRepository.findByStatusAndBusId(0, busId);
            if (ticketList.isEmpty()) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of("status", 400, "message", "this bus is empty"));
            }

            Bus bus = busRepository.findById(busId).orElse(null);
            if (bus == null) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of("status", 400, "message", "bus not found"));
            }

            int count = 0;
            for (Ticket ticket : ticketList) {
                OnBusData onBusData = onBusDataRepository.findByTicketId(ticket.getTicketId());
                if (onBusData != null) {
                    onBusDataRepository.delete(onBusData);
                    bus.setCurrentPassengerAmount(bus.getCurrentPassengerAmount() - 1);
                    busRepository.save(bus);
                    count++;
                }
            }

            if (count == 0) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of("status", 400, "message", "get off 0 passenger"));
            }

            return ResponseEntity.ok(Map.of("status", 200, "message", "Get off bus successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("status", 400, "message", "this user is not on bus"));
        }
    }
} 