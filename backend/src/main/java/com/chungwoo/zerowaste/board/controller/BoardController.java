package com.chungwoo.zerowaste.board.controller;

import com.chungwoo.zerowaste.api.ApiResponse;
import com.chungwoo.zerowaste.auth.dto.AuthUserDetails;
import com.chungwoo.zerowaste.board.boarddto.*;
import com.chungwoo.zerowaste.board.model.Post;
import com.chungwoo.zerowaste.board.model.Comment;
import com.chungwoo.zerowaste.board.service.BoardService;
import com.google.protobuf.Api;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.util.List;

@RestController
@RequestMapping("/api/board")
@RequiredArgsConstructor
public class BoardController {

    private final BoardService boardService;

    // ==================== 📌 게시글 CRUD ====================

    /** 게시글 작성 */
    @PostMapping("/{board-name}/post")  // ✅ "/post" -> "" 로 변경 (POST /api/board)
    public ResponseEntity<ApiResponse<PostResult>> createPost(@PathVariable("board-name") String boardName,
                                                              @RequestPart(value = "images", required = false) List<MultipartFile> images,
                                                              @RequestPart("post") @Valid PostRequest postRequest,
                                                              @AuthenticationPrincipal AuthUserDetails user) {

        // 테스트용 UID 처리
        String testUid = (user.getUid() == null) ? "testUid" : user.getUid();

        PostResult postResult = boardService.post(boardName, images, postRequest, testUid);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(postResult));
    }

    /** 게시글 목록 조회 */
    @GetMapping("/{board-name}")
    public ResponseEntity<ApiResponse<List<PostResponse>>> getPosts(@PathVariable("board-name") String boardName,
                                                       @RequestParam(required = false) String category,
                                                       @RequestParam(required = false) Long startAfter) {

        List<PostResponse> response = boardService.getPosts(boardName, category, startAfter);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(response));
    }

    /** 게시글 상세 조회 */
    @GetMapping("/{board-name}/{post-id}")
    public ResponseEntity<ApiResponse<DetailedPostResponse>> getPost(@PathVariable("board-name") String boardName,
                                                                     @PathVariable("post-id") String postId) {

        DetailedPostResponse post = boardService.getPostById(boardName, postId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(post));
    }

    // 게시글 수정
    @PutMapping("/{board-name}/update/{post-id}")
    public ResponseEntity<ApiResponse<PostResult>> updatePost(@PathVariable("board-name") String boardName,
                                           @PathVariable("post-id") String postId,
                                           @RequestPart(value = "image", required = false) List<MultipartFile> images,
                                           @RequestPart("post") PostRequest postRequest,
                                           @AuthenticationPrincipal AuthUserDetails user) {

        String testUid = (user == null) ? "testUid" : user.getUid();

        PostResult postResult = boardService.updatePost(boardName, postId, images, postRequest, testUid);
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(postResult));
    }

    /** 게시글 삭제 */
    @DeleteMapping("/{board-name}/delete/{post-id}")
    public ResponseEntity<ApiResponse<Void>> deletePost(@PathVariable("board-name") String boardName,
                                                        @PathVariable("post-id") String postId,
                                                        @AuthenticationPrincipal String userId) {

        String testUid = (userId == null) ? "testUid" : userId;
        boardService.deletePost(boardName, postId, testUid);
        return ResponseEntity.status(HttpStatus.NO_CONTENT)
                .body(ApiResponse.noContent());
    }

    // ==================== 💬 댓글/대댓글 CRUD ====================

    /** 댓글 작성 */
    @PostMapping("/{board-name}/{post-id}/comment")
    public ResponseEntity<?> addComment(@PathVariable("board-name") String boardName,
                                              @PathVariable("post-id") String postId,
                                              @RequestBody CommentDto commentDto,
                                              @AuthenticationPrincipal String userId) {

        String testUid = (userId == null) ? "testUid" : userId;
        return ResponseEntity.ok(boardService.addComment(boardName, postId, commentDto, testUid));
    }

    /** 댓글 목록 조회 */
    @GetMapping("/{board-name}/{post-id}/comments")
    public ResponseEntity<List<Comment>> getComments(@PathVariable("board-name") String boardName,
                                                     @PathVariable("post-id") String postId) {
        return ResponseEntity.ok(boardService.getComments(boardName, postId));
    }

    /** 댓글 삭제 (본인만) */
    @DeleteMapping("/{board-name}/{post-id}/comment/{comment-id}")
    public ResponseEntity<ApiResponse<Void>> deleteComment(@PathVariable("board-name") String boardName,
                                                           @PathVariable("post-id") String postId,
                                                           @PathVariable("comment-id") String commentId,
                                                           @AuthenticationPrincipal String userId) {

        String testUid = (userId == null) ? "testUid" : userId;
        boardService.deleteComment(boardName, postId, commentId, testUid);
        return ResponseEntity.status(HttpStatus.NO_CONTENT)
                .body(ApiResponse.noContent());
    }
}
