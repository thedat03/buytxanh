package busmap2.example.busmap2.Model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;


@Entity
public class OnBusPassengerData {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Integer busId;
    private String busNumber;
    private int passengerAmount;

    public void setId(Long id) {
        this.id = id;
    }


    public void setBusId(Integer busId) {
        this.busId = busId;
    }

    public void setBusNumber(String busNumber) {
        this.busNumber = busNumber;
    }

    public void setPassengerAmount(int passengerAmount) {
        this.passengerAmount = passengerAmount;
    }

    public Long getId() {
        return id;
    }

    public Integer getBusId() {
        return busId;
    }

    public String getBusNumber() {
        return busNumber;
    }

    public int getPassengerAmount() {
        return passengerAmount;
    }
// Getters and Setters
}