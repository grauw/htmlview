;
; Top-level application program class
;
Application_READBUFFER_SIZE: equ 1000H

Application: MACRO
	cli:
		CLI
	reader:
		FileReader
	htmlParser:
		HTMLParser
	size:
	ENDM

;
Application_Main:
	ld ix,Mapper_instance
	call Mapper_Construct

	ld hl,Application_MainContinue
	call System_TryCall

	ld ix,Mapper_instance
	call Mapper_Destruct

	call System_Rethrow
	ret

Application_MainContinue:
	call Application_CheckStack

	call VDP_InitMirrorsOnVDPUpgrades

	ld hl,Application_welcome
	call System_Print

	ld ix,Heap_main
	call Heap_Construct

	call MemoryTest_Test
	call HeapTest_Test

	ld ix,Application_instance
	call Application_Construct

	push ix
	ld hl,Application_EnterMainLoop
	call System_TryCall
	pop ix

	call Application_Destruct
	call System_Rethrow
	ret

; ix = this
; ix <- this
Application_Construct:
	push ix
	call Application_GetCLI
	call CLI_Construct
	pop ix
	ret

; ix = this
; ix <- this
Application_Destruct:
	push ix
	call Application_GetCLI
	call CLI_Destruct
	pop ix
	ret

; ix = this
; ix <- Command-line interface
Application_GetCLI:
	ld de,Application.cli
	add ix,de
	ret

; ix = this
; ix <- reader
Application_GetReader:
	ld de,Application.reader
	add ix,de
	ret

; ix = this
; ix <- HTML parser
Application_GetHTMLParser:
	ld de,Application.htmlParser
	add ix,de
	ret

; ix = this
Application_EnterMainLoop:
	call Application_CheckUsageInstructions
	push ix
	push ix
	push ix
	call Application_GetCLI
	call CLI_GetFileInfoBlock
	ex (sp),ix
	call Application_GetReader
	pop de
	ld hl,Application_fileReadBuffer
	ld bc,Application_READBUFFER_SIZE
	call FileReader_Construct
	ex (sp),ix
	pop iy
	call Application_GetHTMLParser
	call HTMLParser_Construct
	call HTMLParser_Parse
	pop ix
	ret

; ix = this
Application_CheckUsageInstructions:
	push ix
	call Application_GetCLI
	call CLI_GetFileInfoBlock
	ld hl,Application_usageInstructions
	call z,System_ThrowExceptionWithMessage
	pop ix
	ret

; Check if the stack is well above the heap
Application_CheckStack:
	ld hl,-(HEAP + HEAP_SIZE + STACK_SIZE)
	add hl,sp
	ld hl,Application_insufficientTPAError
	jp nc,System_ThrowExceptionWithMessage
	ret

;
	SECTION RAM

Application_instance: Application

	ALIGN 100H
Application_fileReadBuffer:
	ds Application_READBUFFER_SIZE

	ENDS

Application_welcome:
	db "HTMLView 1.0 by Grauw",13,10,10,0

Application_loadingFile:
	db "Loading ",0

Application_dotDotDot:
	db "...",13,10,0

Application_showing:
	db 13,10,"Showing...",13,10,0

Application_insufficientTPAError:
	db "Insufficient TPA space.",13,10,0

Application_usageInstructions:
	db "Usage: htmlview <image.htm>",13,10,0
