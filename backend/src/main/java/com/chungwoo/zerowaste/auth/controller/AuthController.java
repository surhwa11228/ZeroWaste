package com.chungwoo.zerowaste.auth.controller;

import com.chungwoo.zerowaste.api.ApiResponse;
import com.chungwoo.zerowaste.auth.JwtProvider;
import com.chungwoo.zerowaste.auth.dto.LoginResponse;
import com.chungwoo.zerowaste.auth.dto.RefreshTokenSaveRequest;
import com.chungwoo.zerowaste.auth.sevice.AuthService;
import com.chungwoo.zerowaste.exception.exceptions.EmailNotVerifiedException;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import lombok.RequiredArgsConstructor;
import lombok.extern.java.Log;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.security.auth.login.LoginException;
import java.util.Date;
import java.util.Map;
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;


    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@RequestHeader("Authorization") String authorizationHeader) throws FirebaseAuthException {
        log.debug("authorization {}", authorizationHeader);
        String idToken = extractToken(authorizationHeader);
        FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
        if(!decodedToken.isEmailVerified()){
            throw new EmailNotVerifiedException("일단아무렇게");
        }



        String uid = decodedToken.getUid();
        String email = decodedToken.getEmail();

//        String uid = "testUid";
//        String email = "TestEmail@email.com";

        LoginResponse loginResponse = authService.handleLogin(uid, email);

        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(loginResponse));

    }


    //JwtFilter랑 중복되기 때문에 리팩터링 필요해보임
    private String extractToken(String header){
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        throw new IllegalArgumentException("Invalid Authorization header");
    }
}

