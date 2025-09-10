        AREA RESET, CODE, READONLY
        ENTRY

main    PROC
    LDR     R0, =0x40000000     ; Source data start address
    LDR     R8, =0x4003FFFF     ; End address
    LDR     R1, =0x20000000     ; Start address of R array
    LDR     R2, =0x20002580     ; Start address of G array
    LDR     R3, =0x20004B00     ; Start address of B array
    LDR     R12, =0x20007080    ; Address to store result
    MOV     R4, #9600           ; Maximum number of pixels
    MOV     R9, #0              ; Red counter
    MOV     R13, #0             ; Pixel counter

search_next_idat
    CMP     R0, R8
    BGT     store_result
    CMP     R13, R4
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
    SUB     R10, R0, #4
    LDRB    R5, [R10]
    LDRB    R6, [R10, #1]
    LDRB    R7, [R10, #2]
    LDRB    R14, [R10, #3]
    MOV     R11, R14, LSL #24
    ORR     R11, R11, R7, LSL #16
    ORR     R11, R11, R6, LSL #8
    ORR     R11, R11, R5

    ADD     R10, R0, #4         ; Data start address
    ADD     R11, R10, R11       ; Data end address

process_idat_pixels_loop
    CMP     R10, R11
    BGE     next_idat_search
    CMP     R13, R4
    BGE     store_result

    ; Read 4 bytes (RGBA) at once
    LDR     R5, [R10], #4

    ; Extract and store R, G, B
    AND     R6, R5, #0xFF
    AND     R7, R5, #0xFF00
    MOV     R7, R7, LSR #8
    AND     R14, R5, #0xFF0000
    MOV     R14, R14, LSR #16

    STRB    R6, [R1], #1
    STRB    R7, [R2], #1
    STRB    R14, [R3], #1

    ; Count Red values
    CMP     R6, #128
    ADDGE   R9, R9, #1

    ADD     R13, R13, #1
    B       process_idat_pixels_loop

next_idat_search
    ADD     R0, R11, #4
    B       search_next_idat

skip_byte
    ADD     R0, R0, #1
    B       search_next_idat

store_result
    STR     R9, [R12]
    BX      LR

    LTORG
    ENDP

        AREA DATA, DATA, READWRITE

R_array     SPACE   9600
G_array     SPACE   9600
B_array     SPACE   9600
result      SPACE   4

        END
