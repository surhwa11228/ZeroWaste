package com.chungwoo.zerowaste.utils;

import jakarta.servlet.http.HttpServletRequest;

public class TokenUtils {
    private TokenUtils() {}

    public static String extractBearerToken(HttpServletRequest request){
        String bearer = request.getHeader("Authorization");
        return (bearer != null && bearer.startsWith("Bearer ")) ? bearer.substring(7) : null;
    }
}
