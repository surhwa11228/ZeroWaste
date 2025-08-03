package com.chungwoo.zerowaste.Controller;

import com.chungwoo.zerowaste.Request.SendVerificationRequest;
import com.chungwoo.zerowaste.Service.PhoneVerificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/phone")
@RequiredArgsConstructor
public class PhoneVerificationController {

    private final PhoneVerificationService phoneVerificationService;

    // JSON body 로 전화번호만 받아서 코드 전송
    @PostMapping(value = "/send", consumes = MediaType.APPLICATION_JSON_VALUE)
    public void sendVerificationCode(@RequestBody SendVerificationRequest req) {
        phoneVerificationService.sendVerificationCode(req.getPhoneNumber());
    }
}

