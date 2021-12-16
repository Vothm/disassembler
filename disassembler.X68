*-----------------------------------------------------------------
* Title      : 68K Disassembler
* Written by : Vince Maranan
* Description: CSS422 Final Project
*-----------------------------------------------------------------

stack       EQU     $A000               * Stack Address
shift4bits  EQU     4                   * Shift 4 bits
shift8bits  EQU     8                   * Shift 8 bits 
shift12bits EQU     12                  * Shift 12 bits
printCount  EQU     20                  * Amount of lines to display to console at once
CR          EQU     $0D                 
LF          EQU     $0A                 

            ORG     $1000
            
start:      BSR     show                ; Show beginning message
            BSR     CLEARALL             
            LEA     stack,SP                ;Load stack pointer       
            LEA     message_buffer,A2       ;A2 is the message buffer
            MOVEA.L A2,A6               
    
in_start    BSR     INPUT
            BSR     buffPrep
            MOVE.B  #1,D0
            LEA     str_more,A1
            MOVE.W  strMore_len,D1
            TRAP    #15
            MOVE.B  #2,D0
            TRAP    #15
            MOVE.B  (A1),D3     
            MOVE.B  #'W',(A1)+  
            MOVE.B  #'u',(A1)  
            CMP.B   #$31,D3    
            BEQ     start
            BEQ     start
            BSR     program_done
            JMP     end
        
;Utility functions (Printing, clearning, checking addresses)

show        MOVE.B  #13,D0
            LEA     intro,A1
            MOVE.W  intro_len,D1
            TRAP    #15
            RTS

program_done  MOVE.B  #1,D0
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
                      
CLEARREGISTERS     CLR.L   D0                 
            CLR.L   D1
            CLR.L   D2
            CLR.L   D3
            CLR.L   D4
            CLR.L   D6
            CLR.L   D7
            RTS
  
EndUtil      RTS

INPUT:      ; Handle inputs
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
            JSR     CLEARREGISTERS
            MOVE    #0,D6      
      
cleanup     MOVE.B  (A1)+,D3            
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
            JMP     cleanup               

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
        
FILL_ADDRESS: MOVEA.L  A2,A1              
              JSR getLong
              MOVE.B   #$09,(A2)+                                   
              RTS
         
; Print stuff in the buffer
buffPrep    MOVEA.L A6,A2         
            BSR FILL_ADDRESS
            JSR     opDecode
            MOVE.B  #00,(A2)            
            MOVE.B  #13,D0
            TRAP    #15                 
                              
            CMPA.L   A0,A4              
            BLE      endBuff
            
            ADDI    #1,D7              
            CMP     #printCount,D7
            BNE     buffPrep
            
            MOVE.B  #1,D0
            LEA     str_enter,A1
            MOVE.W  str_en_len,D1
            TRAP    #15
            
            MOVE.B  #2,D0
            TRAP    #15
            
            MOVE.B  #$50,(A1)
            
            CLR     D7                
            JMP     buffPrep
            
endBuff     RTS         
          
opDecode    MOVEM.L A4-A6/D0-D4/D6-D7,-(SP)     
            JSR     CLEARREGISTERS            
            MOVE.B  #1,D5      
            MOVE.W  (A0)+,D7           
            MOVEA.L A2,A3                             
            JSR     getOp              

opReturn    MOVEM.L (SP)+,D6-D7/D0-D4/A4-A6 
            RTS              
            
getOp       MOVE.W  D7,D6              
            MOVE.B  #shift12bits,D4        
            LSR.W   D4,D6               
            MULU    #6,D6                          
            LEA     jmp_table,A5                                                                                            
            JSR     00(A5,D6)         
            RTS

jmp_table      
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

;0000 ORI
hex1_0000   MOVE.W  D7,D6               
            ANDI.W  #$0F00,D6           
            MOVE.B  #shift8bits,D4          
            LSR.L   D4,D6               
            CMP.B   #$0,D6              ; Check if ORI
            BEQ     opORI               ; Jump to opORI section
            BNE     illegalCode                        

