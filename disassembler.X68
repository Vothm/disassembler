*-----------------------------------------------------------------
* Title      : 68K Disassembler
* Written by : Vince Maranan
* Description: CSS422 Final Project
*-----------------------------------------------------------------

; Variables
            OPT     CRE 
stack       EQU     $A000               * Stack Address
shift4bits  EQU     4                   * Shift 4 bits
shift8bits  EQU     8                   * Shift 8 bits 
shift12bits EQU     12                  * Shift 12 bits
printCount  EQU     20                  * Amount of lines to display to console at once
CR          EQU     $0D                 
LF          EQU     $0A                 


            ORG     $1000
            
start:      BSR     show        * Intro
            BSR     CLEARALL             
            LEA     stack,SP            * Load stack pointer       
            LEA     message_buffer,A2         * buffer resides in A2
            MOVEA.L A2,A6               * reference to start of good buffer
    
in_start    BSR     INPUT
            BSR     buffPrep
            MOVE.B  #1,D0
            LEA     str_more,A1
            MOVE.W  strMore_len,D1
            TRAP    #15
            MOVE.B  #2,D0
            TRAP    #15
            MOVE.B  (A1),D3     * copy input to D3
            MOVE.B  #$57,(A1)+  * write in 'W'
            MOVE.B  #$6F,(A1)   * write in 'u'
            CMP.B   #$31,D3     * compare ASCII 1 to D3
            BEQ     start
            BEQ     start
            BSR     print_exit
            JMP     end
        
;Utility functions (Printing, clearning, checking addresses)

show        MOVE.B  #13,D0
            LEA     intro,A1
            MOVE.W  intro_len,D1
            TRAP    #15
            RTS

print_exit  MOVE.B  #1,D0
            LEA     exit,A1
            MOVE.W  exit_len,D1
            TRAP    #15
            RTS        

CLEARALL    CLR     D0
            CLR     D1
            CLR     D2
            CLR     D3
            CLR     D4
            CLR     D5
            CLR     D6
            CLR     D7
            RTS
                      
clrRegs     CLR.L   D0                 
            CLR.L   D1
            CLR.L   D2
            CLR.L   D3
            CLR.L   D4
            CLR.L   D6
            CLR.L   D7
            RTS
  
EndUtil      RTS

INPUT:
            MOVE.B  #1,D0
            LEA     string1,A1
            MOVE.W  str_len1,D1         
            TRAP    #15
            ADDA.L  #str_len1,A1         
            MOVE.B  #2,D0      
            TRAP    #15
            JSR     asciiToHex           
            CMP.B   #$00,D5
            BEQ     endInput            
            MOVEA.L A0,A4         
            MOVE.B  #1,D0
            LEA     string2,A1
            MOVE.W  str_len2,D1         
            TRAP    #15         
            ADDA.L  #str_len2,A1
            MOVE.B  #2,D0
            TRAP    #15
            JSR     asciiToHex
            CMP.B   #$00,D5
            BEQ          endInput           
            MOVEA.L A4,A3               
            MOVEA.L A0,A4               
            MOVEA.L A3,A0        
                    
endInput    RTS

; Take D3 (user input) and put the converted ascii to hex on A4
asciiToHex
            MOVEM.L D0-D4,-(SP)         
            MOVE.B  #1,D5        
            JSR     clrRegs
            MOVE    #0,D6      
      
loop2       MOVE.B  (A1)+,D3            
            CMP.B   #$30,D3             
            BLT     finish      
            CMP.B   #$3A,D3             
            BLT     num_to_hex      
            CMP.B   #$41,D3             
            BLT     finish      
            CMP.B   #$47,D3             
            BLT     cap_to_hex
            CMP.B   #$61,D3             
            BLT     finish      
            CMP.B   #$67,D3             
            BLT     lower_to_hex
            CMP.B   #$66,D3             
            BGT     finish      
      
resume      ADD     #1,D6               
            CMP     #6,D6               
            BEQ     finish      
            CMP.B   #$00,(A1)          
            BEQ     finish      
            ASL.L   #4,D4                         
            JMP     loop2               

num_to_hex  SUBI.B  #$30,D3             
            ADD.B   D3,D4               
            JMP     resume              

cap_to_hex  SUBI.B  #$37,D3             
            ADD.B   D3,D4               
            JMP     resume              

lower_to_hex
            SUBI.B  #$57,D3             
            ADD.B   D3,D4               
            JMP     resume              

finish      MOVE.L  D4,A0
            CLR     D6                  
            MOVEM.L (SP)+,D0-D4             
            RTS                         
        
