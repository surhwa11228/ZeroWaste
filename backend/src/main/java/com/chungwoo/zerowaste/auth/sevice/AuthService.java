package com.chungwoo.zerowaste.auth.sevice;

import com.chungwoo.zerowaste.auth.JwtProvider;
import com.chungwoo.zerowaste.auth.dto.AccessTokenResponse;
import com.chungwoo.zerowaste.auth.dto.RefreshTokenSaveRequest;
import com.chungwoo.zerowaste.auth.dto.LoginResponse;
import com.chungwoo.zerowaste.exception.exceptions.EmailNotVerifiedException;
import com.chungwoo.zerowaste.exception.exceptions.FirebaseIdTokenInvalidException;
import com.chungwoo.zerowaste.exception.exceptions.FirestoreOperationException;
import com.chungwoo.zerowaste.exception.exceptions.TokenInvalidException;
import com.chungwoo.zerowaste.utils.TokenUtils;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.cloud.FirestoreClient;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final JwtProvider jwtProvider;

    public LoginResponse handleLogin(HttpServletRequest request) {
        LoginRequest loginRequest = authenticateFirebaseUser(request);

        saveUserIfNew(loginRequest.uid(), loginRequest.email());


        RefreshTokenSaveRequest refreshTokenSaveRequest = jwtProvider.createRefreshToken(loginRequest.uid());
        String accessToken = jwtProvider.createAccessToken(loginRequest.uid(), loginRequest.email());
        String refreshToken = saveRefreshToken(refreshTokenSaveRequest);

        return new LoginResponse(accessToken, refreshToken);
    }

    public AccessTokenResponse refresh(String refreshToken){

        //refresh token 검증
        if (!jwtProvider.validateToken(refreshToken)) {
            throw new TokenInvalidException("유효하지 않은 리프레시 토큰입니다.");
        }

        //refresh token 에서 uid 추출
        String uid = jwtProvider.getUidFromToken(refreshToken);

        //db의 refresh 토큰 검색
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference tokenRef = db.collection("RefreshTokens").document(uid);
        DocumentSnapshot tokenDoc;
        try {
            tokenDoc = tokenRef.get().get(); // blocking
        } catch (InterruptedException | ExecutionException e) {
            throw new FirestoreOperationException("토큰 조회 실패", e);
        }
        if (!tokenDoc.exists()) {
            throw new TokenInvalidException("등록된 리프레시 토큰이 없습니다.");
        }

        //db의 토큰과 일치 여부 확인
        String savedToken = tokenDoc.getString("refreshToken");
        Long expiration = tokenDoc.getLong("expiration");
        if (savedToken == null || !savedToken.equals(refreshToken)) {
            throw new TokenInvalidException("토큰이 일치하지 않습니다.");
        }

        //유효기간 검증
        if (expiration == null || expiration < System.currentTimeMillis()) {
            throw new TokenInvalidException("리프레시 토큰이 만료되었습니다.");
        }

        //User 컬렉션에서 email 회득
        DocumentReference userRef = db.collection("Users").document(uid);
        DocumentSnapshot userDoc;
        try {
            userDoc = userRef.get().get(); // blocking
        } catch (InterruptedException | ExecutionException e) {
            throw new FirestoreOperationException("유저 정보 조회 실패", e);
        }
        if (!userDoc.exists()) {
            throw new TokenInvalidException("해당 UID의 유저 정보가 없습니다.");
        }
        String email = userDoc.getString("email");
        if (email == null) {
            throw new TokenInvalidException("이메일 정보가 없습니다.");
        }

        //uid와 email로 새 access token 발행
        String newAccessToken = jwtProvider.createAccessToken(uid, email);
        return new AccessTokenResponse(newAccessToken);
    }

    private LoginRequest authenticateFirebaseUser(HttpServletRequest request) {
        String idToken = TokenUtils.extractBearerToken(request);
        try {
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
            if (!decodedToken.isEmailVerified()) {
                throw new EmailNotVerifiedException("Email not verified.");
            }
            return new LoginRequest(decodedToken.getUid(), decodedToken.getEmail());
        } catch (FirebaseAuthException e) {
            throw new FirebaseIdTokenInvalidException("Invalid Firebase token", e);  // 커스텀 예외로 포장
        }

    }

    private void saveUserIfNew(String uid, String email) {
        Firestore firestore = FirestoreClient.getFirestore();
        DocumentReference userRef = firestore.collection("Users").document(uid);

        try {
            DocumentSnapshot snapshot = userRef.get().get(); // blocking get
            if (!snapshot.exists()) {
                Map<String, Object> userData = Map.of(
                        "uid", uid,
                        "email", email,
                        "createdAt", System.currentTimeMillis()
                );
                userRef.set(userData);
            }
        } catch (InterruptedException | ExecutionException e) {
            throw new FirestoreOperationException("Failed to check or create user in Firestore", e);
        }
    }


    private String saveRefreshToken (RefreshTokenSaveRequest refreshTokenSaveRequest) {
        Firestore db = FirestoreClient.getFirestore();

        String uid = refreshTokenSaveRequest.getUid();
        String refreshToken = refreshTokenSaveRequest.getRefreshToken();
        Long expiration = refreshTokenSaveRequest.getExpiration();

        Map<String,Object> data = new HashMap<>();
        data.put("refreshToken", refreshToken);
        data.put("expiration", expiration);

        db.collection("refresh_tokens").document(uid).set(data);


        log.info("Refresh token saved");
        return refreshToken;
    }

    private record LoginRequest(String uid, String email) {}
}
