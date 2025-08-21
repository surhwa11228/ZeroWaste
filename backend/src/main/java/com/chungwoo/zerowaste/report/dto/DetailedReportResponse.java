package com.chungwoo.zerowaste.report.dto;

import lombok.*;
import lombok.experimental.SuperBuilder;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class DetailedReportResponse {
    private String imageUrl;
    private String description;
}
