package com.chungwoo.zerowaste.report.service;

import com.chungwoo.zerowaste.report.dto.ReportRequestDto;
import com.chungwoo.zerowaste.upload.dto.ImageUploadResult;
import com.chungwoo.zerowaste.utils.GeoUtils;
import com.chungwoo.zerowaste.utils.StorageUploadUtils;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.GeoPoint;
import com.google.firebase.cloud.FirestoreClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service

public class ReportService {


    public void submitReport(MultipartFile image, ReportRequestDto reportDto, String userId){
        try{
            ImageUploadResult imageUploadResult = StorageUploadUtils.imageUpload(StorageUploadUtils.REPORT, image);
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
            report.put("imageUrl", imageUploadResult.getFileName());
            report.put("imageName", imageUploadResult.getFileName());
            report.put("wasteCategory",reportDto.getWasteCategory());
            report.put("reportedAt", reportDto.getReportedAt());

            db.collection("reports").add(report);

        }catch (Exception e){
            log.error("Error while uploading report");
            throw new RuntimeException("Error while uploading report");
        }
    }

}
