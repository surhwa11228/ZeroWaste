package com.chungwoo.zerowaste.report.service;

import com.chungwoo.zerowaste.auth.dto.AuthUserDetails;
import com.chungwoo.zerowaste.exception.exceptions.BusinessException;
import com.chungwoo.zerowaste.exception.exceptions.FirestoreOperationException;
import com.chungwoo.zerowaste.report.dto.*;
import com.chungwoo.zerowaste.report.model.ReportSubmit;
import com.chungwoo.zerowaste.upload.UploadConstants;
import com.chungwoo.zerowaste.upload.service.StorageImageUploader;
import com.chungwoo.zerowaste.utils.GeoUtils;
import com.chungwoo.zerowaste.utils.ImageUtils;
import com.chungwoo.zerowaste.utils.ListConverter;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.print.Doc;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ExecutionException;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReportService {

    private final StorageImageUploader storageImageUploader;

    public ReportResponse submitReport(ReportSubmissionRequest request,
                                       String uid) {

        Firestore db = FirestoreClient.getFirestore();

        GeoPoint location = GeoUtils.determineTrustedLocation(
                request.getGpsLatitude(),
                request.getGpsLongitude(),
                request.getSelectedLat(),
                request.getSelectedLng()
        );

        ReportSubmit report = ReportSubmit.builder()
                .uid(uid)
                .latitude(location.getLatitude())
                .longitude(location.getLongitude())
                .wasteCategory(request.getWasteCategory())
                .reportedAt(System.currentTimeMillis())
                .hasAdditionalInfo(false)
                .build();

        try {
            DocumentReference docRef = db.collection("reports").add(report).get(); // 동기
            log.info("Report submitted: {}", docRef.getId());

            return new ReportResponse(
                    docRef.getId(),
                    report.getLatitude(),
                    report.getLongitude(),
                    report.getWasteCategory(),
                    report.getReportedAt(),
                    report.isHasAdditionalInfo()
            );

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("제보 저장 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("제보 저장 실패", e);
        }
    }


    public void saveAdditionalInfo(String documentId, ReportAdditionalInfoRequest request, MultipartFile image, String uid) {
        try{
            Firestore db = FirestoreClient.getFirestore();
            DocumentSnapshot savedReport =
                    db.collection("reports").document(documentId).get().get();

            if(!savedReport.exists()){
                throw new BusinessException(HttpStatus.NOT_FOUND, "존재하지 않는 제보");
            }
            if(!Objects.requireNonNull(savedReport.getString("uid")).equals(uid)){
                throw new BusinessException(HttpStatus.FORBIDDEN, "uid 다름");
            }
            if(Boolean.TRUE.equals(savedReport.get("hasAdditionalInfo", boolean.class))){
                throw new BusinessException(HttpStatus.FORBIDDEN, "이미 등록된 제보");
            }


            Map<String,String> savedImage = null;
            if(image != null && !image.isEmpty()){
                savedImage = storageImageUploader.upload(UploadConstants.REPORT, image);
            }

            Map<String,Object> additionalInfo = new HashMap<>();
            additionalInfo.put("hasAdditionalInfo",true);
            additionalInfo.put("image", savedImage);
            additionalInfo.put("description", request.getDescription());

            DocumentReference docRef = savedReport.getReference();
            docRef.set(additionalInfo);


        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("제보 저장 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("제보 저장 실패", e);
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
            return ListConverter.convertDocumentsToList
                    (documents, this::mapToReportResponse);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("제보 검색 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("제보 검색 실패", e);
        }
    }

    public List<ReportResponse> searchMyReports(Long startAfter, AuthUserDetails user)  {
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

            return ListConverter.convertDocumentsToList
                    (documents, this::mapToReportResponse);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("제보 검색 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("제보 검색 실패", e);
        }
    }

    private ReportResponse mapToReportResponse(QueryDocumentSnapshot document) {
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

        return ReportResponse.builder()
                .documentId(document.getId())
                .latitude(latitude)
                .longitude(longitude)
                .wasteCategory(wasteCategory)
                .reportedAt(reportedAt)
                .hasAdditionalInfo(hasAdditionalInfo)
                .build();
    }

    public DetailedReportResponse showDetailedReport(String documentId) {
        try{
            Firestore db = FirestoreClient.getFirestore();
            DocumentSnapshot doc = db.collection("reports").document(documentId).get().get();

            return mapToDetailedReportResponse(doc);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("제보 검색 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("제보 검색 실패", e);
        }

    }


    private DetailedReportResponse mapToDetailedReportResponse(DocumentSnapshot document) {
        Map<String, String> savedImage = null;
        String imageUrl = null;
        String description = null;
        if(Boolean.TRUE.equals(document.get("hasAdditionalInfo", Boolean.class))){
            savedImage = (Map<String,String>) document.get("image");
            description = document.getString("description");
        }
        if(savedImage != null && !savedImage.isEmpty()){
            imageUrl = savedImage.get("url");
        }
        return new DetailedReportResponse(
                imageUrl,
                description
        );
    }


}
