package com.chungwoo.zerowaste.board.service;

import com.chungwoo.zerowaste.board.boarddto.*;
import com.chungwoo.zerowaste.board.model.Comment;
import com.chungwoo.zerowaste.exception.exceptions.BusinessException;
import com.chungwoo.zerowaste.exception.exceptions.FirestoreOperationException;
import com.chungwoo.zerowaste.upload.UploadConstants;
import com.chungwoo.zerowaste.upload.service.StorageImageUploader;
import com.chungwoo.zerowaste.user.service.UserService;
import com.chungwoo.zerowaste.utils.ListConverter;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.concurrent.ExecutionException;

@Slf4j
@Service
@RequiredArgsConstructor
public class BoardService {

    private final StorageImageUploader imageUploader;
    private final UserService userService;
    /** 게시글 작성 */
    public PostResult post(String boardName,
                           List<MultipartFile> images,
                           PostRequest postRequest,
                           String uid) {
        try {
            Firestore db = FirestoreClient.getFirestore();

            List<Map<String,String>> savedImages = imageUploader.upload(UploadConstants.BOARD, images);

            // 🔹 게시글 정보 생성
            Map<String, Object> post = new HashMap<>();
            post.put("title", postRequest.getTitle());
            post.put("content", postRequest.getContent());
            post.put("images", savedImages);
            post.put("uid", uid);
            post.put("nickname", userService.getNickname(uid));
            post.put("boardName", boardName);  // scope 대신 boardName으로 구별
            post.put("category", postRequest.getCategory());
            post.put("createdAt", System.currentTimeMillis());

            // 🔹 Firestore 트랜잭션으로 게시글 ID 생성 및 게시글 저장
            String postId = db.runTransaction(transaction -> {
                // 🔹 게시글 ID 생성
                DocumentReference counterRef = db.collection("counters").document("postId");
                DocumentSnapshot snapshot = transaction.get(counterRef).get();

                Long currentValue = snapshot.getLong("value");
                if (currentValue == null) currentValue = 0L;

                Long nextValue = currentValue + 1;
                transaction.set(counterRef, Collections.singletonMap("value", nextValue)); // ID 증가

                // 🔹 Firestore에 게시글 저장
                transaction.set(db.collection(boardName).document(String.valueOf(nextValue)), post); // 게시글 저장

                return String.valueOf(nextValue);  // 트랜잭션에서 새 게시글 ID 반환
            }).get();  // blocking

            return new PostResult(postId, boardName);  // 게시글 ID와 boardName 반환

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("트랜잭션 실패 - 스레드 인터럽트", e);
        } catch (ExecutionException e) {
            throw new RuntimeException("트랜잭션 실패", e);
        }
    }

    /** 게시글 목록 조회 */
    public List<PostResponse> getPosts(String boardName, String category, Long startAfter) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            Query query = db.collection(boardName);
            if(boardName != null){
                query = query.whereEqualTo("boardName", boardName);
            }
            if(category != null){
                query = query.whereEqualTo("category", category);
            }
            query = query.orderBy("createdAt", Query.Direction.DESCENDING);
            if(startAfter != null){
                query = query.startAfter(startAfter);
            }
            query = query.limit(20);

            ApiFuture<QuerySnapshot> querySnapshot = query.get();
            List<QueryDocumentSnapshot> docs = querySnapshot.get().getDocuments();

