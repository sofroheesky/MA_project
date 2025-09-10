        AREA    RESET, CODE, READONLY
        ENTRY
        EXPORT  OptimizedSeparateRGB

OptimizedSeparateRGB
        LDR     R0, =0x40000000         ; Start address of input image
        LDR     R1, =0x4003FFFF         ; End address of image
        LDR     R2, =9600               ; Total number of pixels
        MOV     R3, #0                  ; Pixel counter

        LDR     R4, =0x20000000         ; R storage address
        LDR     R5, =0x20000800         ; G storage address
        LDR     R6, =0x20001000         ; B storage address

FindIDAT
        CMP     R0, R1
        BGT     EndProgram

        LDRB    R7, [R0]
        CMP     R7, #'I'
        BNE     SkipByte
        LDRB    R7, [R0, #1]
        CMP     R7, #'D'
        BNE     SkipByte
        LDRB    R7, [R0, #2]
        CMP     R7, #'A'
        BNE     SkipByte
        LDRB    R7, [R0, #3]
        CMP     R7, #'T'
        BNE     SkipByte

        ADD     R0, R0, #8              ; Skip 'IDAT' and CRC (4 bytes each)

ProcessLoop
        CMP     R3, R2
        BGE     EndProgram

        ; R channel
        LDRB    R7, [R0]
        RSB     R8, R7, #255
        STRB    R8, [R4], #1

        ; G channel
        LDRB    R7, [R0, #1]
        RSB     R8, R7, #255
        STRB    R8, [R5], #1

        ; B channel
        LDRB    R7, [R0, #2]
        RSB     R8, R7, #255
        STRB    R8, [R6], #1

        ADD     R0, R0, #4              ; Move to next pixel
        ADD     R3, R3, #1              ; Increment pixel counter
        B       ProcessLoop

SkipByte
        ADD     R0, R0, #1
        B       FindIDAT

EndProgram
        B       EndProgram

        END