opORI       MOVE.B  #'O',(A2)+         
            MOVE.B  #'R',(A2)+
            MOVE.B  #'I',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+            
            MOVE.B  #'#',(A2)+            
            JSR     getAddr             
            MOVE.B  #',',(A2)+          
            JSR     getEA              
            JMP     end0000           

end0000     RTS
            
;0001 MOVEA, MOVE
hex1_0001   MOVE.B  #'M',(A2)+          
            MOVE.B  #'O',(A2)+
            MOVE.B  #'V',(A2)+
            MOVE.B  #'E',(A2)+
            MOVE.B  D7,D6               
            LSR.L   #6,D6              
            ANDI.W  #$07,D6             
            CMP.B   #$1,D6            
            BNE     moveL              
            MOVE.B  #'A',(A2)+
            MOVE.B  #'.',(A2)+
            MOVE.B  #'L',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JMP     moveLEA            
moveL       MOVE.B  #'.',(A2)+
            MOVE.B  #'L',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+  
moveLEA     JSR     getEA           
            MOVE.B  #',',(A2)+
            JSR     swapDestReg 
            JSR     getEA     
end0010     RTS
 
 
 
; 0011 MOVE
hex1_0011   MOVE.B  #'M',(A2)+         
            MOVE.B  #'O',(A2)+
            MOVE.B  #'V',(A2)+
            MOVE.B  #'E',(A2)+
            MOVE.B  D7,D6               
            LSR.L   #6,D6               ; Get bits 6-8
            ANDI.W  #$07,D6             
            CMP.B   #$1,D6              
            BNE     moveW             
            MOVE.B  #'A',(A2)+         
            MOVE.B  #'.',(A2)+
            MOVE.B  #'W',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JMP     moveWEA            
moveW       MOVE.B  #'.',(A2)+
            MOVE.B  #'W',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+  
moveWEA     JSR     getEA            
            MOVE.B  #',',(A2)+
            JSR     swapDestReg 
            JSR     getEA     
end0011     RTS 

swapDestReg CLR.L   D3                  
            MOVE.W  D7,D6              
            LSR.W   #shift8bits,D6        
            LSR.W   #1,D6               
            ANDI.W  #$0007,D6          
            OR.W    D6,D3              
            MOVE.W  D7,D6               
            LSR.W   #3,D6              
            ANDI.W  #$0038,D6          
            OR.W    D6,D3               
            JSR     moveSize            
            MOVE.W  D3,D7             
            RTS
            
moveSize    MOVE.W  D7,D6             
            LSR.W   #shift8bits,D6       
            LSR.W   #shift4bits,D6          
            ANDI.W  #$0003,D6           
            CMP.B   #$1,D6              
            BEQ     mSizeEnd            
            CMP.B   #$2,D6             
            BEQ     moveSizeL          
            CMP.B   #$3,D6             
            BNE     illegalCode               
moveSizeW   ORI.W   #$0040,D3          
            JMP     mSizeEnd            
moveSizeL   ORI.W   #$0080,D3          
mSizeEnd    RTS 



; 0100 NOP, MOVEM, LEA
hex1_0100   MOVE.W  D7,D6               
            ANDI.W  #$0100,D6           
            CMP.W   #$0100,D6           
            BEQ     opLEA               
            MOVE.W  D7,D6              
            MOVE.B  #shift8bits,D4       
            LSR.W   D4,D6              
            ANDI.W  #$000F,D6           
            MULU    #6,D6              
            LEA     tbl_0100,A5         
            JSR     00(A5,D6)           
            JMP     end0100            
            
opLEA       MOVE.B  #'L',(A2)+         
            MOVE.B  #'E',(A2)+
            MOVE.B  #'A',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #$09,(A2)+ 
            JSR     getEA             
            MOVE.B  #',',(A2)+       
            MOVE.B  #'A',(A2)+        
            MOVE.W  D7,D6              
            MOVE.B  #9,D4              
            LSR.W   D4,D6             
            ANDI.W  #$000F,D6         
            ADD.B   #$30,D6            
            MOVE.B  D6,(A2)+            
end0100     RTS

hex1_0101   JSR     illegalCode         
            RTS
            
            ***** MOVEM Command
