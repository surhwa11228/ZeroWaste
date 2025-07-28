package com.chungwoo.zerowaste.report.controller;

import com.chungwoo.zerowaste.report.reportdto.ReportRequestDto;
import com.chungwoo.zerowaste.report.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;


@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @PostMapping
    public ResponseEntity<?> submitReport(@RequestPart("image") MultipartFile image,
                                          @RequestPart("report") ReportRequestDto reportDto,
                                          @AuthenticationPrincipal String userId) {

        reportService.submitReport(image, reportDto, userId);
        return ResponseEntity.ok().body("Report submitted");
    }

}
