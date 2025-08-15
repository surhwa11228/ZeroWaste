package com.chungwoo.zerowaste.auth.sevice;

import com.chungwoo.zerowaste.auth.JwtProvider;
import com.chungwoo.zerowaste.auth.dto.AccessTokenResponse;
import com.chungwoo.zerowaste.auth.dto.RefreshTokenSaveRequest;
import com.chungwoo.zerowaste.auth.dto.LoginResponse;
import com.chungwoo.zerowaste.exception.exceptions.EmailNotVerifiedException;
import com.chungwoo.zerowaste.exception.exceptions.FirebaseIdTokenInvalidException;
import com.chungwoo.zerowaste.exception.exceptions.FirestoreOperationException;
import com.chungwoo.zerowaste.exception.exceptions.TokenInvalidException;
import com.chungwoo.zerowaste.user.service.UserService;
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
    private final UserService userService;

    public LoginResponse handleLogin(HttpServletRequest request) {
        //firebase Id Token 검증 및 유저 정보 추출
        LoginRequest loginRequest = authenticateFirebaseUser(request);

        saveUserIfNew(loginRequest.uid(), loginRequest.email());

        String accessToken = jwtProvider.createAccessToken(loginRequest.uid(), loginRequest.email());
        String refreshToken = saveRefreshToken(jwtProvider.createRefreshToken(loginRequest.uid()));

        return new LoginResponse(accessToken, refreshToken);
    }

    public AccessTokenResponse refresh(String refreshToken){

        //refresh 토큰 검증
        validateRefreshToken(refreshToken);

        //refresh token 에서 uid 추출
        String uid = jwtProvider.getUidFromToken(refreshToken);

        //db의 refresh 토큰 검색
        validateStoredRefreshToken(uid, refreshToken);

        //User 컬렉션에서 email 회득
        String email = validateUser(uid);

        //uid와 email로 새 access token 발행
        String newAccessToken = jwtProvider.createAccessToken(uid, email);
        return new AccessTokenResponse(newAccessToken);
    }

    private LoginRequest authenticateFirebaseUser(HttpServletRequest request) {
        String idToken = TokenUtils.extractBearerToken(request);
        try {
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
            if (!decodedToken.isEmailVerified()) {
                throw new EmailNotVerifiedException("인증되지 않은 이메일");
            }
            return new LoginRequest(decodedToken.getUid(), decodedToken.getEmail());
        } catch (FirebaseAuthException e) {
            throw new FirebaseIdTokenInvalidException("유효하지 않은 idToken", e);  // 커스텀 예외로 포장
        }

    }

    private void saveUserIfNew(String uid, String email) {
        Firestore firestore = FirestoreClient.getFirestore();
        DocumentReference userRef = firestore.collection("Users").document(uid);

        try {
            DocumentSnapshot snapshot = userRef.get().get(); // blocking get
            if (!snapshot.exists()) {
                userService.registerUser(uid, email, userRef);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("유저 저장 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("유저 저장 실패", e);
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

    private void validateRefreshToken(String refreshToken) {
        if (!jwtProvider.validateToken(refreshToken)) {
            throw new TokenInvalidException("유효하지 않은 리프레시 토큰입니다.");
        }
    }

    private void validateStoredRefreshToken(String uid, String refreshToken) {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference tokenRef = db.collection("refresh_tokens").document(uid);
        DocumentSnapshot tokenDoc;

        try {
            tokenDoc = tokenRef.get().get(); // blocking
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("토큰 조회 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("토큰 조회 실패", e);
        }

        if (!tokenDoc.exists()) {
            throw new TokenInvalidException("등록된 리프레시 토큰이 없습니다.");
        }

        String savedToken = tokenDoc.getString("refreshToken");
        Long expiration = tokenDoc.getLong("expiration");

        if (savedToken == null || !savedToken.equals(refreshToken)) {
            throw new TokenInvalidException("토큰이 일치하지 않습니다.");
        }

        if (expiration == null || expiration < System.currentTimeMillis()) {
            throw new TokenInvalidException("리프레시 토큰이 만료되었습니다.");
        }
    }

    private String validateUser(String uid) {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userRef = db.collection("users").document(uid);
        DocumentSnapshot userDoc;

        try {
            userDoc = userRef.get().get(); // blocking
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("유저 정보 조회 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("유저 정보 조회 실패", e);
        }

        if (!userDoc.exists()) {
            throw new TokenInvalidException("해당 UID의 유저 정보가 없습니다.");
        }

        String email = userDoc.getString("email");
        if (email == null) {
            throw new TokenInvalidException("이메일 정보가 없습니다.");
        }

        return email;
    }

    private record LoginRequest(String uid, String email) {}
}
