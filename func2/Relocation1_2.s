        AREA    RESET, CODE, READONLY
        ENTRY
        EXPORT  InterleavedRGB

InterleavedRGB
        LDR     R0, =0x40000000         ; Start address of input image
        LDR     R1, =0x4003FFFF         ; End address of image
        LDR     R2, =9600               ; Total number of pixels
        MOV     R3, #0                  ; Pixel counter

        LDR     R10, =0x20001800        ; Start address to store interleaved RGB

FindIDAT2
        CMP     R0, R1
        BGT     EndProgram

        LDRB    R7, [R0]
        CMP     R7, #'I'
        BNE     Skip2
        LDRB    R7, [R0, #1]
        CMP     R7, #'D'
        BNE     Skip2
        LDRB    R7, [R0, #2]
        CMP     R7, #'A'
        BNE     Skip2
        LDRB    R7, [R0, #3]
        CMP     R7, #'T'
        BNE     Skip2

        ADD     R0, R0, #8              ; Skip 'IDAT' + CRC (4 bytes)

ProcessLoop2
        CMP     R3, R2
        BGE     EndProgram

        LDRB    R7, [R0]                ; Load R
        LDRB    R8, [R0, #1]            ; Load G
        LDRB    R9, [R0, #2]            ; Load B

        RSB     R7, R7, #255            ; Invert R: 255 - R
        RSB     R8, R8, #255            ; Invert G: 255 - G
        RSB     R9, R9, #255            ; Invert B: 255 - B

        STRB    R7, [R10], #1           ; Store R
        STRB    R8, [R10], #1           ; Store G
        STRB    R9, [R10], #1           ; Store B

        ADD     R0, R0, #4              ; Move to next pixel (4 bytes)
        ADD     R3, R3, #1              ; Increment pixel counter
        B       ProcessLoop2

Skip2
        ADD     R0, R0, #1
        B       FindIDAT2

EndProgram
        B       EndProgram              ; Infinite loop (end of program)

        END
