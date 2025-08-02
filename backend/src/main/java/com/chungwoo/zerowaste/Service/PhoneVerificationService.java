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

   /* private final Firestore db = FirestoreClient.getFirestore();

    // 전화번호 인증 코드 전송
    public PhoneVerificationDto sendVerificationCode(String phoneNumber) {
        String verificationCode = generateVerificationCode();
        Date expiresAt = new Date(System.currentTimeMillis() + 10 * 60 * 1000);  // 10분 후 만료

        // Firestore에 저장할 데이터 준비
        Map<String, Object> verificationMap = new HashMap<>();
        verificationMap.put("phoneNumber", phoneNumber);
        verificationMap.put("verificationCode", verificationCode);
        verificationMap.put("expiresAt", expiresAt);
        verificationMap.put("createdAt", new Date());
        verificationMap.put("verified", false);

        // Firestore에 인증 정보 저장
        DocumentReference docRef = db.collection("phoneVerifications").document(phoneNumber);
        ApiFuture<WriteResult> result = docRef.set(verificationMap);

        // DTO 반환
        PhoneVerificationDto dto = new PhoneVerificationDto();
        dto.setPhoneNumber(phoneNumber);
        dto.setVerificationCode(verificationCode);
        dto.setExpiresAt(expiresAt);
        dto.setCreatedAt(new Date());
        dto.setVerified(false);

        return dto;
    }*/
   /*private final Firestore db = FirestoreClient.getFirestore();

    // 전화번호 인증 코드 조회
    public PhoneVerificationDto getVerification(String phoneNumber) {
        try {
            // 전화번호에 해당하는 인증 정보를 Firestore에서 조회
            DocumentReference docRef = db.collection("phoneVerifications").document(phoneNumber);
            ApiFuture<DocumentSnapshot> future = docRef.get();
            DocumentSnapshot document = future.get();

            if (document.exists()) {
                return document.toObject(PhoneVerificationDto.class); // Firestore 문서를 DTO로 변환하여 반환
            } else {
                throw new RuntimeException("Verification data not found for phone number: " + phoneNumber);
            }
        } catch (Exception e) {
            throw new RuntimeException("Error fetching verification data", e);
        }
    }
*/

    private String generateVerificationCode() {
        Random random = new Random();
        return String.format("%06d", random.nextInt(1000000));
    }
}

