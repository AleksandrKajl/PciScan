;PciRecScan.asm
;Created by Alexandr Kail
;Fasm, cp1251

;��������� ���� PCI
;0-7 ������ ��������
;8-10 �������
;11-15 ����������
;16-23 ����
;24-30 ������ 0
;31 C - ���� ������� � ���������� 1 	
Start:
		MOV		AX,CS
		MOV		DS,AX
			CLI
		MOV		SS,AX
		MOV		SP,Start
			STI
		MOV		AH,1
		MOV		CX,2000H
	INT		10H								;������� ������
		MOV		AX,0B800H               	
		MOV		ES,AX						;������������� ������� �� ����� ������
		XOR		DI,DI						;��������� � �����������
;��������� ����	
	CALL	FieldMarkup
		XOR		CL,CL

;���� ������������ ���������				
ScanDevices:
;�������� ������ �� ������	I/O		
			
		MOV		EAX,[confAddr]				;��������� �����(BUS_0,DEV_0,FUN_0,_REG_0),������� ��� ��������������
		MOV		DX,0CF8H                    
		OUT		DX,EAX						;���������� ����� � ���� PCI CONFIG_ADDRESS	
		MOV		DX,0CFCH	                
		IN		EAX,DX						;������ ������� ����. ������������ PCI �� CONFIG_DATA
		CMP		AX,0FFFFH					;���� VenID = 0FFFFH, ���������� �����������.
	JE	.End								;�������� ��������� ����������
		MOV		[regVenID],EAX				;��������� ������� � ����
		
		MOV		EAX,[confAddr]				
		ADD		EAX,08H						;Class code/Subclass/ProgIF/Revision ID
		MOV		DX,0CF8H
		OUT		DX,EAX						
		MOV		DX,0CFCH
		IN		EAX,DX	
		MOV		[regClCode],EAX	
	CALL	OutputScreen
	
		SHR		EAX,16
		CMP		AX,0604H
	JNE	.End
	
		MOV		EAX,[confAddr]	
		ADD		EAX,18H							;Secondary Bus Number/Primary Bus Number ������ ����� ��������� ����
		MOV		DX,0CF8H	
		OUT		DX,EAX							
		MOV		DX,0CFCH	
		IN		EAX,DX	
		
		MOV		EBX,[confAddr]					;��������� ������� ����, ���������� � ������� 
		PUSH	EBX
			
		MOV		BYTE[confAddr+2],AH				;���������� Secondary Bus Number
		MOV		BYTE[confAddr+1],0				;�������� D:F	
	CALL	ScanDevices	
	
		POP		EBX
		MOV		[confAddr],EBX					;���������� B.D:F
		
;�������� ��������� ����������
.End:	
		CMP	 	WORD[confAddr],0FF00H			;��������� ���� ����
	JE	_End
		ADD		[confAddr],100H					;��������� ����������, ����
	JMP	ScanDevices
	
_End:
		CMP		BYTE[confAddr+3],0
	JE	@F
	RET
@@:
	JMP	$
	
OutputScreen:
		PUSH	EAX

	;������� ������ �� �����					
		MOV		BL,BYTE[confAddr+2]			;�������� ����� ����
		ADD		[addrBdf],160				;��������� ������ ������ � �����������(80 * (�� ����. + �����.))	
		MOV		DI,[addrBdf]	
		CMP		DI,0F00H					;��������� �� ������?	
	JE	NextPage							;������������� ����� �� ����� �����
.L1:
	CALL	ConvNumOfStr1					;������� ����� ����
		MOV		AL,'.'				           
		STOSW								;������� ������ ����
		MOV		BL,BYTE[confAddr+1]			   		
		SHR		BL,3						;����� ���������� ������� 5 ���
	CALL	ConvNumOfStr1
		MOV		AL,':'
		STOSW
		MOV		BL,BYTE[confAddr+1]
		AND		BL,7						;��������� ������� 5 ���; ����� ������� 	
	CALL	ConvNumOfStr1	                
		MOV		EBX,[regVenID]				;� EBX ������� ����. ������������ PCI
		ADD		[addrVen],160				;���������� �� ����� ��� ������ VenID
		MOV		DI,[addrVen]
	CALL	ConvNumOfStr2
		SHR		EBX,16
		ADD		[addrDev],160				;���������� �� ����� ��� ������ DevID
		MOV		DI,[addrDev]				
	CALL	ConvNumOfStr2		
		MOV		BX,WORD[regClCode+2]
		ADD		[addrRegPci],160			;!!!���������� �����
		MOV		DI,[addrRegPci]
	CALL	ConvNumOfStr2
		MOV		BL,BYTE[regClCode+1]
	CALL	ConvNumOfStr1
		POP		EAX
	RET
