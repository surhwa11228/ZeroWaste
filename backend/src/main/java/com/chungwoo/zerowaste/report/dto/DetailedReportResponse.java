package com.chungwoo.zerowaste.report.dto;

import lombok.*;
import lombok.experimental.SuperBuilder;

@Data
@EqualsAndHashCode(callSuper = false)
@AllArgsConstructor
@NoArgsConstructor
@SuperBuilder
public class DetailedReportResponse extends ReportResponse {
    private Long reportedAt;
    private boolean hasAdditionalInfo;
}