hex1_0110   JSR     illegalCode
            ADDQ.W  #2,A0
            RTS

hex1_0111   JSR     illegalCode       
            RTS
           


; 1001 sub
hex1_1001   MOVE.B  #'S',(A2)+         
            MOVE.B  #'U',(A2)+
            MOVE.B  #'B',(A2)+
            JSR     getSize            
            CMP.B   #%11,D6           
            BNE     opSUB              
            MOVE.B  #'A',(A2)+        
            MOVE.B  #'.',(A2)+
            MOVE.W  D7,D6              
            LSR.L   #shift8bits,D6         
            ANDI.W  #$0001,D6         
            CMP.B   #%1,D6            
            BEQ     subaL               
            MOVE.B  #'W',(A2)+        
            JMP     opSUBA
subaL       MOVE.B  #'L',(A2)+                 
opSUBA      MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+

            JSR     getEA             
            MOVE.B  #',',(A2)+
            MOVE.B  #'A',(A2)+  
            JSR     highRegBits        
            JMP     end1101
            
opSUB       MOVE.B  #'.',(A2)+        
            JSR     size2Buffer         
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getDirBit           
            CMP.B   #%0,D6            
            BNE     opSUB01            
            JSR     getEA            
            MOVE.B  #',',(A2)+        
            MOVE.B  #'D',(A2)+         
            JSR     highRegBits       
            JMP     end1001            
            
opSUB01     MOVE.B  #'D',(A2)+         
            JSR     highRegBits      
            MOVE.B  #',',(A2)+        
            JSR     getEA                    
            
end1001     RTS            

hex1_1010   JSR     illegalCode          
            RTS



;1011 CMP
hex1_1011   JSR     getSize            
            CMP.B   #%11,D6           
            BNE     opCMPEOR
            MOVE.B  #'C',(A2)+          
            MOVE.B  #'M',(A2)+
            MOVE.B  #'P',(A2)+
            MOVE.B  #'A',(A2)+
            MOVE.B  #'.',(A2)+
            MOVE.W  D7,D6               
            LSR.L   #shift8bits,D6        
            ANDI.W  #$0001,D6           
            CMP.B   #%1,D6              
            BEQ     cmpaL              
            MOVE.B  #'W',(A2)+          
            JMP     opCMPA              
cmpaL       MOVE.B  #'L',(A2)+                 
opCMPA      MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+

            JSR     getEA               
            MOVE.B  #',',(A2)+
            MOVE.B  #'A',(A2)+
            JSR     highRegBits         
            JMP     end1011             
            
opCMPEOR    MOVE.W  D7,D6              
            JSR     getDirBit           
            CMP.B   #%0,D6             
                   
opCMP       MOVE.B  #'C',(A2)+          
            MOVE.B  #'M',(A2)+
            MOVE.B  #'P',(A2)+
            MOVE.B  #'.',(A2)+
            JSR     size2Buffer         
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getEA               
            MOVE.B  #',',(A2)+
            MOVE.B  #'D',(A2)+  
            JSR     highRegBits        
            JMP     end1011             
      

end1011     RTS





hex1_1100   MOVE.W  D7,D6              
opMULU      LSR.L   #6,D6             
            ANDI.W  #$3,D6             
            CMP.B   #$3,D6             
            BEQ     muluMode           
muluMode    MOVE.W  D7,D6           
            LSR.L   #3,D6              
            ANDI.W  #$7,D6             
            CMP.B   #$7,D6             
            BEQ     movePTR           
            JMP     illegalCode     

movePTR     ADDQ.W  #2,A0           
            JMP     illegalCode
        

end1100     RTS

hex1_1101   MOVE.B  #'A',(A2)+        
            MOVE.B  #'D',(A2)+
            MOVE.B  #'D',(A2)+
            JSR     getSize            
            CMP.B   #%11,D6            
            BNE     opADD             
            MOVE.B  #'A',(A2)+          
            MOVE.B  #'.',(A2)+
            MOVE.W  D7,D6               
            LSR.L   #shift8bits,D6       
            ANDI.W  #$0001,D6          
            CMP.B   #%1,D6              
            BEQ     addaL              
            MOVE.B  #'W',(A2)+          
            JMP     opADDA
