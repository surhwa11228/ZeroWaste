package com.chungwoo.zerowaste.report.service;

import com.chungwoo.zerowaste.exception.exceptions.ReportSearchFailedException;
import com.chungwoo.zerowaste.exception.exceptions.ReportSubmissionFailedException;
import com.chungwoo.zerowaste.report.dto.ReportSearchRequest;
import com.chungwoo.zerowaste.report.dto.ReportResponse;
import com.chungwoo.zerowaste.report.dto.ReportSubmissionRequest;
import com.chungwoo.zerowaste.utils.GeoUtils;
import com.google.api.core.ApiFuture;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Slf4j
@Service
public class ReportService {

    public ReportResponse submitReport(ReportSubmissionRequest request,
                                       String uid) {

        Firestore db = FirestoreClient.getFirestore();

        GeoPoint location = GeoUtils.determineTrustedLocation(
                request.getGpsLatitude(),
                request.getGpsLongitude(),
                request.getSelectedLat(),
                request.getSelectedLng()
        );

        Map<String,Object> report = new HashMap<>();
        report.put("uid", uid);
        report.put("latitude", location.getLatitude());
        report.put("longitude",location.getLongitude());
        report.put("wasteCategory", request.getWasteCategory());
        report.put("reportedAt", request.getReportedAt());
        report.put("hasAdditionalInfo", false);


        try {
            DocumentReference docRef = db.collection("reports").add(report).get(); // 동기
            log.info("Report submitted: {}", docRef.getId());

            return new ReportResponse(
                    docRef.getId(),
                    location.getLatitude(),
                    location.getLongitude(),
                    request.getWasteCategory()
            );

        } catch (InterruptedException | ExecutionException e) {
            Thread.currentThread().interrupt();
            throw new ReportSubmissionFailedException("제보 저장 실패", e);
        }
    }


    public List<ReportResponse> searchReports(ReportSearchRequest reportSearchRequest)  {
        try {
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

            query = query
                    .whereGreaterThanOrEqualTo("longitude", boundingBox.minLng())
                    .whereLessThanOrEqualTo("longitude", boundingBox.maxLng())
                    .whereGreaterThanOrEqualTo("latitude", boundingBox.minLat())
                    .whereLessThanOrEqualTo("latitude", boundingBox.maxLat())
                    .limit(50);

            ApiFuture<QuerySnapshot> querySnapshot = query.get();
            List<QueryDocumentSnapshot> documents = querySnapshot.get().getDocuments();

            return convertDocumentsToResponses(documents);

        } catch (ExecutionException | InterruptedException e) {
            throw new ReportSearchFailedException("제보 검색 실패", e);
        }
    }

    private List<ReportResponse> convertDocumentsToResponses(List<QueryDocumentSnapshot> documents) {
        return documents.stream()
                .map(this::mapToReportResponse)
                .filter(Objects::nonNull)
                .toList();
    }

    private ReportResponse mapToReportResponse(QueryDocumentSnapshot document) {
        Double latitude = document.get("latitude", Double.class);
        Double longitude = document.get("longitude", Double.class);
        String wasteCategory = document.getString("wasteCategory");

        if (latitude == null || longitude == null || wasteCategory == null) {
            log.warn("필수 정보 누락 docId: {}", document.getId());
            return null;
        }

        return new ReportResponse(
                document.getId(),
                latitude,
                longitude,
                wasteCategory
        );
    }

}
