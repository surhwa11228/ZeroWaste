package com.chungwoo.zerowaste.Controller;

import com.chungwoo.zerowaste.Model.UserDto;
import com.chungwoo.zerowaste.Model.UserRegistrationRequest;
import com.chungwoo.zerowaste.Service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping(value = "/register", consumes = MediaType.APPLICATION_JSON_VALUE)
    public UserDto registerUser(@RequestBody UserRegistrationRequest request) {
        return userService.registerUser(request);
    }

    @PostMapping("/verifyPhone")
    public void verifyPhone(@RequestParam String phoneNumber,
                            @RequestParam String verificationCode) {
        userService.verifyPhoneNumber(phoneNumber, verificationCode);
    }

    @GetMapping("/info/{emailId}")
    public UserDto getUserInfo(@PathVariable String emailId) {
        return userService.getUserInfo(emailId);
    }

    @PostMapping("/findId")
    public String findId(@RequestParam String name,
                         @RequestParam String phoneNumber,
                         @RequestParam String verificationCode) {
        return userService.findId(name, phoneNumber, verificationCode);
    }

    @PostMapping("/findPassword")
    public String findPassword(@RequestParam String name,
                               @RequestParam String emailId,
                               @RequestParam String phoneNumber,
                               @RequestParam String verificationCode) {
        return userService.findPassword(name, emailId, phoneNumber, verificationCode);
    }

    @PostMapping("/login")
    public String login(@RequestParam String emailId,
                        @RequestParam String password) {
        return userService.login(emailId, password);
    }
}
