        AREA    RESET, CODE, READONLY
        ENTRY

main    PROC
        LDR     R0, =0x40000000      
        LDR     R9, =0x4003FFFF      
        LDR     R8, =0x20000000      
        LDR     R12, =0x20007080     
        MOV     R1, #0               
        LDR     R6, =9600           

search_next_idat
        CMP     R0, R9              ; Check memory range
        BGT     start_counting
        CMP     R1, R6              ; maximum pixels
        BGE     start_counting

        ; Search for IDAT
        LDRB    R2, [R0], #1
        CMP     R2, #'I'
        BNE     search_next_idat
        LDRB    R2, [R0], #1
        CMP     R2, #'D'
        BNE     search_next_idat
        LDRB    R2, [R0], #1
        CMP     R2, #'A'
        BNE     search_next_idat
        LDRB    R2, [R0], #1
        CMP     R2, #'T'
        BNE     search_next_idat

        ;Read chunk length 4 bytes
        SUB     R10, R0, #8         ; 
        LDRB    R2, [R10], #1       ; byte 0 
        LDRB    R3, [R10], #1       ; byte 1
        LDRB    R4, [R10], #1       ; byte 2
        LDRB    R5, [R10], #1       ; byte 3 
        ; Convert to Little-Endian
        MOV     R11, R5, LSL #24
        ORR     R11, R11, R4, LSL #16
        ORR     R11, R11, R3, LSL #8
        ORR     R11, R11, R2

        ; Data start address is right after IDAT signature
        MOV     R10, R0
        ADD     R11, R10, R11       ; Data end address

store_rgb
        CMP     R10, R11            ; Check end of chunk data
        BGE     next_idat
        CMP     R1, R6              ; Check maximum pixels
        BGE     start_counting

        ; Process RGBA 4 bytes
        LDRB    R2, [R10], #1       ; R
        LDRB    R3, [R10], #1       ; G
        LDRB    R4, [R10], #1       ; B
        LDRB    R5, [R10], #1       ; A (not stored)

        ; Store only RGB
        STRB    R2, [R8], #1        ; Store R
        STRB    R3, [R8], #1        ; Store G
        STRB    R4, [R8], #1        ; Store B

        ADD     R1, R1, #1
        B       store_rgb

next_idat
        ; Search for next IDAT
        ADD     R0, R11, #4
        B       search_next_idat

start_counting
        ; Count Red values in stored data
        LDR     R8, =0x20000000     ; RGB storage start address
        MOV     R1, #0              ; Loop counter
        MOV     R2, #0              ; Red counter

count_loop
        CMP     R1, R6              ; Check 9600 pixels
        BGE     final_store
        LDRB    R3, [R8], #3        ; Read only R value
        CMP     R3, #128
        ADDGE   R2, R2, #1          ; Increase count
        ADD     R1, R1, #1
        B       count_loop

final_store
        STR     R2, [R12]           ; Store final result
        BX      LR                  ; Return

        LTORG
        ENDP
        END
