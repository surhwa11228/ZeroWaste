package com.chungwoo.zerowaste.report.service;

import com.chungwoo.zerowaste.report.reportdto.ReportRequestDto;
import com.chungwoo.zerowaste.utils.GeoUtils;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.GeoPoint;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReportService {

    private final FirebaseStorageUploadService firebaseStorageUploadService;

    public void submitReport(MultipartFile image, ReportRequestDto reportDto, String userId){
        try{
            String imageUrl = firebaseStorageUploadService.imageUpload(image);
            Firestore db = FirestoreClient.getFirestore();

            GeoPoint location;
            //gps 위치와 지도선택 위치 간의 거리(오차) 계산
            double distance = GeoUtils
                    .haversine(reportDto.getGpsLatitude(), reportDto.getGpsLongitude(),
                    reportDto.getSelectedLat(),
                    reportDto.getSelectedLng());
            //오차가 40미터 이내일 경우 선택한 위치 반영, 아닐경우 gps 위치 반영
            if(distance < 40){
                location = new GeoPoint(reportDto.getSelectedLat(), reportDto.getSelectedLng());
            }
            else{
                location = new GeoPoint(reportDto.getGpsLatitude(), reportDto.getGpsLatitude());
            }

            Map<String,Object> report = new HashMap<>();
            report.put("userId", userId);
            report.put("location",location);
            report.put("address",reportDto.getAddress());
            report.put("description",reportDto.getDescription());
            report.put("imageUrl", imageUrl);
            report.put("wasteCategory",reportDto.getWasteCategory());
            report.put("reportedAt", reportDto.getReportedAt());

            db.collection("reports").add(report);

        }catch (Exception e){
            log.error("Error while uploading report");
            throw new RuntimeException("Error while uploading report");
        }
    }

}
