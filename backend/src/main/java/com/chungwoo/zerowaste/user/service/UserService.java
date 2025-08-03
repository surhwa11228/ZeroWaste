package com.chungwoo.zerowaste.user.service;

import com.chungwoo.zerowaste.user.Request.UserRegistrationRequest;
import com.chungwoo.zerowaste.user.dto.UserDto;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class UserService {

    public UserDto registerUser(UserRegistrationRequest request) throws ExecutionException {
        try {
            Firestore db = FirestoreClient.getFirestore();
            if (!db.collection("users").document("testUid").get().get().exists()) {
                //save user data (document ID <- uid, document fields <- email, region, etc...)
            }
            else{
                //do nothing
            }

            Map<String, Object> userMap = new HashMap<>();
            userMap.put("emailId", request.getEmailId());
            userMap.put("name", request.getName());
            userMap.put("phoneNumber", request.getPhoneNumber());
            userMap.put("address", request.getAddress());
            userMap.put("birthDate", request.getBirthDate());
            //userMap.put("password", request.getPassword());
            userMap.put("phoneVerified", false);

            db.collection("users").document("testUid").set(userMap);

            UserDto dto = new UserDto();
            dto.setEmailId(request.getEmailId());
            dto.setName(request.getName());
            dto.setPhoneNumber(request.getPhoneNumber());
            dto.setAddress(request.getAddress());
            dto.setBirthDate(request.getBirthDate());
            dto.setPhoneVerified(false);
            return dto;

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Registration failed: " + e.getMessage(), e);
        }
    }

    public UserDto getUserInfo(String emailId) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentReference ref = db.collection("users").document(emailId);
            DocumentSnapshot doc = ref.get().get();
            if (!doc.exists()) throw new RuntimeException("User not found");
            return doc.toObject(UserDto.class);
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error fetching user info", e);
        }
    }


    //login은 auth 패키지의 Auth*로 구현
    public String login(String emailId, String password) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            Query query = db.collection("users").whereEqualTo("emailId", emailId);
            QuerySnapshot snapshot = query.get().get();
            if (snapshot.isEmpty()) throw new RuntimeException("User not found");

            String storedPassword = snapshot.getDocuments().get(0).getString("password");
            if (!storedPassword.equals(password)) throw new RuntimeException("Invalid password");
            return "Login successful";
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Login failed", e);
        }
    }
}
