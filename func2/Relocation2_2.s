        AREA    RESET, CODE, READONLY
        ENTRY
        EXPORT  SeparateRGB

SeparateRGB
        LDR     R0, =0x40000000      ; Start address of input image
        LDR     R1, =0x4003FFFF      ; End address of image
        LDR     R2, =9600            ; Total number of pixels
        MOV     R3, #0               ; Pixel counter

        LDR     R4, =0x20000000      ; R storage address
        LDR     R5, =0x20000800      ; G storage address
        LDR     R6, =0x20001000      ; B storage address

FindIDAT
        CMP     R0, R1
        BGT     EndProgram

        LDRB    R7, [R0]
        CMP     R7, #'I'
        BNE     Skip
        LDRB    R7, [R0, #1]
        CMP     R7, #'D'
        BNE     Skip
        LDRB    R7, [R0, #2]
        CMP     R7, #'A'
        BNE     Skip
        LDRB    R7, [R0, #3]
        CMP     R7, #'T'
        BNE     Skip

        ADD     R0, R0, #8           ; Skip 'IDAT' and CRC (4 bytes each)

ProcessLoop
        CMP     R3, R2
        BGE     EndProgram

        LDRB    R7, [R0]             ; Load R
        LDRB    R8, [R0, #1]         ; Load G
        LDRB    R9, [R0, #2]         ; Load B

        RSB     R7, R7, #255         ; Invert R
        RSB     R8, R8, #255         ; Invert G
        RSB     R9, R9, #255         ; Invert B

        STRB    R7, [R4], #1         ; Store R
        STRB    R8, [R5], #1         ; Store G
        STRB    R9, [R6], #1         ; Store B

        ADD     R0, R0, #4           ; Move to next pixel
        ADD     R3, R3, #1           ; Increment pixel counter
        B       ProcessLoop

Skip
        ADD     R0, R0, #1
        B       FindIDAT

EndProgram
        B       EndProgram

        END
