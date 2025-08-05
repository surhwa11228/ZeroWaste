package com.chungwoo.zerowaste.board.controller;

import com.chungwoo.zerowaste.board.model.Post;
import com.chungwoo.zerowaste.board.model.Comment;
import com.chungwoo.zerowaste.board.boarddto.BoardDto;
import com.chungwoo.zerowaste.board.boarddto.CommentDto;
import com.chungwoo.zerowaste.board.boarddto.BoardSearchResponseDto; // ✅ 새 DTO import
import com.chungwoo.zerowaste.board.service.BoardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.io.IOException;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/board")
@RequiredArgsConstructor
public class BoardController {

    private final BoardService boardService;

    // ==================== 📌 게시글 CRUD ====================

    /** 게시글 작성 */
    @PostMapping  // ✅ "/post" -> "" 로 변경 (POST /api/board)
    public ResponseEntity<?> createPost(
            @RequestPart(value = "image", required = false) MultipartFile image, // ✅ 이미지 선택적
            @RequestPart("post") BoardDto boardDto,
            @AuthenticationPrincipal String userId) throws IOException {

        // 테스트용 UID 처리
        String testUid = (userId == null) ? "testUid" : userId;

        String postId = boardService.post(image, boardDto, testUid);

        // ✅ JSON 응답으로 반환
        Map<String, Object> response = new HashMap<>();
        response.put("code", 200);
        response.put("msg", "게시글 등록 성공");
        response.put("postId", postId);

        return ResponseEntity.ok(response);
    }

    /** 게시글 목록 조회 */
    @GetMapping
    public ResponseEntity<List<BoardSearchResponseDto>> getAllPosts(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String scope) {
        return ResponseEntity.ok(boardService.getPosts(category, scope));
    }

    /** 게시글 상세 조회 */
    @GetMapping("/posts/{id}")
    public ResponseEntity<Post> getPost(@PathVariable String id) {
        Post post = boardService.getPostById(id);
        if (post == null) {
            return ResponseEntity.notFound().build(); // ✅ 404 처리
        }
        return ResponseEntity.ok(post);
    }

    /** 게시글 수정 (나중에 PUT으로 변경 권장) */
    @PutMapping("/update/{id}") // ✅ PUT으로 수정
    public ResponseEntity<Post> updatePost(
            @PathVariable String id,
            @RequestPart(value = "image", required = false) MultipartFile image,
            @RequestPart("post") BoardDto boardDto,
            @AuthenticationPrincipal String userId) {

        String testUid = (userId == null) ? "testUid" : userId;
        return ResponseEntity.ok(boardService.updatePost(id, image, boardDto, testUid));
    }

    /** 게시글 삭제 */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<String> deletePost(
            @PathVariable String id,
            @AuthenticationPrincipal String userId) {

        String testUid = (userId == null) ? "testUid" : userId;
        boardService.deletePost(id, testUid);
        return ResponseEntity.ok("게시글이 삭제되었습니다.");
    }

    // ==================== 💬 댓글/대댓글 CRUD ====================

    /** 댓글 작성 */
    @PostMapping("/{postId}/comments")
    public ResponseEntity<Comment> addComment(
            @PathVariable String postId,
            @RequestBody CommentDto commentDto,
            @AuthenticationPrincipal String userId) {

        String testUid = (userId == null) ? "testUid" : userId;
        return ResponseEntity.ok(boardService.addComment(postId, commentDto, testUid));
    }

    /** 댓글 목록 조회 */
    @GetMapping("/{postId}/comments")
    public ResponseEntity<List<Comment>> getComments(@PathVariable String postId) {
        return ResponseEntity.ok(boardService.getComments(postId));
    }

    /** 댓글 삭제 (본인만) */
    @DeleteMapping("/{postId}/comments/{commentId}")
    public ResponseEntity<String> deleteComment(
            @PathVariable String postId,
            @PathVariable String commentId,
            @AuthenticationPrincipal String userId) {

        String testUid = (userId == null) ? "testUid" : userId;
        boardService.deleteComment(postId, commentId, testUid);
        return ResponseEntity.ok("댓글이 삭제되었습니다.");
    }
}
