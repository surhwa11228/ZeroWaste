package com.chungwoo.zerowaste.board.boarddto;

import lombok.*;

/**
 * 게시판 글 작성/수정 시 클라이언트로부터 전달받는 요청 데이터 DTO
 * - 실제 DB(Post 모델)에는 없는 임시 데이터 전송 용도
 * - Controller → Service 단계에서 게시글 생성/수정 시 사용
 */
@Getter              // Lombok: 모든 필드에 대한 Getter 메서드 자동 생성
@Setter              // Lombok: 모든 필드에 대한 Setter 메서드 자동 생성
@NoArgsConstructor   // Lombok: 파라미터 없는 기본 생성자 자동 생성
@AllArgsConstructor  // Lombok: 모든 필드를 초기화하는 생성자 자동 생성
@Builder             // Lombok: Builder 패턴 사용 가능
public class BoardDto {

    /**
     * 게시글 제목
     * - 필수 입력
     */
    private String title;

    /**
     * 게시글 본문 내용
     * - 필수 입력
     */
    private String content;

    /**
     * 게시글 카테고리
     * 예: "제보", "질문", "기타"
     */
    private String category;

    /**
     * 게시글 공개 범위
     * "지역" = 작성자 지역 한정
     * "전체" = 전체 사용자 열람 가능
     */
    private String scope;
}


