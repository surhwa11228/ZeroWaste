package com.chungwoo.zerowaste.board.boarddto;

import lombok.*;

/**
 * 댓글 작성 시 클라이언트로부터 전달받는 요청 데이터 DTO
 * - 실제 DB(Comment 모델)에는 없는 임시 데이터 전송 용도
 * - Controller → Service 단계에서 댓글 생성 시 사용
 */
@Getter              // Lombok: 모든 필드에 대한 Getter 메서드 자동 생성
@Setter              // Lombok: 모든 필드에 대한 Setter 메서드 자동 생성
@NoArgsConstructor   // Lombok: 파라미터 없는 기본 생성자 자동 생성
@AllArgsConstructor  // Lombok: 모든 필드를 초기화하는 생성자 자동 생성
@Builder             // Lombok: Builder 패턴 사용 가능
public class CommentDto {

    /**
     * 댓글 작성자 ID
     * - Firebase Authentication UID와 매핑됨
     * - 일반적으로 @AuthenticationPrincipal을 통해 서버에서 추출
     */
    private String uid;

    /**
     * 댓글 본문 내용
     */
    private String content;

    /**
     * 부모 댓글 ID
     * - 일반 댓글: null
     * - 대댓글(답글): 부모 댓글의 ID 값
     */
    private String parentId;
}
