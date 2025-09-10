        AREA    RESET, CODE, READONLY
        ENTRY

main    PROC
        LDR     R0, =0x40000000      ; Source data start address
        LDR     R9, =0x4003FFFF      ; End address of ROM2
        LDR     R8, =0x20000000      ; RGBA storage start address
        LDR     R12, =0x20009600     ; Address to store result count
        MOV     R1, #0               ; Pixel counter
        LDR     R6, =9600            ; Maximum number of pixels

search_next_idat
        CMP     R0, R9              
        BGT     start_counting
        CMP     R1, R6              
        BGE     start_counting

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

        ; 'IDAT' signature
        SUB     R10, R0, #8         
        LDRB    R2, [R10], #1       
        LDRB    R3, [R10], #1       
        LDRB    R4, [R10], #1       
        LDRB    R5, [R10], #1      
        MOV     R11, R5, LSL #24
        ORR     R11, R11, R4, LSL #16
        ORR     R11, R11, R3, LSL #8
        ORR     R11, R11, R2
        MOV     R10, R0
        ADD     R11, R10, R11       ; End address of data

store_rgba
        CMP     R10, R11           
        BGE     next_idat
        CMP     R1, R6             
        BGE     start_counting

        LDRB    R2, [R10], #1       ; R
        LDRB    R3, [R10], #1       ; G
        LDRB    R4, [R10], #1       ; B
        LDRB    R5, [R10], #1       ; A
        ORR     R2, R2, R3, LSL #8
        ORR     R2, R2, R4, LSL #16
        ORR     R2, R2, R5, LSL #24
        STR     R2, [R8], #4
        ADD     R1, R1, #1
        B       store_rgba

next_idat
        ADD     R0, R11, #4
        B       search_next_idat

start_counting
        LDR     R8, =0x20000000    
        MOV     R1, #0             
        MOV     R2, #0              

count_loop
        CMP     R1, R6             
        BGE     final_store
        LDRB    R3, [R8], #4        
        CMP     R3, #128
        ADDGE   R2, R2, #1          
        ADD     R1, R1, #1
        B       count_loop

final_store
        STR     R2, [R12]           ; Store final result
        BX      LR                  ; Return

        LTORG
        ENDP
        END
