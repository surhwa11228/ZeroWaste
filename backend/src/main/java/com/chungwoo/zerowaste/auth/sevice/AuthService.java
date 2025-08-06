package com.chungwoo.zerowaste.auth.sevice;

import com.chungwoo.zerowaste.auth.JwtProvider;
import com.chungwoo.zerowaste.auth.dto.LoginResponse;
import com.chungwoo.zerowaste.auth.dto.RefreshTokenSaveRequest;

import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final JwtProvider jwtProvider;

    public LoginResponse handleLogin(String uid, String email){
        // 사용자 등록 or 조회 (Firestore 또는 RDB)
        // 필요시 별도 UserService로 분리 가능

        // Access & Refresh Token 발급
        String accessToken = jwtProvider.createAccessToken(uid, email);
        RefreshTokenSaveRequest refreshTokenSaveRequest= jwtProvider.createRefreshToken(uid);
        String refreshToken = saveRefreshToken(refreshTokenSaveRequest);

        return new LoginResponse(accessToken, refreshToken);
    }

    private String saveRefreshToken (RefreshTokenSaveRequest refreshTokenSaveRequest) {
        Firestore db = FirestoreClient.getFirestore();

        String uid = refreshTokenSaveRequest.getUid();
        String refreshToken = refreshTokenSaveRequest.getRefreshToken();
        Date expiration = refreshTokenSaveRequest.getExpiration();

        Map<String,Object> data = new HashMap<>();
        data.put("refreshToken", refreshToken);
        data.put("expiration", expiration);

        db.collection("refresh_tokens").document(uid).set(data);


        log.info("Refresh token saved");
        return refreshToken;
    }
}
