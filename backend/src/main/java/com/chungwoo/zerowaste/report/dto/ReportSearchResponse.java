package com.chungwoo.zerowaste.report.dto;

import lombok.AllArgsConstructor;
import lombok.Data;



@Data
@AllArgsConstructor
public class ReportSearchResponse {
    private String documentId;
    private double latitude;
    private double longitude;
    private String wasteCategory;
}
