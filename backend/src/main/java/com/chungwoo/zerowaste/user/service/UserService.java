package com.chungwoo.zerowaste.user.service;

import com.chungwoo.zerowaste.exception.exceptions.BusinessException;
import com.chungwoo.zerowaste.exception.exceptions.FirestoreOperationException;
import com.chungwoo.zerowaste.user.dto.UserAdditionalInfoRequest;
import com.chungwoo.zerowaste.user.dto.UserInfoResponse;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class UserService {

    public void updateAdditionalInfo(UserAdditionalInfoRequest request, String uid) {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userRef = db.collection("users").document(uid);

        try {
            // 사용자 문서의 현재 데이터를 가져옴
            DocumentSnapshot snapshot = userRef.get().get();  // blocking
            if (!snapshot.exists()) {
                throw new BusinessException(HttpStatus.NOT_FOUND, "User with UID " + uid + " does not exist.");
            }

            // 추가할 정보 (닉네임과 지역)
            Map<String, Object> additionalInfo = new HashMap<>();
            additionalInfo.put("nickname", request.getNickname());  // 닉네임 추가
            additionalInfo.put("region", request.getRegion());  // 지역 추가

            // 기존 문서에 추가 정보 업데이트
            userRef.update(additionalInfo).get();  // blocking

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("유저 정보 업데이트 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("유저 정보 업데이트 실패", e);
        }
    }


    public void registerUser(String uid, String email, DocumentReference userRef) {
        try {
            String temporaryNickname = UUID.randomUUID().toString().replaceAll("-", "").substring(0, 8);

            Map<String, Object> userData = new HashMap<>();
            userData.put("uid", uid);
            userData.put("email", email);
            userData.put("createAt", System.currentTimeMillis());
            userData.put("nickname", temporaryNickname);

            userRef.set(userData).get();

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("유저 정보 등록 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("유저 정보 등록 실패", e);
        }
    }

    public String getNickname(String uid) {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userRef = db.collection("users").document(uid);
        try {
            DocumentSnapshot doc =  userRef.get().get();
            if (!doc.exists()) {
                throw new BusinessException(HttpStatus.NOT_FOUND, "User with UID " + uid + " does not exist.");
            }
            return doc.getString("nickname");

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("유저 정보 검색 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("유저 정보 검색 실패", e);
        }
    }

    public UserInfoResponse getUserInfo(String uid) {
//        Firestore db = FirestoreClient.getFirestore();
//        DocumentReference userRef = db.collection("users").document(uid);
//
//        try {
//            DocumentSnapshot snapshot = userRef.get().get();  // blocking
//            if (!snapshot.exists()) {
//                throw new RuntimeException("User with UID " + uid + " does not exist.");
//            }
//
//            String email = userRef.get
//
//            return UserInfoResponse.builder()
//                    .email()
//
//        } catch (InterruptedException e) {
//            Thread.currentThread().interrupt();
//            throw new FirestoreOperationException("유저 정보 검색 중 인터럽트 발생", e);
//        } catch (ExecutionException e) {
//            throw new FirestoreOperationException("유저 정보 검색 실패", e);
//        }
        return null;
    }


}
