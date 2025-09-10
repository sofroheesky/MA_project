AREA    RESET, CODE, READONLY
        ENTRY
        
main    PROC
        BL      extract_rgba_data        ; 1단계: RGBA 전체 저장
        BL      calculate_grayscale_rgba ; 2단계: 복사본에서 계산
        BX      LR


; 1단계: RGBA 4바이트씩 연속 저장
extract_rgba_data PROC
        LDR     R0, =0x40000000     ; 이미지 시작 주소
        LDR     R8, =0x40002000     ; RGBA 저장 주소
        LDR     R9, =0x4000FFFF     
        MOV     R1, #0              ; 픽셀 카운터
        LDR     R6, =9600           ; 최대 9,600픽셀

search_next_idat_rgba
        CMP     R0, R9
        BGT     extract_rgba_done

        ; IDAT 청크 찾기
        LDRB    R3, [R0]
        CMP     R3, #'I'
        BNE     skip_byte_rgba
        LDRB    R3, [R0, #1]
        CMP     R3, #'D'
        BNE     skip_byte_rgba
        LDRB    R3, [R0, #2]
        CMP     R3, #'A'
        BNE     skip_byte_rgba
        LDRB    R3, [R0, #3]
        CMP     R3, #'T'
        BNE     skip_byte_rgba

        ; IDAT 청크 크기 읽기
        SUB     R7, R0, #4
        LDRB    R3, [R7]
        LDRB    R4, [R7, #1]
        LDRB    R5, [R7, #2]
        LDRB    R12, [R7, #3]
        MOV     R11, R12, LSL #24
        ORR     R11, R11, R5, LSL #16
        ORR     R11, R11, R4, LSL #8
        ORR     R11, R11, R3

        ADD     R10, R0, #4          ; IDAT 데이터 시작
        ADD     R11, R10, R11        ; IDAT 데이터 끝

extract_rgba_pixels
        CMP     R1, R6               ; 9600개 초과 여부
        BGE     extract_rgba_done

        CMP     R10, R11             ; IDAT 청크 끝
        BGE     next_idat_search_rgba

        ; RGBA 4바이트 연속 저장
        LDRB    R3, [R10, #0]
        STRB    R3, [R8], #1
        LDRB    R4, [R10, #1]
        STRB    R4, [R8], #1
        LDRB    R5, [R10, #2]
        STRB    R5, [R8], #1
        LDRB    R12, [R10, #3]
        STRB    R12, [R8], #1

        ADD     R10, R10, #4
        ADD     R1, R1, #1
        B       extract_rgba_pixels

next_idat_search_rgba
        ADD     R0, R11, #4
        B       search_next_idat_rgba

skip_byte_rgba
        ADD     R0, R0, #1
        B       search_next_idat_rgba

extract_rgba_done
        BX      LR
        ENDP


; 2단계: RGBA 데이터(0x40002000)에서 RGB만 꺼내서 Grayscale 계산
calculate_grayscale_rgba PROC
        LDR     R0, =0x40002000     ; RGBA 데이터 시작 주소
        LDR     R8, =0x40004000     ; Grayscale 결과 저장
        LDR     R6, =9600           ; 최대 9,600픽셀
        MOV     R1, #0

process_rgba_pixels
        CMP     R1, R6
        BGE     calculate_done_rgba

        LDRB    R3, [R0], #1        ; R
        LDRB    R4, [R0], #1        ; G
        LDRB    R5, [R0], #1        ; B
        ADD     R0, R0, #1          ; A는 그냥 스킵

        ; Grayscale 공식: 3*R + 6*G + B
        MOV     R7, R3
        ADD     R7, R7, R7, LSL #1  ; 3*R
        MOV     R12, R4
        ADD     R12, R12, R12, LSL #1 ; 3*G
        ADD     R12, R12, R12       ; 6*G
        ADD     R7, R7, R12
        ADD     R7, R7, R5

        STRH    R7, [R8], #2        ; 16비트로 저장

        ADD     R1, R1, #1
        B       process_rgba_pixels

calculate_done_rgba
        BX      LR
        ENDP

        LTORG
        END
