package com.chungwoo.zerowaste.report.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.Date;

@Data
public class ReportSubmissionRequest {

    @NotNull private Double gpsLatitude;
    @NotNull private Double gpsLongitude;

    @NotNull private Double selectedLat;
    @NotNull private Double selectedLng;

    //"CIGARETTE_BUTT", "GENERAL_WASTE", "FOOD_WASTE", "OTHERS"
    @NotBlank private String wasteCategory;

    @NotNull private Date reportedAt;

    private String description;

    //필요한가?
    private String address;
}
