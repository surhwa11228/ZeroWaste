package com.chungwoo.zerowaste.auth.sevice;

import com.chungwoo.zerowaste.auth.dto.RefreshTokenSaveRequest;

import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
public class AuthService {

    public void saveRefreshToken (RefreshTokenSaveRequest refreshTokenSaveRequest) {
        Firestore db = FirestoreClient.getFirestore();

        String uid = refreshTokenSaveRequest.getUid();
        String refreshToken = refreshTokenSaveRequest.getRefreshToken();
        Date expiration = refreshTokenSaveRequest.getExpiration();

        Map<String,Object> data = new HashMap<>();
        data.put("refreshToken", refreshToken);
        data.put("expiration", expiration);

        db.collection("refresh_tokens").document(uid).set(data);
        log.info("Refresh token saved");
    }
}
