package com.chungwoo.zerowaste.report.reportdto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ReportRequestDto {
    private double gpsLatitude;
    private double gpsLongitude;
    private String address;
    private double selectedLat;
    private double selectedLng;
    private String wasteCategory;
    private String description;
    private LocalDateTime reportedAt;
}
