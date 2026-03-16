package com.example.BusMap.Model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.JoinColumn;

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

    @ManyToOne
    @JoinColumn(name = "bus_id")
    private Bus bus;

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

    public Bus getBus() {
        return bus;
    }

    // Setters
    public void setBusStationId(Long busStationId) {
        this.busStationId = busStationId;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setBusNumber(String busNumber) {
        this.busNumber = busNumber;
    }

    public void setBusNumberName(String busNumberName) {
        this.busNumberName = busNumberName;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }

    public void setDirection(int direction) {
        this.direction = direction;
    }

    public void setPrice(int price) {
        this.price = price;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public void setUpdatedAt(Date updatedAt) {
        this.updatedAt = updatedAt;
    }

    public void setBusNumberListGo(String busNumberListGo) {
        this.busNumberListGo = busNumberListGo;
    }

    public void setBusNumberListReturn(String busNumberListReturn) {
        this.busNumberListReturn = busNumberListReturn;
    }

    public void setBus(Bus bus) {
        this.bus = bus;
    }
}
