package busmap2.example.busmap2.Model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

import java.util.Date;

@Entity
public class BusStation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long busStationId;

    private String name;
    private String busNumber;
    private String busNumberName;
    private double latitude;
    private double longitude;
    private int direction;
    private int price;
    private Date createdAt;
    private Date updatedAt;
    private String busNumberListGo;
    private String busNumberListReturn;

    // Getters
    public Long getBusStationId() {
        return busStationId;
    }

    public String getName() {
        return name;
    }

    public String getBusNumber() {
        return busNumber;
    }

    public String getBusNumberName() {
        return busNumberName;
    }

    public double getLatitude() {
        return latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public int getDirection() {
        return direction;
    }

    public int getPrice() {
        return price;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public Date getUpdatedAt() {
        return updatedAt;
    }

    public String getBusNumberListGo() {
        return busNumberListGo;
    }

    public String getBusNumberListReturn() {
        return busNumberListReturn;
    }
}