            return ListConverter.convertDocumentsToList(docs, this::mapToPostResponse);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("게시글 검색 중 오류 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("게시글 검색 실패", e);
        }
    }

    /** 게시글 상세 조회 */
    public DetailedPostResponse getPostById(String boardName, String id) {
        Firestore db = FirestoreClient.getFirestore();//board db
        try {
            DocumentSnapshot doc = db.collection(boardName).document(id).get().get();

            List<String> imageUrls = new ArrayList<>();
            List<Map<String,String>> images = (List<Map<String,String>>) doc.get("images");
            if(images != null && !images.isEmpty()){
                for (Map<String,String> image : images){
                    imageUrls.add(image.get("url"));
                }
            }

            return DetailedPostResponse.builder()
                    .postId(doc.getId())
                    .uid(doc.getString("userId"))
                    .nickname(doc.getString("nickname"))
                    .title(doc.getString("title"))
                    .content(doc.getString("content"))
                    .category(doc.getString("category"))
                    .boardName(doc.getString("boardName"))
                    .imageUrls(imageUrls)
                    .createdAt(doc.getLong("createdAt"))
                    .build();

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("게시글 상세 조회 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("게시글 상세 조회 실패", e);
        }
    }

    /** 게시글 수정 */
    public PostResult updatePost(String boardName,
                                 String postId,
                                 List<MultipartFile> images,
                                 PostRequest postRequest,
                                 String uid) {

        Firestore db = FirestoreClient.getFirestore();

        try {
            DocumentReference postRef = db.collection(boardName).document(postId);
            DocumentSnapshot doc = postRef.get().get();

            if (!doc.exists())
                throw new BusinessException(HttpStatus.NOT_FOUND, "게시글 없음"); //404

            if (!doc.getString("uid").equals(uid))
                throw new BusinessException(HttpStatus.FORBIDDEN, "권한없음"); //403

            List<Map<String,String>> savedImages = (List<Map<String,String>>) doc.get("images");
            if (images != null && !images.isEmpty()) {
                savedImages = imageUploader.upload(UploadConstants.BOARD, images);
            }

            Map<String, Object> updateData = new HashMap<>();
            updateData.put("title", postRequest.getTitle());
            updateData.put("content", postRequest.getContent());
            updateData.put("category", postRequest.getCategory());
            updateData.put("images", savedImages);
            updateData.put("nickname", userService.getNickname(uid));

            postRef.update(updateData).get(); // 동기 저장
            return new PostResult(postId, boardName);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("게시글 수정 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("게시글 수정 실패", e);
        }
    }

    /** 게시글 삭제 */
    public void deletePost(String boardName, String postId, String uid) {
        Firestore db = FirestoreClient.getFirestore();
        try {
            DocumentReference ref = db.collection(boardName).document(postId);
            DocumentSnapshot doc = ref.get().get();
            if (!doc.exists())
                throw new BusinessException(HttpStatus.NOT_FOUND, "게시글 없음"); //404

            if (!doc.getString("uid").equals(uid))
                throw new BusinessException(HttpStatus.FORBIDDEN, "권한없음"); //403

            ref.delete().get(); // 동기 삭제
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("게시글 삭제 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("게시글 삭제 실패", e);
        }
    }

    // ==================== 💬 댓글/대댓글 CRUD ====================

    public PostResult addComment(String boardName, String postId, CommentDto dto, String uid) {
        Firestore db = FirestoreClient.getFirestore();
        String commentId = UUID.randomUUID().toString();

        Map<String,Object> commentData = new HashMap<>();
        commentData.put("commentId", commentId);
        commentData.put("parentId", dto.getParentId());
        commentData.put("content", dto.getContent());
        commentData.put("uid", uid);
        commentData.put("createAt", System.currentTimeMillis());

        try {
            db.collection(boardName).document(postId)
                    .collection("comments").document(commentId)
                    .set(commentData).get();

            return new PostResult(postId, boardName);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("댓글 등록 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("댓글 등록 실패", e);
        }
    }

    public List<Comment> getComments(String boardName, String postId) {
        Firestore db = FirestoreClient.getFirestore();
        List<Comment> comments = new ArrayList<>();

        try {
            List<QueryDocumentSnapshot> docs = db.collection(boardName)
                    .document(postId)
                    .collection("comments")
                    .get().get().getDocuments();

            for (QueryDocumentSnapshot doc : docs) {
                comments.add(doc.toObject(Comment.class));
            }

            comments.sort(Comparator.comparing(Comment::getCreatedAt).reversed());

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("댓글 불러오기 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("댓글 불러오기 실패", e);
        }

        return comments;
    }

    public void deleteComment(String boardName, String postId, String commentId, String uid) {
        Firestore db = FirestoreClient.getFirestore();
        try {
            DocumentReference commentRef = db.collection(boardName)
                    .document(postId)
                    .collection("comments")
                    .document(commentId);

            DocumentSnapshot snapshot = commentRef.get().get();
            if (!snapshot.exists())
                throw new BusinessException(HttpStatus.NOT_FOUND, "댓글 없음"); //404

            Comment comment = snapshot.toObject(Comment.class);
            if (!comment.getUid().equals(uid))
                throw new BusinessException(HttpStatus.FORBIDDEN, "권한없음"); //403

            commentRef.delete().get();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new FirestoreOperationException("댓글 삭제 중 인터럽트 발생", e);
        } catch (ExecutionException e) {
            throw new FirestoreOperationException("댓글 삭제 실패", e);
        }
    }


    private PostResponse mapToPostResponse(QueryDocumentSnapshot document) {
        String postId = document.getId();
        String title = document.getString("title");
        String uid = document.getString("uid");
        String nickname = document.getString("nickname");
        Long createdAt = document.getLong("createdAt");

        // 필수 필드 검증 (필요 시)
        if (title == null || uid == null || nickname == null || createdAt == null) {
            log.warn("필수 게시글 정보 누락 documentId: {}", postId);
            return null;
        }

        return PostResponse.builder()
                .postId(postId)
                .title(title)
                .createdAt(createdAt)
                .uid(uid)
                .nickname(nickname)
                .build();
    }

}
