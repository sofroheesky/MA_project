        AREA RESET, CODE, READONLY

        ENTRY

main    PROC
    LDR     R0, =0x40000000     ; Source data start address
    LDR     R8, =0x4003FFFF     ; End address
    LDR     R1, =0x20000000     ; R array start address (9600 bytes)
    LDR     R2, =0x20002580     ; G array start address (R array + 9600)
    LDR     R3, =0x20004B00     ; B array start address (G array + 9600)
    LDR     R12, =0x20007080    ; Result storage address (B array + 9600)
    MOV     R4, #9600           ; Maximum pixel count
    MOV     R9, #0              ; Red counter (>= 128)
    MOV     R13, #0             ; Pixel counter

search_next_idat
    CMP     R0, R8              ; Check memory range
    BGT     store_result
    CMP     R13, R4             ; Compare maximum pixels
    BGE     store_result

    ; Search for IDAT signature
    LDRB    R5, [R0]
    CMP     R5, #'I'
    BNE     skip_byte
    LDRB    R6, [R0, #1]
    CMP     R6, #'D'
    BNE     skip_byte
    LDRB    R7, [R0, #2]
    CMP     R7, #'A'
    BNE     skip_byte
    LDRB    R14, [R0, #3]
    CMP     R14, #'T'
    BNE     skip_byte


    ; Calculate chunk length
    SUB     R10, R0, #4         ; Chunk length address
    LDRB    R5, [R10]           ; byte0
    LDRB    R6, [R10, #1]       ; byte1
    LDRB    R7, [R10, #2]       ; byte2
    LDRB    R14, [R10, #3]      ; byte3
    MOV     R11, R14, LSL #24
    ORR     R11, R11, R7, LSL #16
    ORR     R11, R11, R6, LSL #8
    ORR     R11, R11, R5

    ADD     R10, R0, #4         ; Data start address
    ADD     R11, R10, R11       ; Data end address

process_idat_pixels_loop
    CMP     R10, R11            ; Check end of chunk data
    BGE     next_idat_search
    CMP     R13, R4             ; Check maximum pixels
    BGE     store_result

    ; Read RGBA 4 bytes
    LDRB    R5, [R10], #1       ; R
    LDRB    R6, [R10], #1       ; G
    LDRB    R7, [R10], #1       ; B
    ADD     R10, R10, #1        ; Skip A

    ; Store R, G, B
    STRB    R5, [R1], #1        ; R array
    STRB    R6, [R2], #1        ; G array
    STRB    R7, [R3], #1        ; B array

    ; Check Red value
    CMP     R5, #128
    ADDGE   R9, R9, #1          ; Increment count

    ADD     R13, R13, #1        ; Increment pixel counter
    B       process_idat_pixels_loop

next_idat_search
    ADD     R0, R11, #4         ; Search next IDAT (skip 4 bytes CRC)
    B       search_next_idat

skip_byte
    ADD     R0, R0, #1          ; Move 1 byte
    B       search_next_idat

store_result
    STR     R9, [R12]           ; Store result
    BX      LR

    LTORG
    ENDP

        AREA DATA, DATA, READWRITE

R_array     SPACE   9600        ; 0x20000000 ~ 0x2000257F
G_array     SPACE   9600        ; 0x20002580 ~ 0x20004AFF
B_array     SPACE   9600        ; 0x20004B00 ~ 0x2000707F
result      SPACE   4           ; 0x20007080

        END