; Fill the message buffer with address so that the format can be: address DATA hex
FILL_ADDRESS: MOVEA.L  A2,A1              *load trap address with A2                     JSR      getLongtLong
              JSR getLong
              MOVE.B   #$09,(A2)+                                   
              RTS
         
; Print stuff in the buffer
buffPrep    MOVEA.L A6,A2         
            BSR     FILL_ADDRESS        * fill buffer with current address
            JSR     opDecode
            MOVE.B  #00,(A2)            * null terminater
            MOVE.B  #13,D0
            TRAP    #15                 * print decoded Op
                              
            CMPA.L   A0,A4              * have we reached the end of our address range?
            BLE      endBuff
            
            ADDI    #1,D7               * increment counter
            CMP     #printCount,D7
            BNE     buffPrep
            
            MOVE.B  #1,D0
            LEA     str_enter,A1
            MOVE.W  str_en_len,D1
            TRAP    #15
            
            MOVE.B  #2,D0
            TRAP    #15
            
            MOVE.B  #$50,(A1)
            
            CLR     D7                  *reset counter
            JMP     buffPrep
            
endBuff     RTS         
          
opDecode    MOVEM.L A4-A6/D0-D4/D6-D7,-(SP)      * Save registers
            JSR     clrRegs             * Clear registers for use
            MOVE.B  #1,D5        * Set good flag until fail
            MOVE.W  (A0)+,D7            * Move instruction to D7 & Increment pointer
            MOVEA.L A2,A3               * Store buffer location                 
            JSR     getOp               * Decode instruction Test



********************************************************************************************************************** 
* Start of opReturn section - clean up process and return to IO
********************************************************************************************************************** 
opReturn    MOVEM.L (SP)+,D6-D7/D0-D4/A4-A6 
            RTS              
            
                                    
getOp       MOVE.W  D7,D6               * Move instruction to shift
            MOVE.B  #shift12bits,D4         * Load shifter register
            LSR.W   D4,D6               * Shift right 12 bits
            MULU    #6,D6               * Form offset           
            LEA     tbl_op,A5           * Index into the table                                                                                   
            JSR     00(A5,D6)           * Jump indirect with index (00 indicates word movement)
            RTS



********************************************************************************************************************** 
* Beginning of the main table: tbl_op
* Contains the functions per the first 4 bits of current instruction.
********************************************************************************************************************** 
tbl_op      
            JMP     hex1_0000            
            JMP     hex1_0001            
            ;JMP     hex1_0010
            JMP     hex1_0011
            JMP     hex1_0100
            JMP     hex1_0101
            JMP     hex1_0110
            JMP     hex1_0111
            ;JMP     hex1_1000
            JMP     hex1_1001
            JMP     hex1_1010
            JMP     hex1_1011
            JMP     hex1_1100
            JMP     hex1_1101
            ;JMP     hex1_1110
            ;JMP     hex1_1111

********************************************************************************************************************** 
* Case for: first four bits = 0000
* --(ORI) 
********************************************************************************************************************** 
hex1_0000   MOVE.W  D7,D6               * Fresh copy of instruction to shift
            ANDI.W  #$0F00,D6           * Isolate second byte
            MOVE.B  #shift8bits,D4          * Load shifter
            LSR.L   D4,D6               * Shift to LSB
            CMP.B   #$0,D6              * Is this ORI?
            BEQ     opORI               * Jump to opORI section
            BNE     illegalCode             * No - bad instruction                  

opORI       MOVE.B  #'O',(A2)+          * Populate ORI into buffer
            MOVE.B  #'R',(A2)+
            MOVE.B  #'I',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+            
            MOVE.B  #'#',(A2)+            
            JSR     getAddr             * Add immediate source
            MOVE.B  #',',(A2)+          * Add comma
            JSR     getEA               * Print off desitination operand
            JMP     end0000             * Skip to end of sub: hex1_0000

end0000     RTS
********************************************************************************************************************** 
* Case for: first four bits = 0011                                   
* MOVE.B
********************************************************************************************************************** 

*hex1_0011  MOVE.B  #'M',(A2)+          * Start of MOVE.B OpCode
*            MOVE.B  #'O',(A2)+
*            MOVE.B  #'V',(A2)+
*            MOVE.B  #'E',(A2)+
*            MOVE.B  #'.',(A2)+
*            MOVE.B  #'B',(A2)+
*            MOVE.B  #' ',(A2)+
*            MOVE.B  #' ',(A2)+
*            MOVE.B  #' ',(A2)+  
*            JSR     getEA               * get source destination
*            MOVE.B  #',',(A2)+
*            JSR     swap4Move           * swap destination and source regs for getEA
*            JSR     getEA     
*end0001     RTS 
*            
            
            
            
