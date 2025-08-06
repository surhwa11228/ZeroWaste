package com.chungwoo.zerowaste.report.service;

import com.chungwoo.zerowaste.auth.dto.AuthUserDetails;
import com.chungwoo.zerowaste.exception.exceptions.ReportSearchFailedException;
import com.chungwoo.zerowaste.exception.exceptions.ReportSubmissionFailedException;
import com.chungwoo.zerowaste.report.dto.DetailedReportResponse;
import com.chungwoo.zerowaste.report.dto.ReportSearchRequest;
import com.chungwoo.zerowaste.report.dto.ReportResponse;
import com.chungwoo.zerowaste.report.dto.ReportSubmissionRequest;
import com.chungwoo.zerowaste.utils.GeoUtils;
import com.chungwoo.zerowaste.utils.ListConverter;
import com.google.api.core.ApiFuture;
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
                                       AuthUserDetails user) {

        Firestore db = FirestoreClient.getFirestore();

        GeoPoint location = GeoUtils.determineTrustedLocation(
                request.getGpsLatitude(),
                request.getGpsLongitude(),
                request.getSelectedLat(),
                request.getSelectedLng()
        );

        Map<String,Object> report = new HashMap<>();
        report.put("uid", user.getUid());
        report.put("latitude", location.getLatitude());
        report.put("longitude",location.getLongitude());
        report.put("wasteCategory", request.getWasteCategory());
        report.put("reportedAt", System.currentTimeMillis());
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

//    public void addAdditionalInfo(String uid, Request request, MultipartFile multipartFile) {
//        Firestore db = FirestoreClient.getFirestore();
//        //request의 uid와 입력받은 uid가 같은지 확인 후, Request의 doc Id를 참조하여 hasAdditionalInfo필드확인
//        //추가 정보가 입력되지 않은 제보라면 추가 정보 입력 허용
//        //입력받은 이미지 업로드 후 주석 등 추가로 db에 저장
//    }
//

    public List<ReportResponse> searchReports(ReportSearchRequest request)  {
        try {
            Firestore db = FirestoreClient.getFirestore();

            //일주일로 설정하여 필터. 추후 가변으로 구현하는 게 좋아보임
            long aWeekAgo = Instant.now()
                    .minus(Duration.ofDays(7))
                    .toEpochMilli();

            CollectionReference reportsRef = db.collection("reports");
            Query query = reportsRef.whereGreaterThan("reportedAt", aWeekAgo);

            //wasteCategory를 설정한 경우 필터
            if (request.getWasteCategory() != null && !request.getWasteCategory().isBlank()) {
                query = query.whereEqualTo("wasteCategory", request.getWasteCategory());
            }

            //중심점으로부터 일정 거리의 최소 경계 박스를 구한 뒤 범위 내의 제보를 쿼리
            GeoUtils.BoundingBox boundingBox = GeoUtils.calculateBoundingBox(
                    request.getCenterLat(),
                    request.getCenterLng(),
                    request.getRadius()
            );
            query = query
                    .whereGreaterThanOrEqualTo("longitude", boundingBox.minLng())
                    .whereLessThanOrEqualTo("longitude", boundingBox.maxLng())
                    .whereGreaterThanOrEqualTo("latitude", boundingBox.minLat())
                    .whereLessThanOrEqualTo("latitude", boundingBox.maxLat())
                    .limit(50);

            ApiFuture<QuerySnapshot> querySnapshot = query.get();
            List<QueryDocumentSnapshot> documents = querySnapshot.get().getDocuments();

            //리스트로 만들어 반환
            return ListConverter.convertDocumentsToList(documents, this::mapToReportResponse);

        } catch (ExecutionException | InterruptedException e) {
            throw new ReportSearchFailedException("제보 검색 실패", e);
        }
    }

    public List<DetailedReportResponse> searchMyReports(Long startAfter, AuthUserDetails user)  {
        try{
            Firestore db = FirestoreClient.getFirestore();
            CollectionReference reportsRef = db.collection("reports");

            Query query = reportsRef.whereEqualTo("uid", user.getUid())
                    .orderBy("reportedAt", Query.Direction.DESCENDING);
            if (startAfter != null) {
                query = query.startAfter(startAfter);
            }
            query = query.limit(10);

            ApiFuture<QuerySnapshot> querySnapshot = query.get();
            List<QueryDocumentSnapshot> documents = querySnapshot.get().getDocuments();

            return ListConverter.convertDocumentsToList(documents, this::mapToDetailedReportResponse);
        }
        catch (ExecutionException | InterruptedException e) {
            throw new ReportSearchFailedException("제보 검색 실패", e);
        }
    }

    private ReportResponse mapToReportResponse(QueryDocumentSnapshot document) {
        Double latitude = document.get("latitude", Double.class);
        Double longitude = document.get("longitude", Double.class);
        String wasteCategory = document.getString("wasteCategory");

        if (latitude == null || longitude == null || wasteCategory == null) {
            log.warn("필수 정보 누락 docId: {}", document.getId());
            return null;
        }

        return ReportResponse.builder()
                .documentId(document.getId())
                .latitude(latitude)
                .longitude(longitude)
                .wasteCategory(wasteCategory)
                .build();
    }
    private DetailedReportResponse mapToDetailedReportResponse(QueryDocumentSnapshot document) {
        Double latitude = document.get("latitude", Double.class);
        Double longitude = document.get("longitude", Double.class);
        String wasteCategory = document.getString("wasteCategory");
        Long reportedAt = document.get("reportedAt", Long.class);
        Boolean hasAdditionalInfo = document.get("hasAdditionalInfo", Boolean.class);

        if (latitude == null || longitude == null || wasteCategory == null
                || reportedAt == null || hasAdditionalInfo == null) {
            log.warn("필수 정보 누락 docId: {}", document.getId());
            return null;
        }

        return DetailedReportResponse.builder()
                .documentId(document.getId())
                .latitude(latitude)
                .longitude(longitude)
                .wasteCategory(wasteCategory)
                .reportedAt(reportedAt)
                .hasAdditionalInfo(hasAdditionalInfo)
                .build();
    }

}
