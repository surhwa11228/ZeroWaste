package com.chungwoo.zerowaste.Service;

import com.chungwoo.zerowaste.Model.PhoneVerificationDto;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class PhoneVerificationService {

    private final Firestore db;

    public PhoneVerificationDto sendVerificationCode(String phoneNumber) {
        String code = generateVerificationCode();
        Date now = new Date();
        Date expiresAt = new Date(now.getTime() + 10 * 60 * 1000);

        Map<String, Object> map = new HashMap<>();
        map.put("phoneNumber", phoneNumber);
        map.put("verificationCode", code);
        map.put("createdAt", now);
        map.put("expiresAt", expiresAt);
        map.put("verified", false);

        db.collection("phoneVerifications").document(phoneNumber).set(map);

        PhoneVerificationDto dto = new PhoneVerificationDto();
        dto.setPhoneNumber(phoneNumber);
        dto.setVerificationCode(code);
        dto.setCreatedAt(now);
        dto.setExpiresAt(expiresAt);
        dto.setVerified(false);
        return dto;
    }

    public PhoneVerificationDto getVerification(String phoneNumber) {
        try {
            DocumentSnapshot doc = db.collection("phoneVerifications")
                    .document(phoneNumber).get().get();
            if (!doc.exists()) throw new RuntimeException("Verification not found");
            return doc.toObject(PhoneVerificationDto.class);
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error fetching verification", e);
        }
    }

    private String generateVerificationCode() {
        return String.format("%06d", new Random().nextInt(1_000_000));
    }
}