********************************************************************************************************************** 
* Case for: first four bits = 0001                                 
* MOVE.L, MOVEA.L
********************************************************************************************************************** 
hex1_0001   MOVE.B  #'M',(A2)+          * Start of MOVE/A.L OpCodes
            MOVE.B  #'O',(A2)+
            MOVE.B  #'V',(A2)+
            MOVE.B  #'E',(A2)+
            MOVE.B  D7,D6               * copy fresh instruction to Shift
            LSR.L   #6,D6               * shift by 6 to isolate bits 6-8 in LSB
            ANDI.W  #$07,D6             * determine if MoveA?
            CMP.B   #$1,D6              * is this a MOVEA Function?
            BNE     moveL               * no then move to . portion
            MOVE.B  #'A',(A2)+
            MOVE.B  #'.',(A2)+
            MOVE.B  #'L',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JMP     moveLEA             * skip to filling out source destination
moveL       MOVE.B  #'.',(A2)+
            MOVE.B  #'L',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+  
moveLEA     JSR     getEA               * get source destination
            MOVE.B  #',',(A2)+
            JSR     swapDestReg  * swap destination and source regs for getEA
            JSR     getEA     
end0010     RTS
 
 
 
********************************************************************************************************************** 
* Case for: first four bits = 0011                                    
* MOVE.W, MOVEA.W
********************************************************************************************************************** 
hex1_0011   MOVE.B  #'M',(A2)+          * Start of MOVE/A.W OpCodes
            MOVE.B  #'O',(A2)+
            MOVE.B  #'V',(A2)+
            MOVE.B  #'E',(A2)+
            MOVE.B  D7,D6               * copy fresh instruction to Shift
            LSR.L   #6,D6               * shift by 6 to isolate bits 6-8 in LSB
            ANDI.W  #$07,D6             * determin if move A?
            CMP.B   #$1,D6              * is this a MOVEA Function?
            BNE     moveW               * no then move to . portion
            MOVE.B  #'A',(A2)+          * yes - populate A
            MOVE.B  #'.',(A2)+
            MOVE.B  #'W',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JMP     moveWEA             * skip to filling out source destination
moveW       MOVE.B  #'.',(A2)+
            MOVE.B  #'W',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+  
moveWEA     JSR     getEA               * get source destination
            MOVE.B  #',',(A2)+
            JSR     swapDestReg  * swap destination and source regs for getEA
            JSR     getEA     
end0011     RTS 



swapDestReg CLR.L   D3                  * Clear (0000) D3 to hold swap value
            MOVE.W  D7,D6               * Copy to initial shift get reg bits 9-11
            LSR.W   #shift8bits,D6          * shift by 8 (9 total)
            LSR.W   #1,D6               * shift by 1 (9 total)
            ANDI.W  #$0007,D6           * Mask/Isolate last 3 bits
            OR.W    D6,D3               * Place Reg Bits Into D3 for swap
            MOVE.W  D7,D6               * Copy to get mode bits 6-8
            LSR.W   #3,D6               * shift bits 6-8 down 3 to normal ea position 3-5
            ANDI.W  #$0038,D6           * mask bits 3-5
            OR.W    D6,D3               * add the move bits into D3
            JSR     moveSize            * add the move size bits (6-7) into D3 for ea
            MOVE.W  D3,D7               * swap register mode to determine destination from ea functions
            RTS
            
            
moveSize    MOVE.W  D7,D6               * get fresh copy to determine MOVE size
            LSR.W   #shift8bits,D6          * shift move size bits 12-13 to LSB
            LSR.W   #shift4bits,D6          
            ANDI.W  #$0003,D6           * Isolate move bits
            CMP.B   #$1,D6              * is this a byte?
            BEQ     mSizeEnd            * yes - byte size already in bits 6-7 of D3
            CMP.B   #$2,D6              * is this a L?
            BEQ     moveSizeL           * yes - Or L size to D3 bits 6-7
            CMP.B   #$3,D6              * is this a W?
            BNE     illegalCode             * No- then illegalCode        
moveSizeW   ORI.W   #$0040,D3           * add size 01 in bits 6-7 (4) into D3
            JMP     mSizeEnd            * skip to end once done
moveSizeL   ORI.W   #$0080,D3           * add size 10 in bits 6-7 (4) into D3
mSizeEnd    RTS 



