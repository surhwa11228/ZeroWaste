package com.chungwoo.zerowaste.report.dto;

import lombok.Data;

@Data
public class ReportSearchRequest {
    private double centerLat;
    private double centerLng;
    private double radius;
    private String category;
}
