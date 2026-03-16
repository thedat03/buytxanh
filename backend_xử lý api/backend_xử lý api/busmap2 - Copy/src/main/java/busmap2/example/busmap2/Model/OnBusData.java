package busmap2.example.busmap2.Model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Data
@Table(name = "on_bus_data")
public class OnBusData {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    
    private Integer ticketId;
    private Integer busId;
    private String busNumber;

    public void setId(Integer id) {
        this.id = id;
    }

    public void setBusNumber(String busNumber) {
        this.busNumber = busNumber;
    }

    public void setBusId(Integer busId) {
        this.busId = busId;
    }

    public void setTicketId(Integer ticketId) {
        this.ticketId = ticketId;
    }

    public Integer getId() {
        return id;
    }

    public Integer getTicketId() {
        return ticketId;
    }

    public Integer getBusId() {
        return busId;
    }

    public String getBusNumber() {
        return busNumber;
    }
}