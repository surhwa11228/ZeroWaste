package com.chungwoo.zerowaste.Service;

import com.chungwoo.zerowaste.Model.PhoneVerificationDto;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ExecutionException;

@Service
public class PhoneVerificationService {

    private final Firestore db = FirestoreClient.getFirestore();

    public PhoneVerificationDto sendVerificationCode(String phoneNumber) {
        String verificationCode = generateVerificationCode();
        Date expiresAt = new Date(System.currentTimeMillis() + 10 * 60 * 1000);

        // PhoneVerificationDto를 Map으로 변환
        Map<String, Object> verificationMap = new HashMap<>();
        verificationMap.put("phoneNumber", phoneNumber);
        verificationMap.put("verificationCode", verificationCode);
        verificationMap.put("expiresAt", expiresAt);
        verificationMap.put("createdAt", new Date());
        verificationMap.put("verified", false);

        // Firestore에 저장
        DocumentReference docRef = db.collection("phoneVerifications").document(phoneNumber);
        ApiFuture<WriteResult> result = docRef.set(verificationMap);

        // 반환할 DTO
        PhoneVerificationDto dto = new PhoneVerificationDto();
        dto.setPhoneNumber(phoneNumber);
        dto.setVerificationCode(verificationCode);
        dto.setExpiresAt(expiresAt);
        dto.setCreatedAt(new Date());
        dto.setVerified(false);

        return dto;
    }

    private String generateVerificationCode() {
        Random random = new Random();
        return String.format("%06d", random.nextInt(1000000));
    }
}

