package com.chungwoo.zerowaste.report.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    @PostMapping
    public ResponseEntity<?> uploadReport(@RequestParam("file") MultipartFile file,
                                          @ModelAttribute ReportDto reportDto,
                                          @AuthenticationPrincipal String uid) {

    }

}
