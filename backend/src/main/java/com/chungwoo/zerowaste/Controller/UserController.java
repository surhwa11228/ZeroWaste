package com.chungwoo.zerowaste.Controller;

import com.chungwoo.zerowaste.Model.UserDto;
import com.chungwoo.zerowaste.Model.UserRegistrationRequest;
import com.chungwoo.zerowaste.Service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // Register a new user
    @PostMapping("/register")
    public UserDto registerUser(@RequestBody UserRegistrationRequest request) {
        try {
            return userService.registerUser(request);
        } catch (Exception e) {
            throw new RuntimeException("Registration failed: " + e.getMessage());
        }
    }

    // Verify phone number using verification code
    @PostMapping("/verifyPhone")
    public void verifyPhone(@RequestParam String phoneNumber, @RequestParam String verificationCode) {
        try {
            userService.verifyPhoneNumber(phoneNumber, verificationCode);
        } catch (Exception e) {
            throw new RuntimeException("Phone verification failed: " + e.getMessage());
        }
    }

    @GetMapping("/info/{emailId}")
    public UserDto getUserInfo(@PathVariable String emailId) {
        try {
            return userService.getUserInfo(emailId);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get user info: " + e.getMessage());
        }
    }

  /*  @PostMapping("/findPassword")
    public String findPassword(@RequestParam String name, @RequestParam String emailId, @RequestParam String phoneNumber, @RequestParam String verificationCode) {
        try {
            return userService.findPassword(name, emailId, phoneNumber, verificationCode);
        } catch (Exception e) {
            throw new RuntimeException("Failed to find password: " + e.getMessage());
        }
    }*/
    @PostMapping("/login")
    public String login(@RequestParam String emailId, @RequestParam String password) {
        try {
            return userService.login(emailId, password);
        } catch (Exception e) {
            throw new RuntimeException("Login failed: " + e.getMessage());
        }
    }



}

