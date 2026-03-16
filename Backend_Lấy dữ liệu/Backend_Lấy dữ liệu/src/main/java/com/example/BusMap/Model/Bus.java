package com.example.BusMap.Model;

import jakarta.persistence.*;

import java.util.Date;

@Entity
public class Bus {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "bus_id")
    private int busId;

    private String busNumber;
    private String driverName;
    private double currentLongitude;
    private double currentLatitude;
    private int currentPassengerAmount;
    private int maxPassengerAmount;
    private double speed;
    private int direction;
    private String busNumberName;
    private Date createdAt;
    private Date updatedAt;

    // Getters


    public int getBusId() {
        return busId;
    }

    public void setBusId(int busId) {
        this.busId = busId;
    }

    public String getBusNumber() {
        return busNumber;
    }

    public String getDriverName() {
        return driverName;
    }

    public double getCurrentLongitude() {
        return currentLongitude;
    }

    public double getCurrentLatitude() {
        return currentLatitude;
    }

    public int getCurrentPassengerAmount() {
        return currentPassengerAmount;
    }

    public int getMaxPassengerAmount() {
        return maxPassengerAmount;
    }

    public double getSpeed() {
        return speed;
    }

    public Integer getDirection() {
        return direction;
    }

    public String getBusNumberName() {
        return busNumberName;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public Date getUpdatedAt() {
        return updatedAt;
    }

    // Setters


    public void setBusNumber(String busNumber) {
        this.busNumber = busNumber;
    }

    public void setDriverName(String driverName) {
        this.driverName = driverName;
    }

    public void setCurrentLongitude(double currentLongitude) {
        this.currentLongitude = currentLongitude;
    }

    public void setCurrentLatitude(double currentLatitude) {
        this.currentLatitude = currentLatitude;
    }

    public void setCurrentPassengerAmount(int currentPassengerAmount) {
        this.currentPassengerAmount = currentPassengerAmount;
    }

    public void setMaxPassengerAmount(int maxPassengerAmount) {
        this.maxPassengerAmount = maxPassengerAmount;
    }

    public void setSpeed(double speed) {
        this.speed = speed;
    }

    public void setDirection(int direction) {
        this.direction = direction;
    }

    public void setBusNumberName(String busNumberName) {
        this.busNumberName = busNumberName;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public void setUpdatedAt(Date updatedAt) {
        this.updatedAt = updatedAt;
    }
}