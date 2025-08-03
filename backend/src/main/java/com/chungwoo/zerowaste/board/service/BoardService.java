package com.chungwoo.zerowaste.board.service;

import com.chungwoo.zerowaste.board.boarddto.BoardDto;
import com.chungwoo.zerowaste.board.boarddto.CommentDto;
import com.chungwoo.zerowaste.board.model.Post;
import com.chungwoo.zerowaste.board.model.Comment;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ExecutionException;

/**
 * 게시판 서비스 클래스
 * - Firestore를 이용한 게시글/댓글 CRUD 로직 구현
 * - Controller에서 호출하여 데이터 처리 담당
 */
@Service
@RequiredArgsConstructor
public class BoardService {

    /** ----------------- 게시글 CRUD ----------------- **/

    /**
     * 게시글 작성
     * @param image    첨부 이미지 (Firebase Storage 연동 예정)
     * @param boardDto 작성 요청 DTO
     * @param userId   작성자 UID
     * @return 저장된 게시글(Post)
     */
    public Post post(MultipartFile image, BoardDto boardDto, String userId) {
        try {
            Firestore db = FirestoreClient.getFirestore();

            // 이미지 업로드는 추후 Firebase Storage 연동 예정
            String imageUrl = (image != null) ? "uploaded/image/path" : null;

            // 랜덤 UUID를 게시글 ID로 사용
            String postId = UUID.randomUUID().toString();

            // Post 객체 생성
            Post post = Post.builder()
                    .id(postId)
                    .userId(userId)
                    .title(boardDto.getTitle())
                    .content(boardDto.getContent())
                    .category(boardDto.getCategory())
                    .scope(boardDto.getScope())
                    .imageUrl(imageUrl)
                    .createdAt(Instant.now().toEpochMilli()) // 작성 시간 timestamp
                    .pinned(false) // 기본값: 상단 고정 아님
                    .build();

            // Firestore에 저장
            db.collection("posts").document(postId).set(post).get();
            return post;

        } catch (Exception e) {
            throw new RuntimeException("게시글 작성 중 오류 발생", e);
        }
    }

    /**
     * 게시글 목록 조회
     * - 카테고리 / 공개범위 / 키워드 검색 지원
     * - 상단 고정글 먼저, 최신순 정렬
     */
    public List<Post> getPosts(String category, String scope, String keyword) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            ApiFuture<QuerySnapshot> future = db.collection("posts").get();
            List<QueryDocumentSnapshot> documents = future.get().getDocuments();

            List<Post> posts = new ArrayList<>();
            for (DocumentSnapshot doc : documents) {
                Post post = doc.toObject(Post.class);
                if (post == null) continue;

                // 필터링
                if (category != null && !post.getCategory().equals(category)) continue;
                if (scope != null && !post.getScope().equals(scope)) continue;
                if (keyword != null && !post.getTitle().contains(keyword) && !post.getContent().contains(keyword)) continue;

                posts.add(post);
            }

            // 상단 고정글 우선 → 최신순 정렬
            posts.sort(Comparator.comparing(Post::isPinned).reversed()
                    .thenComparing(Post::getCreatedAt).reversed());

            return posts;

        } catch (Exception e) {
            throw new RuntimeException("게시글 목록 조회 오류", e);
        }
    }

    /**
     * 게시글 상세 조회
     * @param postId 조회할 게시글 ID
     * @return 게시글(Post)
     */
    public Post getPost(String postId) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentSnapshot snapshot = db.collection("posts").document(postId).get().get();

            if (!snapshot.exists()) return null;
            return snapshot.toObject(Post.class);

        } catch (Exception e) {
            throw new RuntimeException("게시글 상세 조회 오류", e);
        }
    }

    /**
     * 게시글 수정
     * @param postId 수정할 게시글 ID
     * @param boardDto 수정 내용 DTO
     * @return 수정 후 게시글(Post)
     */
    public Post updatePost(String postId, BoardDto boardDto) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentReference docRef = db.collection("posts").document(postId);

            if (!docRef.get().get().exists()) {
                throw new RuntimeException("게시글이 존재하지 않습니다.");
            }

            Map<String, Object> updates = new HashMap<>();
            updates.put("title", boardDto.getTitle());
            updates.put("content", boardDto.getContent());
            updates.put("category", boardDto.getCategory());
            updates.put("scope", boardDto.getScope());

            docRef.update(updates).get();

            return docRef.get().get().toObject(Post.class);

        } catch (Exception e) {
            throw new RuntimeException("게시글 수정 오류", e);
        }
    }

    /**
     * 게시글 삭제
     * @param postId 삭제할 게시글 ID
     */
    public void deletePost(String postId) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            db.collection("posts").document(postId).delete().get();
        } catch (Exception e) {
            throw new RuntimeException("게시글 삭제 오류", e);
        }
    }

    /** ----------------- 댓글 CRUD ----------------- **/

    /**
     * 댓글 작성
     * @param postId 게시글 ID
     * @param commentDto 댓글 작성 DTO
     * @return 저장된 댓글(Comment)
     */
    public Comment addComment(String postId, CommentDto commentDto) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            String commentId = UUID.randomUUID().toString();

            Comment comment = Comment.builder()
                    .id(commentId)
                    .userId(commentDto.getUserId())
                    .content(commentDto.getContent())
                    .parentId(commentDto.getParentId())
                    .createdAt(Instant.now().toEpochMilli())
                    .build();

            // posts/{postId}/comments/{commentId} 경로에 저장
            db.collection("posts")
                    .document(postId)
                    .collection("comments")
                    .document(commentId)
                    .set(comment)
                    .get();

            return comment;

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("댓글 작성 중 오류 발생", e);
        }
    }

    /**
     * 댓글 목록 조회
     * @param postId 게시글 ID
     * @return 해당 게시글의 댓글 목록 (작성 시간 순 정렬)
     */
    public List<Comment> getComments(String postId) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            ApiFuture<QuerySnapshot> future = db.collection("posts")
                    .document(postId)
                    .collection("comments")
                    .get();

            List<QueryDocumentSnapshot> documents = future.get().getDocuments();
            List<Comment> comments = new ArrayList<>();
            for (DocumentSnapshot doc : documents) {
                Comment comment = doc.toObject(Comment.class);
                if (comment != null) comments.add(comment);
            }

            // 작성 시간순 정렬
            comments.sort(Comparator.comparing(Comment::getCreatedAt));
            return comments;

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("댓글 조회 중 오류 발생", e);
        }
    }

    /**
     * 댓글 삭제
     * @param postId    게시글 ID
     * @param commentId 댓글 ID
     */
    public void deleteComment(String postId, String commentId) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentReference docRef = db.collection("posts")
                    .document(postId)
                    .collection("comments")
                    .document(commentId);

            if (!docRef.get().get().exists()) {
                throw new RuntimeException("삭제할 댓글이 존재하지 않습니다: " + commentId);
            }

            docRef.delete().get();

        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("댓글 삭제 중 오류 발생", e);
        }
    }
}
