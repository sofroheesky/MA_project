        AREA    RESET, CODE, READONLY
        ENTRY

main    PROC
        BL      extract_separate_rgb      ; 1단계: RGB 각각 분리 저장
        BL      calculate_from_separate   ; 2단계: 분리된 RGB로 Grayscale 계산
        BX      LR
        ENDP

extract_separate_rgb PROC
        LDR     R0, =0x40000000     ; 이미지 시작 주소
        LDR     R2, =0x40001000     ; R 채널 저장 시작
        LDR     R3, =0x40004000     ; G 채널 저장 시작
        LDR     R4, =0x40007000     ; B 채널 저장 시작
        LDR     R9, =0x4000FFFF     
        MOV     R1, #0              ; 픽셀 카운터
        LDR     R6, =9600           ; 최대 9,600픽셀

search_next_idat_step1
        CMP     R0, R9
        BGT     extract_separate_done

        ; IDAT 청크 찾기
        LDRB    R5, [R0]
        CMP     R5, #'I'
        BNE     skip_byte_step1
        LDRB    R5, [R0, #1]
        CMP     R5, #'D'
        BNE     skip_byte_step1
        LDRB    R5, [R0, #2]
        CMP     R5, #'A'
        BNE     skip_byte_step1
        LDRB    R5, [R0, #3]
        CMP     R5, #'T'
        BNE     skip_byte_step1

        ; IDAT 청크 길이 읽기
        SUB     R7, R0, #4
        LDRB    R5,  [R7]         ; lowest byte
        LDRB    R10, [R7, #1]
        LDRB    R11, [R7, #2]
        LDRB    R12, [R7, #3]     ; highest byte
        MOV     R12, R12, LSL #24
        ORR     R12, R12, R11, LSL #16
        ORR     R12, R12, R10, LSL #8
        ORR     R12, R12, R5     ; R12 = IDAT 데이터 길이

        ADD     R10, R0, #4      ; IDAT 데이터 시작 주소
        ADD     R11, R10, R12    ; IDAT 데이터 끝 주소

extract_separate_pixels
        CMP     R1, R6
        BGE     extract_separate_done
        CMP     R10, R11
        BGE     next_idat_search_step1

        ; R, G, B 각각 분리 → 저장
        LDRB    R5,  [R10, #0]       ; Red
        STRB    R5,  [R2, R1]        ; R 채널 저장

        LDRB    R7,  [R10, #1]       ; Green
        STRB    R7,  [R3, R1]        ; G 채널 저장

        LDRB    R12, [R10, #2]       ; Blue
        STRB    R12, [R4, R1]        ; B 채널 저장

        ADD     R10, R10, #4         ; 다음 RGBA 픽셀 위치
        ADD     R1,  R1,  #1
        B       extract_separate_pixels

next_idat_search_step1
        ADD     R0, R11, #4          ; CRC(4byte) 건너뛰고 다음 청크로
        B       search_next_idat_step1

skip_byte_step1
        ADD     R0, R0, #1
        B       search_next_idat_step1

extract_separate_done
        BX      LR
        ENDP


calculate_from_separate PROC
        ; 채널별 버퍼 시작 주소 로드
        LDR     R2,  =0x40001000     ; R 채널 배열 시작
        LDR     R3,  =0x40004000     ; G 채널 배열 시작
        LDR     R4,  =0x40007000     ; B 채널 배열 시작
        LDR     R8,  =0x4000A000     ; Grayscale 결과 저장 버퍼 시작

        ; 상수 3, 6을 미리 로드 (루프 내에서는 매번 로드하지 않도록)
        MOV     R9,  #3             ; 3×R
        MOV     R10, #6             ; 6×G

        LDR     R6,  =9600          ; 최대 9,600픽셀
        MOV     R1,  #0             ; 픽셀 인덱스 (0부터 시작)

process_separate_pixels
        CMP     R1, R6
        BGE     calculate_separate_done

        ; R/G/B 채널 버퍼에서 1바이트씩 읽기
        LDRB    R5,  [R2, R1]       ; R 값
        LDRB    R7,  [R3, R1]       ; G 값
        LDRB    R12, [R4, R1]       ; B 값

        MLA     R11, R7,  R10, R12   ; R11 = (R7 × R10) + R12  → 6*G + B

        MLA     R12, R5,  R9,  R11   ; R12 = (R5 × R9) + R11   → 3*R + (6*G + B)

        MOV     R11, R1, LSL #1     ; offset = R1 × 2

        ; 16-bit Grayscale 저장
        STRH    R12, [R8, R11]      ; [0x4000A000 + (R1×2)] 위치에 저장

        ADD     R1, R1, #1
        B       process_separate_pixels

calculate_separate_done
        BX      LR
        ENDP

        LTORG
        END

