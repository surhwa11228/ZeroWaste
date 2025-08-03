package com.chungwoo.zerowaste.auth.controller;

import com.chungwoo.zerowaste.auth.JwtProvider;
import com.chungwoo.zerowaste.auth.dto.RefreshTokenSaveRequest;
import com.chungwoo.zerowaste.auth.sevice.AuthService;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import java.util.Date;

@RestController
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;


    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestHeader("Authorization") String authorizationHeader) throws FirebaseAuthException {
        String idToken = extractToken(authorizationHeader);
        FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
        decodedToken.isEmailVerified();

        //클라이언트 - Firebase Auth 간의 로그인을 통해 발행된 IdToken 추출
        //토큰은 일반적으로 Authorization 헤더에 담겨져 오며 "Bearer <token>"의 형태로 담겨져있음
        //FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken); 과 같이 토큰 검증
        //검증된 토큰으로 이메일 인증 여부 체크. decodedToken.isEmailVerified();
        //email 인증이 false인 경우 로그인 불가
        //(Firebase Auth-google 등의 소셜 로그인의 경우 기본적으로 true,
        //Firebase Auth-email의 경우 클라이언트에서 Firebase Auth api를 통해 email 인증 요청)
        //idToken의 uid를 통해 db의 user 조회. 없다면 새 user 생성 (uid(documentID로 설정), email, createAt etc)
        //액세스 토큰과 리프레시 토큰 발급, 리프레시 토큰은 db에 저장
        //발행한 2개의 토큰을 Response에 담아서 전송(어떤 방식으로 담을지 조사 해야함. 아직 생각 못 함)


        return ResponseEntity.ok("ok");

        //구현중
    }


    //JwtFilter랑 중복되기 때문에 리팩터링 필요해보임
    private String extractToken(String header){
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        throw new IllegalArgumentException("Invalid Authorization header");
    }
}

