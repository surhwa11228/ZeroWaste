package com.chungwoo.zerowaste.report.controller;

import com.chungwoo.zerowaste.api.ApiResponse;
import com.chungwoo.zerowaste.auth.dto.AuthUserDetails;
import com.chungwoo.zerowaste.report.dto.*;
import com.chungwoo.zerowaste.report.service.ReportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

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

        ReportResponse report =  reportService.submitReport(request, user.getUid());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(report));
    }

    @PutMapping("/{documentId}")
    public ResponseEntity<ApiResponse<Void>> updateReport(@PathVariable("documentId") String documentId,
                                                          @RequestPart("image") MultipartFile image,
                                                          @RequestPart("data") ReportAdditionalInfoRequest request,
                                                          @AuthenticationPrincipal AuthUserDetails user){

        reportService.saveAdditionalInfo(documentId, request, image, user.getUid());
        return ResponseEntity.status(HttpStatus.NO_CONTENT)
                .body(ApiResponse.noContent());
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
    public ResponseEntity<ApiResponse<List<ReportResponse>>> searchReports(
            @RequestBody @Valid ReportSearchRequest request) {

        List<ReportResponse> reports = reportService.searchReports(request);
//        log.info("Report search results for {} reports", reports.size());
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(reports));
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse<List<ReportResponse>>> searchMyReports(
            @RequestParam(required = false) Long startAfter,
            @AuthenticationPrincipal AuthUserDetails user) {

        List<ReportResponse> myReports = reportService.searchMyReports(startAfter, user);

        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(myReports));

    }

    @GetMapping("/detail/{documentId}")
    public ResponseEntity<ApiResponse<DetailedReportResponse>> showDetailedReport(
            @PathVariable("documentId") String documentId) {

        DetailedReportResponse res = reportService.showDetailedReport(documentId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(res));
    }

}