addaL       MOVE.B  #'L',(A2)+                
opADDA      MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+

            JSR     getEA              
            MOVE.B  #',',(A2)+
            MOVE.B  #'A',(A2)+  
            JSR     highRegBits       
            JMP     end1101
            
opADD       MOVE.B  #'.',(A2)+        
            JSR     size2Buffer       
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            MOVE.B  #' ',(A2)+
            JSR     getDirBit           
            CMP.B   #%0,D6             
            BNE     opADD01             
            JSR     getEA               
            MOVE.B  #',',(A2)+         
            MOVE.B  #'D',(A2)+          
            JSR     highRegBits        
            JMP     end1101             
            
opADD01     MOVE.B  #'D',(A2)+          
            JSR     highRegBits        
            MOVE.B  #',',(A2)+         
            JSR     getEA               

end1101     RTS


tbl_0100    
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
            
            
;0100 MOVEM
hex4_1000   MOVE.W  D7,D6          
            LSR.L   #shift4bits,D6     
            ANDI.W  #$000F,D6      
            CMP.B   #$4,D6         
            BNE     opMOVEM       

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


;0100 NOP
hex4_1110   JSR     getSize            
            CMP.B   #%10,D6           
            BNE     illegalCode         
             
            MOVE.B  #'N',(A2)+        
            MOVE.B  #'O',(A2)+
            MOVE.B  #'P',(A2)+
            RTS

            
hex2_1111   RTS    


getSize     MOVE.W  D7,D6            
            LSR.W   #6,D6              
            ANDI.W  #$0003,D6         
            RTS

size2Buffer JSR     getSize            
            CMP.B   #%00,D6             
            BEQ     addBToBuffer              
            CMP.B   #%01,D6            
            BEQ     addWToBuffer             
            CMP.B   #%10,D6             
            BNE     illegalCode           
      
            MOVE.B  #'L',(A2)+          
            JMP     mainEnd             
            
addBToBuffer       MOVE.B  #'B',(A2)+        
                    JMP     mainEnd             
            
addWToBuffer       MOVE.B  #'W',(A2)+      
mainEnd     RTS                                            

highRegBits MOVE.W  D7,D6               
            LSR.L   #shift8bits,D6        
            LSR.L   #1,D6              
            ANDI.B  #$7,D6            
            ADD.B   #$30,D6           
            MOVE.B  D6,(A2)+          
            RTS

getDirBit   MOVE.W  D7,D6              
            LSR.L   #shift8bits,D6        
            ANDI.B  #01,D6              
            RTS  
            
getAddr     CMP.B   #%00,D6            
            BEQ     putbytebuffer        
            CMP.B   #%01,D6            
            BEQ     putWordBuffer        
            CMP.B   #%10,D6            
            BEQ     putLongBuffer         
            RTS

getLong     JSR     cmdSh1            
            MOVE.B  #shift12bits,D4      
            JSR     cmdSh2            
            MOVE.B  #shift8bits,D4       
            JSR     cmdSh2             
            MOVE.B  #shift4bits,D4         
            JSR     cmdSh2             
            MOVE.B  #0,D4
            JSR     cmdSh4             
            MOVE.B  #shift12bits,D4        
            JSR     cmdSh4              
            MOVE.B  #shift8bits,D4         
            JSR     cmdSh4           
            MOVE.B  #shift4bits,D4        
            JSR     cmdSh4             
            MOVE.B  #0,D4              
            LSR.L   D4,D6               
            ANDI.L  #$0000000F,D6      
            JSR     converToHex           

cmdSh1      MOVEQ   #$0,D6             
            MOVE.L  A0,D6              
            SWAP    D6                 
            RTS

cmdSh2      LSR.L   D4,D6               
            ANDI.L  #$0000000F,D6      
            JSR     converToHex          
            JSR     cmdSh1             
            RTS

cmdSh3      MOVEQ   #$0,D6              
            MOVE.L  A0,D6               
            RTS
            
cmdSh4      LSR.L   D4,D6              
            ANDI.L  #$0000000F,D6       
            JSR     converToHex         
            JSR     cmdSh3             
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
