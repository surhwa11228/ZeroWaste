package com.chungwoo.zerowaste.report.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ReportResponse {
    private String documentId;
    private double latitude;
    private double longitude;
    private String wasteCategory;
}
