package com.chungwoo.zerowaste.auth;

import com.chungwoo.zerowaste.auth.dto.AuthUserDetails;
import com.chungwoo.zerowaste.utils.TokenUtils;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Slf4j
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtProvider jwtProvider;

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain) throws ServletException, IOException {
        log.debug("doFilterInternal");
        String token = TokenUtils.extractBearerToken(request);

        if (token != null) {
            try {
                Claims claims = jwtProvider.parseToken(token); // 무효면 JwtException
                AuthUserDetails user = new AuthUserDetails(claims.getSubject(), claims.get("email", String.class));
                Authentication auth = new UsernamePasswordAuthenticationToken(user, null, List.of());
                SecurityContextHolder.getContext().setAuthentication(auth);
            } catch (JwtException | IllegalArgumentException e) {
                // “토큰이 존재하지만 유효하지 않음” → 인증 예외로 위임 → EntryPoint가 401 반환
                throw new org.springframework.security.core.AuthenticationException("Invalid JWT", e) {};
            }
        }

        filterChain.doFilter(request, response);
    }
}
