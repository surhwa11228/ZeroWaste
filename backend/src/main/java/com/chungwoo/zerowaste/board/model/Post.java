package com.chungwoo.zerowaste.board.model;

import lombok.*;
import java.util.Date;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Post {

    private String id;          // 게시글 ID
    private String userId;      // 작성자 ID
    private String title;       // 제목
    private String content;     // 내용
    private String category;    // 카테고리 (제보/질문/기타)
    private String scope;       // 지역 / 전체
    private String imageUrl;    // 이미지 URL
    private Date createdAt;     // 작성 시간 (Date -> Firestore Timestamp로 저장)
    private boolean pinned;     // 상단 고정 여부
}