;��� ������� ������������ ���� PCI-PCI	

	
;������� ���������� ��������� ��������	
NextPage:
		MOV		SI,msg
		MOV		AH,00000111B	;����� ������ �� ר���� ����			
	CALL	LineOut				;������� ���������
		MOV		AH,10H          
	INT	16H						;���������� ������� � ���������
		XOR		EAX,EAX
		XOR		DI,DI
		MOV		CX,0FA0H
	REP	STOSD
		MOV		[addrBdf],160
		MOV		[addrVen],32
		MOV		[addrDev],64
		MOV		[addrRegPci],96
		MOV		[addrHeadType],128
		XOR		DI,DI
;��������� ����	
	CALL	FieldMarkup
		MOV		DI,160
	JMP	OutputScreen.L1

;�������� ����	
FieldMarkup:
		MOV		SI,msgBdf				;��������� ������
;�������� �� ���������
		MOV		AH,00000100B			;������� ������ �� ר���� ����		
	CALL	LineOut                       
		MOV		DI,[addrVen]			;������� VenID
		MOV		SI,msgVen               
		MOV		AH,00000100B			;������� ������ �� ר���� ����		
	CALL	LineOut				        
		MOV		DI,[addrDev]					;������� DevID
		MOV		SI,msgDev               
		MOV		AH,00000100B			;������� ������ �� ר���� ����		
	CALL	LineOut
		MOV		DI,[addrRegPci]
		MOV		SI,msgClassCode
		MOV		AH,00000100B
	CALL	LineOut
		MOV		DI,[addrHeadType]
		MOV		SI,msgHeadType	
		MOV		AH,00000100B
	CALL	LineOut
	
	RET	
		
;����������� ��� ����� � ASCII ������
;� BX ��������� HEX ��������
;� ES:DI ����� �����������
ConvNumOfStr2:		
		MOV		AH,00000100B	
		MOV		AL,BH			;������� ����
;!!!!!!!!!!!!!! ��������� ��������
	CALL	Fun1				;������� ����
		MOV		AL,BL			;������� ����
	CALL	Fun1                

	RET                         
Fun1:	                        
		PUSH	AX				;��������� AL
		SHR		AL,4			;������� ������ �����
	CALL 	CharOut				;����� �������
		POP		AX				;��������������
		AND		AL,00001111B	;������� ������ �����		
	CALL	CharOut			    

	RET                         

CharOut:						
		CMP		AL,0AH			;����� ��� �����
		JAE	L1	                
		ADD		AL,30H			;����������� � ASCII
@@:			                    
		STOSW                   
	RET                         

L1:                             
		ADD		AL,37H			;����������� � ASCII
	JMP	@b	

;����������� 1 ���� � ASCII ������
;� BL ��������� HEX ��������
;� ES:DI ����� �����������
ConvNumOfStr1:
		MOV		AH,00000100B	
		MOV		AL,BL			;��������� ����	
		PUSH	AX				;��������� AL
		SHR		AL,4			;������� ������ �����
	CALL 	.CharOut			;����� �������
		POP		AX				;��������������
		AND		AL,00001111B	;������� ������ �����
	CALL	.CharOut							
	RET                         

.CharOut:                       
		CMP		AL,0AH			;����� ��� �����
		JAE	.L1	                
		ADD		AL,30H			;����������� � ASCII
@@:			                    
		STOSW                   
	RET                         
	
.L1:                            
		ADD		AL,37H			;����������� � ASCII
	JMP	@b	
	
;������� ������ �������� ��������������� 0
;� DS:SI ������ ��������	
;� ES:DI �������� � �����������
;� AH ������� �������		
LineOut:						
		MOV		AL,[SI]
		CMP		AL,0
	JE	.End
			STOSW	
		INC		SI
	JMP	LineOut
	
.End:	
	RET	
	


;==========================������==================================
msgBdf			DB	'B.D:F',0					;����.����:���
msgVen			DB	'VenID',0
msgDev			DB	'DevID',0
msgClassCode	DB	'ClCode/SubCl',0
msgHeadType		DB	'HeaderType',0
msg				DB	"Press any button to continue...",0
;0-2 �������(3 ����),3-7 ����������(5 ���),8-15 ����(8 ���)
confAddr		DD	80000000H					;��������� �����
regClCode		DD  0	
regVenID		DD  0
regHeadType		DD	0							;���������� ��� �������� ���. PCI	
addrBdf			DW	0							;����� ������ "B.D:F"
secondaryBus	DB	0							;����� ��������� ����
addrVen			DW	32							;����� ������ VenID	
addrDev			DW	64							;����� ������ DevID		
addrRegPci		DW	96							;����� ������ ���. PCI
addrHeadType	DW	128	
					