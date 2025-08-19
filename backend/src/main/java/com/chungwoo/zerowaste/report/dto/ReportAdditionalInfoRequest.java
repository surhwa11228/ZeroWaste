package com.chungwoo.zerowaste.report.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ReportAdditionalInfoRequest {

    private String description;
}