********************************************************************************************************************** 
* Case for: first four bits = 0100
* --(MOVEM,LEA,NOP)
********************************************************************************************************************** 
hex1_0100   MOVE.W  D7,D6               * Fresh copy of instruction to shift
            ANDI.W  #$0100,D6           * Test isolate 8th bit for LEA
            CMP.W   #$0100,D6           * Test if LEA
            BEQ     opLEA               * Yes finish testing for LEA
            MOVE.W  D7,D6               * Copy fresh copy of instruction to shift
            MOVE.B  #shift8bits,D4          * Load 8 bit shifter
            LSR.W   D4,D6               * Shift current instruction
            ANDI.W  #$000F,D6           * Isolate last 4 bits (LSB)
            MULU    #6,D6               * Form offset for next JMP table
            LEA     tbl_0100,A5         * Load next JMP table 
            JSR     00(A5,D6)           * Jump to next instruction per next 4 bits
            JMP     end0100             * Once returned from jump table, skip to end
            
opLEA       MOVE.B  #'L',(A2)+          * Start input of LEA
            MOVE.B  #'E',(A2)+
            MOVE.B  #'A',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #$09,(A2)+ 
            JSR     getEA               * Determine address to go to buffer
            MOVE.B  #',',(A2)+          * Add comma
            MOVE.B  #'A',(A2)+          * Add A(x)
            MOVE.W  D7,D6               * Copy fresh copy of instruction to shift
            MOVE.B  #9,D4               * Load 9 bit shifter
            LSR.W   D4,D6               * Shift current instruction
            ANDI.W  #$000F,D6           * Isolate last 4 bits (LSB)
            ADD.B   #$30,D6             * convert data register # to hex digit
            MOVE.B  D6,(A2)+            * register # to buffer
end0100     RTS

hex1_0101   JSR     illegalCode             * Invalid Instruction
            RTS
            
            ***** MOVEM Command
hex1_0110   JSR     illegalCode
            ADDQ.W  #2,A0
            RTS

hex1_0111   JSR     illegalCode             * Invalid Instruction
            RTS
           


********************************************************************************************************************** 
* Case for: first four bits = 1001
* --(SUB,SUBA) - Need to look into possibilites with immediate
********************************************************************************************************************** 
hex1_1001   MOVE.B  #'S',(A2)+          * Put ADD into Buff
            MOVE.B  #'U',(A2)+
            MOVE.B  #'B',(A2)+
            JSR     getSize             * return size  in 6 & 7 into D6
            CMP.B   #%11,D6             * determine if a ADD or ADDA
            BNE     opSUB               * not size 11, then skip to ADD
            MOVE.B  #'A',(A2)+          * yep, detected 11 then ADDA
            MOVE.B  #'.',(A2)+
            MOVE.W  D7,D6               * fresh copy of instruction
            LSR.L   #shift8bits,D6          * shift to right to isolate 8th bits
            ANDI.W  #$0001,D6           * Isolate last bit for size
            CMP.B   #%1,D6              * compare for a 1 to determine
            BEQ     subaL               * jump to long, else word
            MOVE.B  #'W',(A2)+          * add word size into buffer
            JMP     opSUBA
subaL       MOVE.B  #'L',(A2)+          * add long size into buffer           
opSUBA      MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            **** NOTE NEED TO TEST FOR EA to ADD $
            JSR     getEA               * get source operand
            MOVE.B  #',',(A2)+
            MOVE.B  #'A',(A2)+  
            JSR     highRegBits         * Add register number to buffer
            JMP     end1101
            
opSUB       MOVE.B  #'.',(A2)+          * finish putting Add.x to buffer
            JSR     size2Buffer         * Determine Size and Add to Buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getDirBit           * get Direction Bit 0 = EA 1 =regs
            CMP.B   #%0,D6              * is this EA first?
            BNE     opSUB01             * no, jmp to reg mode first
            JSR     getEA               * print off effective address
            MOVE.B  #',',(A2)+          * add comma
            MOVE.B  #'D',(A2)+          * add register BAM!
            JSR     highRegBits         * Add register number to buffer
            JMP     end1001             * jump to exit of sub: hex1_1101
            
opSUB01     MOVE.B  #'D',(A2)+          * start register entry
            JSR     highRegBits         * add register number
            MOVE.B  #',',(A2)+          * add comma
            JSR     getEA               * finish with EA          
            
end1001     RTS            

hex1_1010   JSR     illegalCode             * Invalid Instruction
            RTS



