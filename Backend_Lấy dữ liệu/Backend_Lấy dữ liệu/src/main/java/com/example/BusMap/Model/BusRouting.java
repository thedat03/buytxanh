package com.example.BusMap.Model;


import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table
public class BusRouting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Integer direction;
    @Lob
    private String polyline;
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    @ManyToOne
    @JoinColumn(name = "bus_id", referencedColumnName = "bus_id")
    private Bus bus;
    private String operator;
    private String frequency;
    private String price;
    private String operatingHoursWeekday;
    private String operatingHoursWeekend;

    @Lob
    private String routeDescription;
    @Column(length = 1000)
    private String departureTimes;

    public Bus getBus() {
        return bus;
    }

    public void setBus(Bus bus) {
        this.bus = bus;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setDirection(Integer direction) {
        this.direction = direction;
    }

    public void setPolyline(String polyline) {
        this.polyline = polyline;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public Integer getDirection() {
        return direction;
    }

    public String getPolyline() {
        return polyline;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public String getOperator() {
        return operator;
    }

    public void setOperator(String operator) {
        this.operator = operator;
    }

    public String getFrequency() {
        return frequency;
    }

    public void setFrequency(String frequency) {
        this.frequency = frequency;
    }

    public String getPrice() {
        return price;
    }

    public void setPrice(String price) {
        this.price = price;
    }

    public String getOperatingHoursWeekday() {
        return operatingHoursWeekday;
    }

    public void setOperatingHoursWeekday(String operatingHoursWeekday) {
        this.operatingHoursWeekday = operatingHoursWeekday;
    }

    public String getOperatingHoursWeekend() {
        return operatingHoursWeekend;
    }

    public void setOperatingHoursWeekend(String operatingHoursWeekend) {
        this.operatingHoursWeekend = operatingHoursWeekend;
    }

    public String getRouteDescription() {
        return routeDescription;
    }

    public void setRouteDescription(String routeDescription) {
        this.routeDescription = routeDescription;
    }

    public String getDepartureTimes() {
        return departureTimes;
    }

    public void setDepartureTimes(String departureTimes) {
        this.departureTimes = departureTimes;
    }



}