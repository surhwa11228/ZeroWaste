package com.chungwoo.zerowaste.report.controller;

import com.chungwoo.zerowaste.auth.dto.AuthUserDetails;
import com.chungwoo.zerowaste.report.dto.ReportSearchRequest;
import com.chungwoo.zerowaste.report.dto.ReportSearchResponse;
import com.chungwoo.zerowaste.report.dto.ReportSubmissionRequest;
import com.chungwoo.zerowaste.report.service.ReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Slf4j
@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @PostMapping
    public ResponseEntity<?> submitReport(@RequestPart("image") MultipartFile image,
                                          @RequestPart("report") ReportSubmissionRequest reportSubmissionRequest,
                                          @AuthenticationPrincipal AuthUserDetails user) throws IOException {


        //test
        user = new AuthUserDetails("testUID", "testEmail");

        reportService.submitReport(image, reportSubmissionRequest, user.getUid());
        return ResponseEntity.ok().body("Report submitted");
    }

    @PostMapping("/search")
    public  ResponseEntity<List<ReportSearchResponse>> searchReports(@RequestBody ReportSearchRequest reportSearchRequest) throws ExecutionException, InterruptedException {

        List<ReportSearchResponse> reports = reportService.searchReports(reportSearchRequest);
        log.info("Report search results for {} reports", reports.size());
        return ResponseEntity.ok(reports);
    }

}