********************************************************************************************************************** 
* Case for: first four bits = 1011
* --(CMP)
********************************************************************************************************************** 
hex1_1011   JSR     getSize             * return size  in 6 & 7 into D6
            CMP.B   #%11,D6             * determine if a CMPA
            BNE     opCMPEOR
            MOVE.B  #'C',(A2)+          * Put SUBA into Buff
            MOVE.B  #'M',(A2)+
            MOVE.B  #'P',(A2)+
            MOVE.B  #'A',(A2)+
            MOVE.B  #'.',(A2)+
            MOVE.W  D7,D6               * fresh copy of instruction
            LSR.L   #shift8bits,D6          * shift to right to isolate 8th bits
            ANDI.W  #$0001,D6           * Isolate last bit for size
            CMP.B   #%1,D6              * compare for a 1 to determine
            BEQ     cmpaL               * jump to long, else word
            MOVE.B  #'W',(A2)+          * add word size into buffer
            JMP     opCMPA              * Skip to adding padding and destination
cmpaL       MOVE.B  #'L',(A2)+          * add long size into buffer           
opCMPA      MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+

            JSR     getEA               * get source operand
            MOVE.B  #',',(A2)+
            MOVE.B  #'A',(A2)+
            JSR     highRegBits         * Get address register number
            JMP     end1011             * Skip to end of sub: hex1_1011
            
opCMPEOR    MOVE.W  D7,D6               * fresh value
            JSR     getDirBit           * determine the direction bit 1 = eor 0 = cmp
            CMP.B   #%0,D6              * yes, go into CMP     
                   
opCMP       MOVE.B  #'C',(A2)+          * Populate CMP
            MOVE.B  #'M',(A2)+
            MOVE.B  #'P',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         * Determine & add size to buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getEA               * Source Operand
            MOVE.B  #',',(A2)+
            MOVE.B  #'D',(A2)+  
            JSR     highRegBits         * Add register number to buffer
            JMP     end1011             * Skip to end of sub: hex1_1011
      

end1011     RTS




********************************************************************************************************************** 
* Case for: first four bits = 1100
* MULU
********************************************************************************************************************** 
hex1_1100   MOVE.W  D7,D6               * copy instruction for testing
opMULU      LSR.L   #6,D6               * shift 6 to prep for mulu testing
            ANDI.W  #$3,D6              * mask last 3 bits
            CMP.B   #$3,D6              * is this MULU or MULS?
            BEQ     muluMode            * head to mulu  mode to determine immediate  
muluMode    MOVE.W  D7,D6               * fresh copy
            LSR.L   #3,D6               * shift bits 3-5 into LSB
            ANDI.W  #$7,D6              * mask for mode bits
            CMP.B   #$7,D6              *
            BEQ     movePTR             * increment pointer by word
            JMP     illegalCode     

movePTR     ADDQ.W  #2,A0               * increment pointer
            JMP     illegalCode
        

end1100     RTS

********************************************************************************************************************** 
* Case for: first four bits = 1101
* --(ADD,ADDA)
********************************************************************************************************************** 
hex1_1101   MOVE.B  #'A',(A2)+          * Put ADD into Buff
            MOVE.B  #'D',(A2)+
            MOVE.B  #'D',(A2)+
            JSR     getSize             * return size  in 6 & 7 into D6
            CMP.B   #%11,D6             * determine if a ADD or ADDA
            BNE     opADD               * not size 11, then skip to ADD
            MOVE.B  #'A',(A2)+          * yep, detected 11 then ADDA
            MOVE.B  #'.',(A2)+
            MOVE.W  D7,D6               * fresh copy of instruction
            LSR.L   #shift8bits,D6          * shift to right to isolate 8th bits
            ANDI.W  #$0001,D6           * Isolate last bit for size
            CMP.B   #%1,D6              * compare for a 1 to determine
            BEQ     addaL               * jump to long, else word
            MOVE.B  #'W',(A2)+          * add word size into buffer
            JMP     opADDA
addaL       MOVE.B  #'L',(A2)+          * add long size into buffer           
opADDA      MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            **** NOTE NEED TO TEST FOR EA to ADD $
            JSR     getEA               * get source operand
            MOVE.B  #',',(A2)+
            MOVE.B  #'A',(A2)+  
            JSR     highRegBits         * Add register number to buffer
            JMP     end1101
            
opADD       MOVE.B  #'.',(A2)+          * finish putting Add.x to buffer
            JSR     size2Buffer         * Determine Size and Add to Buffer
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getDirBit           * get Direction Bit 0 = EA 1 =regs
            CMP.B   #%0,D6              * is this EA first?
            BNE     opADD01             * no, jmp to reg mode first
            JSR     getEA               * print off effective address
            MOVE.B  #',',(A2)+          * add comma
            MOVE.B  #'D',(A2)+          * add register BAM!
            JSR     highRegBits         * Add register number to buffer
            JMP     end1101             * jump to exit of sub: hex1_1101
            
