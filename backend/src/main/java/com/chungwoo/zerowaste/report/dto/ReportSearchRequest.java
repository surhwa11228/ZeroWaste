package com.chungwoo.zerowaste.report.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ReportSearchRequest {

    @NotNull private Double centerLat;
    @NotNull private Double centerLng;

    @NotNull private Double radius;

    private String category;
}
