package com.chungwoo.zerowaste.report.service;

import com.chungwoo.zerowaste.report.dto.ReportSearchRequest;
import com.chungwoo.zerowaste.report.dto.ReportSearchResponse;
import com.chungwoo.zerowaste.report.dto.ReportSubmissionRequest;
import com.chungwoo.zerowaste.upload.dto.ImageUploadResponse;
import com.chungwoo.zerowaste.utils.GeoUtils;
import com.chungwoo.zerowaste.utils.StorageUploadUtils;
import com.google.api.core.ApiFuture;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Slf4j
@Service
public class ReportService {


    public void submitReport(MultipartFile image, ReportSubmissionRequest reportSubmissionRequest, String uid) throws IOException {
        ImageUploadResponse imageUploadResponse =
                StorageUploadUtils.imageUpload(StorageUploadUtils.REPORT, image);

        Firestore db = FirestoreClient.getFirestore();

        GeoPoint location = GeoUtils.determineTrustedLocation(
                reportSubmissionRequest.getGpsLatitude(),
                reportSubmissionRequest.getGpsLongitude(),
                reportSubmissionRequest.getSelectedLat(),
                reportSubmissionRequest.getSelectedLng()
        );

        Map<String,Object> report = new HashMap<>();
        report.put("uid", uid);
        report.put("location",location);
        report.put("address", reportSubmissionRequest.getAddress());
        report.put("description", reportSubmissionRequest.getDescription());
        report.put("imageUrl", imageUploadResponse.getUrl());
        report.put("imageName", imageUploadResponse.getFileName());
        report.put("wasteCategory", reportSubmissionRequest.getWasteCategory());
        report.put("reportedAt", reportSubmissionRequest.getReportedAt());

        db.collection("reports").add(report);
        log.info("Report submitted");
    }


    //수정중
    public List<ReportSearchResponse> searchReports(ReportSearchRequest reportSearchRequest) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();

        Timestamp threeDaysAgo = Timestamp.of(
                Date.from(Instant.now().minus(Duration.ofDays(3)))
        );


        CollectionReference reportsRef = db.collection("reports");

        Query query = reportsRef.whereGreaterThan("reportedAt", threeDaysAgo);

        GeoUtils.BoundingBox boundingBox = GeoUtils.calculateBoundingBox(
                reportSearchRequest.getCenterLat(),
                reportSearchRequest.getCenterLng(),
                reportSearchRequest.getRadius()
        );

        log.info("bounding box {}, {}, {}, {} ", boundingBox.minLat(), boundingBox.minLng(), boundingBox.maxLat(), boundingBox.maxLng());

        GeoPoint minLatLng = new  GeoPoint(boundingBox.minLat(), boundingBox.minLng());
        GeoPoint maxLatLng = new  GeoPoint(boundingBox.maxLat(), boundingBox.maxLng());

        query = query
                .whereGreaterThanOrEqualTo("location", minLatLng)
                .whereLessThanOrEqualTo("location", maxLatLng)
                .limit(50);

        ApiFuture<QuerySnapshot> querySnapshot = query.get();
        log.info("Query results for {} reports", querySnapshot.get().getDocuments().size());
        List<QueryDocumentSnapshot> documents = querySnapshot.get().getDocuments();

        return documents.stream()
                .map(document -> {
                    GeoPoint location = document.get("location", GeoPoint.class);
                    Double latitude = location.getLatitude();
                    Double longitude = location.getLongitude();
                    String wasteCategory = document.getString("wasteCategory");

                    if (latitude == null || longitude == null || wasteCategory == null) {
                        log.warn("위치 정보 누락 docId: {}", document.getId());
                        return null;
                    }

                    return new ReportSearchResponse(
                            document.getId(),
                            latitude,
                            longitude,
                            wasteCategory
                    );
                })
                .filter(Objects::nonNull) // null인 객체 제외
                .toList();

    }

}