opADD01     MOVE.B  #'D',(A2)+          * start register entry
            JSR     highRegBits         * add register number
            MOVE.B  #',',(A2)+          * add comma
            JSR     getEA               * finish with EA 

end1101     RTS



********************************************************************************************************************** 
* Beginning of 4xxx Op Codes table: tbl_0100 
* Contains the functions per the second  4 bits of current instruction.
********************************************************************************************************************** 
tbl_0100    *Jump table for all op codes that start with 4XXX
            JMP     hex4_0000            
            JMP     hex4_0001            
            ;JMP     hex4_0010
            ;JMP     hex4_0011
            ;JMP     hex4_0100
            JMP     hex4_0101
            ;JMP     hex4_0110
            JMP     hex4_0111
            JMP     hex4_1000
            JMP     hex4_1001
            JMP     hex4_1010
            JMP     hex4_1011
            JMP     hex4_1100
            JMP     hex4_1101
            JMP     hex4_1110
            JMP     hex4_1111
            
hex4_0000   JSR     illegalCode
            RTS
            
hex4_0001   JSR     illegalCode
            RTS
            
hex4_0011   JSR     illegalCode
            RTS
                          
            
hex4_0101   JSR     illegalCode
            RTS
        
            
hex4_0111   JSR     illegalCode
            RTS
            
            
********************************************************************************************************************** 
* Case for: 0100 1000 (MOVEM)                                                          
********************************************************************************************************************** 
hex4_1000   MOVE.W  D7,D6           * copy instruction
            LSR.L   #shift4bits,D6      * shift by 4 bits
            ANDI.W  #$000F,D6       * isolate last byte
            CMP.B   #$4,D6          * Determine if SWAP
            BNE     opMOVEM         * No - go to MOVEM

            RTS            

opMOVEM     JSR     illegalCode
            RTS   

hex4_1001   JSR     illegalCode
            RTS   
hex4_1010   JSR     illegalCode
            RTS   
hex4_1011   JSR     illegalCode
            RTS
hex4_1100   JSR     illegalCode
            RTS
hex4_1101   JSR     illegalCode
            RTS
hex4_1111   JSR     illegalCode
            RTS   


********************************************************************************************************************** 
* Case for: 0100 1110 (NOP)                                                      
********************************************************************************************************************** 
hex4_1110   JSR     getSize             * determine the size for (JSR,JMP)
            CMP.B   #%10,D6             * test size bits is this JSR? (0100 1110 10..)
            BNE     illegalCode             * No set badFlag for illegal instruction
             
            MOVE.B  #'N',(A2)+          * yes - print NOP to goodBuff
            MOVE.B  #'O',(A2)+
            MOVE.B  #'P',(A2)+
            RTS

            
hex2_1111   RTS    


********************************************************************************************************************** 
* Beginning of functions: illegalCode, getSize, size2Buffer, 
********************************************************************************************************************** 
getSize     MOVE.W  D7,D6               * copy current instruction to shift
            LSR.W   #6,D6               * move the size bits in 6-7 to LSB
            ANDI.W  #$0003,D6           * remove other non-size bits and store result into D6
            RTS

size2Buffer JSR     getSize             * run sizing Commands
            CMP.B   #%00,D6             * is tihs a byte?
            BEQ     mainB               * yes, add B to buffer
            CMP.B   #%01,D6             * is this a word?
            BEQ     mainW               * yes, add teh W to buffer
            CMP.B   #%10,D6             * is this a long?
            BNE     illegalCode             * No? then bad instruction
      
            MOVE.B  #'L',(A2)+          * add L to buffer
            JMP     mainEnd             * end size2Buffer sub  
            
mainB       MOVE.B  #'B',(A2)+          * add B to buffer
            JMP     mainEnd             * end size2Buffer sub
            
mainW       MOVE.B  #'W',(A2)+          * add W to buffer
mainEnd     RTS                         * end size2Buffer sub                        

highRegBits MOVE.W  D7,D6               * get fresh copy of instruction
            LSR.L   #shift8bits,D6          * shift by 8 (9total)
            LSR.L   #1,D6               * shift by 1
            ANDI.B  #$7,D6              * isolate last 7 bits for register number
            ADD.B   #$30,D6             * convert register number to ascii
            MOVE.B  D6,(A2)+            * put register numbert into buffer
            RTS

getDirBit   MOVE.W  D7,D6               * get fresh copy of instruction
            LSR.L   #shift8bits,D6          * shift to right to isolate 8th bits
            ANDI.B  #01,D6              * isolate last bit for testing & return in D6
            RTS  
            
