package busmap2.example.busmap2.service;

import busmap2.example.busmap2.Model.Bus;
import busmap2.example.busmap2.Model.BusRouting;
import busmap2.example.busmap2.Model.BusStation;
import busmap2.example.busmap2.repository.BusRepository;
import busmap2.example.busmap2.repository.BusRoutingRepository;
import busmap2.example.busmap2.repository.BusStationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BusRoutingService {

    @Autowired
    private BusRepository busRepository;

    @Autowired
    private BusRoutingRepository busRoutingRepository;

    @Autowired
    private BusStationRepository busStationRepository;

    public BusRouting getBusRoutingDetails(int busId) {
        return busRoutingRepository.findByBusBusId(busId)
                .stream()
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Bus routing not found for bus ID: " + busId));
    }

    public List<BusRouting> getAllBusRoutings() {
        return busRoutingRepository.findAll();
    }

    public BusRouting updateBusRoutingDetails(Long id, String operator, String frequency, 
            String price, String operatingHoursWeekday, String operatingHoursWeekend, 
            String routeDescription, String departureTimes) {
        BusRouting busRouting = busRoutingRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Bus routing not found with id: " + id));

        busRouting.setOperator(operator);
        busRouting.setFrequency(frequency);
        busRouting.setPrice(price);
        busRouting.setOperatingHoursWeekday(operatingHoursWeekday);
        busRouting.setOperatingHoursWeekend(operatingHoursWeekend);
        busRouting.setRouteDescription(routeDescription);
        busRouting.setDepartureTimes(departureTimes);

        return busRoutingRepository.save(busRouting);
    }
}
