package com.chungwoo.zerowaste.report.controller;

import com.chungwoo.zerowaste.api.ApiResponse;
import com.chungwoo.zerowaste.auth.dto.AuthUserDetails;
import com.chungwoo.zerowaste.report.dto.ReportSearchRequest;
import com.chungwoo.zerowaste.report.dto.ReportResponse;
import com.chungwoo.zerowaste.report.dto.ReportSubmissionRequest;
import com.chungwoo.zerowaste.report.service.ReportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/report")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @PostMapping
    public ResponseEntity<ApiResponse<ReportResponse>> submitReport(@RequestBody @Valid ReportSubmissionRequest request,
                                          @AuthenticationPrincipal AuthUserDetails user) {


        //test
        user = new AuthUserDetails("testUID", "testEmail");

        ReportResponse report =  reportService.submitReport(request, user.getUid());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(report));
    }

//    @PostMapping("/submit/additional/{id}")
//    public ResponseEntity<ApiResponse<Void>> addAdditionalInfo(@RequestPart("image") MultipartFile file,
//                                                                         @RequestPart("info") ReportAdditionalInfoRequest request,
//                                                                         AuthenticationPrincipal AuthUserDetails user){
//
//          추후 구현
//
//    }


    @PostMapping("/search")
    public  ResponseEntity<ApiResponse<List<ReportResponse>>> searchReports
            (@RequestBody @Valid ReportSearchRequest request) {

        List<ReportResponse> reports = reportService.searchReports(request);
//        log.info("Report search results for {} reports", reports.size());
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(reports));
    }

}