getAddr     CMP.B   #%00,D6             * test if value is a byte - assumes D6 already loaded
            BEQ     putbytebuffer         * yes? - load B worth of address into buffer
            CMP.B   #%01,D6             * test if value is a word - assumes D6 already loaded
            BEQ     putWordBuffer         * yes? - load W worth of address into buffer
            CMP.B   #%10,D6             * test if value is a long - assumes D6 already loaded
            BEQ     putLongBuffer         * yes? - load L worth of address into buffer
            RTS

getLong     JSR     cmdSh1              * Clear D6 and load value for shift
            MOVE.B  #shift12bits,D4         * Load shifter w/12
            JSR     cmdSh2              * Shift
            MOVE.B  #shift8bits,D4          * Load shifter w/8
            JSR     cmdSh2              * Shift
            MOVE.B  #shift4bits,D4          * Load shifter w/4
            JSR     cmdSh2              * Shift
            MOVE.B  #0,D4
            JSR     cmdSh4              * Shift
            MOVE.B  #shift12bits,D4         * Load shifter w/12
            JSR     cmdSh4              * Shift
            MOVE.B  #shift8bits,D4          * Load shifter w/8
            JSR     cmdSh4              * Shift
            MOVE.B  #shift4bits,D4          * Load shifter w/4
            JSR     cmdSh4              * Shift
            MOVE.B  #0,D4               * Load shifter
            LSR.L   D4,D6               * Shift
            ANDI.L  #$0000000F,D6       * Isolate last bit
            JSR     converToHex           * Place value in D6 into buffer

cmdSh1      MOVEQ   #$0,D6              * Clear D6
            MOVE.L  A0,D6               * Load current address to print
            SWAP    D6                  * Swap high and low word
            RTS

cmdSh2      LSR.L   D4,D6               * Shift
            ANDI.L  #$0000000F,D6       * Isolate last bit
            JSR     converToHex           * Place value in D6 into buffer
            JSR     cmdSh1              * Reset D6 for next shift
            RTS

cmdSh3      MOVEQ   #$0,D6              * Clear D6
            MOVE.L  A0,D6               * Load current address to print
            RTS
            
cmdSh4      LSR.L   D4,D6               * Shift
            ANDI.L  #$0000000F,D6       * Isolate last bit
            JSR     converToHex           * Place value in D6 into buffer
            JSR     cmdSh3              * Reset D6 for next shift
            RTS
            
illegalCode     MOVE.B  #0,D5         
            MOVEA.L A3,A2               
            MOVE.B  #'D',(A2)+          
            MOVE.B  #'A',(A2)+
            MOVE.B  #'T',(A2)+
            MOVE.B  #'A',(A2)+
            MOVE.B  #$09,(A2)+
            MOVE.B  #'$',(A2)+          
            JSR     loadDataBuffer          
            RTS          

loadDataBuffer      MOVEQ   #$0,D6              
                    MOVE.W  D7,D6               
                    MOVE.B  #shift12bits,D4         
                    LSR.L   D4,D6               
                    ANDI.W  #$000F,D6           
                    JSR     converToHex           
                    MOVE.W  D7,D6
                    MOVE.B  #shift8bits,D4
                    LSR.L   D4,D6
                    ANDI.W  #$000F,D6
                    JSR     converToHex           
                    MOVE.W  D7,D6
                    MOVE.B  #shift4bits,D4
                    LSR.L   D4,D6
                    ANDI.W  #$000F,D6
                    JSR     converToHex           
                    MOVE.W  D7,D6
                    ANDI.W  #$000F,D6
                    JSR     converToHex           
                    RTS
           

; Convert hex to ascii
converToHex   CMP.B   #$A,D6             
            BGE     letter              
            ADDI.B  #$30,D6             
            BRA hexToBuffer
            
letter      ADDI.B  #$37,D6
hexToBuffer MOVE.B D6, (A2)+
            RTS
            
getEA       
            LEA         ea_mode_table,A5 
            CLR.L   D2
            CLR.L   D3
            CLR.L   D4           
            CLR.L   D6
            MOVE.W  D7,D6                 
            ANDI.W  #$003F,D6            
            MOVE.B      #3,D1                       
            LSR.W       D1,D6                       

            MULU      #6,D6                     
            JSR         00(A5,D6)               

            RTS                                
            JMP         END                    

