package com.chungwoo.zerowaste.report.service;

import com.google.cloud.firestore.Firestore;
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

    public void upload(MultipartFile image, ReportDto reportDto, String uid){
        try{
            Firestore db = FirestoreClient.getFirestore();

            Map<String,Object> report = new HashMap<>();
            report.put("uid",uid);
            report.put("imageUrl",imageUrl);


        }catch (Exception e){
            log.error("Error while uploading report");
            throw new RuntimeException("Error while uploading report");
        }
    }

}
