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

        FirebaseToken firebaseToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
        String accessToken = "";
        String refreshToken = "";

        authService.saveRefreshToken(new RefreshTokenSaveRequest("","",new Date()));
        return ResponseEntity.ok("ok");

        //구현중
    }

    private String extractToken(String header){
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        throw new IllegalArgumentException("Invalid Authorization header");
    }
}