ea_mode_table                             
            JMP     EAcode000             ; Data Register Direct (mode 0)
            JMP     EAcode001             ; Address Register Direct (mode 1)
            JMP     EAcode010             ; Address Register Diret (mode 2)
            JMP     EAcode011             ; Address Register Indirect with Post Increment (mode 3)
            JMP     EAcode100             ; Address Register Indirect with Pre Decrement (mode 4)
            JMP     EAcode101             ; Absolute Word Address (mode 7 subclass 0)
            JMP     EAcode110             ; Absolute Long Address (mode 7 subclass 1)
            JMP     EAcode111             ; Immediate Data (mode 7 subclass 4)

EAcode000
            MOVE.W      D7,D6                 
            ANDI.W      #$7,D6                 
            MOVE.B      #'D',(A2)+              
            ADD.B       #$30,D6                 
            MOVE.B      D6,(A2)+                            
            RTS
 
EAcode001
            MOVE.W      D7,D6                   
            ANDI.W      #$7,D6                  
            MOVE.B      #'A',(A2)+              
            ADD.B       #$30,D6                
            MOVE.B      D6,(A2)+                
            RTS

EAcode010
            MOVE.W      D7,D6                   
            ANDI.W      #$7,D6                  
            MOVE.B      #'(',(A2)+                       
            MOVE.B      #'A',(A2)+              
            ADD.B       #$30,D6                 
            MOVE.B      D6,(A2)+                
            MOVE.B      #')',(A2)+              
            RTS
 
EAcode011
            
            MOVE.W      D7,D6                   
            ANDI.W      #$7,D6                  
            MOVE.B      #'(',(A2)+                      
            MOVE.B      #'A',(A2)+             
            ADD.B       #$30,D6                 
            MOVE.B      D6,(A2)+                
            MOVE.B      #')',(A2)+              
            MOVE.B      #'+',(A2)+              
            RTS

EAcode100   MOVE.W      D7,D6                   
            ANDI.W      #$7,D6                  
            MOVE.B      #'-',(A2)+              
            MOVE.B      #'(',(A2)+                          
            MOVE.B      #'A',(A2)+              
            ADD.B       #$30,D6                 
            MOVE.B      D6,(A2)+                
            MOVE.B      #')',(A2)+              
            RTS                                     
            
EAcode101
             JMP    illegalCode          * set bad instruction flag
EAcode110
            JMP       illegalCode             * set bad instruction flag

EAcode111   MOVE.W D7, D6
            ANDI.W #$07, D6
            CMPI.B   #$0,D6              
            BEQ      putWordBuffer         
            CMPI.B   #$1,D6              
            BEQ      putLongBuffer         
            CMPI.B   #$2,D6
            CMPI.B   #$2,D6              
            BEQ      pctobuffer  
            RTS

 
; Add '(pc)' to buffer
pctobuffer
            JSR         putWordBuffer
            MOVE.B      #'(',(A2)+                        
            MOVE.B      #'P',(A2)+              
            MOVE.B      #'C',(A2)+              
            MOVE.B      #')',(A2)+                                     
            RTS

putbytebuffer   
            MOVE.B  #'$',(A2)+
            CLR.L   D4          
            MOVE.W  (A0),D2     
            CLR.L   D4          
            MOVE.B  #2,D4       
            
putWordBuffer 
            MOVE.B  #'$',(A2)+  
            CLR.L   D4          
            MOVE.B  #$24,(A2)+  
            MOVE.W  (A0),D2       
            CLR.L   D4          
            MOVE.B  #4,D4       
           
            MOVE.W  D7,D6                
            ADDQ.W  #2,A0         
            RTS                 

putLongBuffer
            MOVE.B  #'$',(A2)+
            CLR.L   D4          
            MOVE.L  (A0),D2     
            CLR.L   D4          
            MOVE.B  #8,D4      
            
            MOVE.W  D7,D6       
            ADDQ.W  #4,A0      
            RTS                 
                   
             ORG   $4000 ; Make sure data starts at $4000
intro        DC.B    'Hello, please enter beginning and ending addresses',CR,LF

intro_len   DC.W    intro_len-intro
        
string1     DC.B    'Enter start address: $',0
str_len1    DC.W    str_len1-string1  *Get the length of the string

string2     DC.B    'Enter end address: $',0
str_len2    DC.W    str_len2-string2  *Get the length of the string

str_enter   DC.B    'Press enter to read more data',0
str_en_len  DC.W    str_enter-str_en_len

str_more    DC.B    'Disassemble more code? 1 for yes, 0 for no. ',0
strMore_len DC.W    strMore_len-str_more       

exit        DC.B    'Closing program',0
exit_len    DC.W    exit_len-exit           

message_buffer    DC.B   1
                                 
*************************************************************************************************************************
* End of program:
*************************************************************************************************************************        
END         STOP    #$2700
            END     $1000


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
