package com.chungwoo.zerowaste.report.model;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ReportSubmit {
    private String uid;
    private Double latitude;
    private Double longitude;
    private String wasteCategory;
    private Long reportedAt;
    private boolean hasAdditionalInfo;
}
