package com.chungwoo.zerowaste.report.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

@Data
@AllArgsConstructor
@NoArgsConstructor
@SuperBuilder
public class ReportResponse {
    private String documentId;
    private double latitude;
    private double longitude;
    private String wasteCategory;
}
