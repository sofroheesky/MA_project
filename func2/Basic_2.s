        AREA    RESET, CODE, READONLY
        ENTRY
        EXPORT  SeparateRGBA_Pack

SeparateRGBA_Pack
        LDR     R0, =0x40000000      ; Start address of PNG image
        LDR     R1, =0x4003FFFF      ; End address of PNG image
        LDR     R2, =9600            ; Number of pixels to process
        MOV     R3, #0               ; Pixel counter

        LDR     R4, =0x20002000      ; Destination address to store inverted RGBA

FindIDAT
        CMP     R0, R1
        BGT     EndProgram

        LDRB    R5, [R0]
        CMP     R5, #'I'
        BNE     Skip
        LDRB    R5, [R0, #1]
        CMP     R5, #'D'
        BNE     Skip
        LDRB    R5, [R0, #2]
        CMP     R5, #'A'
        BNE     Skip
        LDRB    R5, [R0, #3]
        CMP     R5, #'T'
        BNE     Skip

        ADD     R0, R0, #8           ; Skip "IDAT" and CRC (4 bytes each)

ProcessLoop
        CMP     R3, R2
        BGE     EndProgram

        LDRB    R5, [R0]             ; Load R
        LDRB    R6, [R0, #1]         ; Load G
        LDRB    R7, [R0, #2]         ; Load B
        LDRB    R8, [R0, #3]         ; Load A

        RSB     R5, R5, #255         ; Invert R
        RSB     R6, R6, #255         ; Invert G
        RSB     R7, R7, #255         ; Invert B

        STRB    R5, [R4], #1         ; Store inverted R
        STRB    R6, [R4], #1         ; Store inverted G
        STRB    R7, [R4], #1         ; Store inverted B
        STRB    R8, [R4], #1         ; Store A (unchanged)

        ADD     R0, R0, #4
        ADD     R3, R3, #1
        B       ProcessLoop

Skip
        ADD     R0, R0, #1
        B       FindIDAT

EndProgram
        B       EndProgram

        END
