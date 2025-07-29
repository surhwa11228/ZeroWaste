package com.chungwoo.zerowaste.report.dto;

import lombok.Data;

import java.util.Date;

@Data
public class ReportSubmissionRequest {
    private double gpsLatitude;
    private double gpsLongitude;
    private String address;
    private double selectedLat;
    private double selectedLng;
    private String wasteCategory;
    private String description;
    private Date reportedAt;
}
