;
; Command-line interface parser
;
CLI_BUFFER_SIZE: equ 255

CLI: MACRO
	fileInfoBlockReference:
		dw 0
	fileInfoBlock:
		FileInfoBlock
	_size:
	ENDM

; ix = this
; ix <- this
CLI_Construct:
	jp CLI_Parse

; ix = this
; ix <- this
CLI_Destruct: equ System_Return
;	ret

; ix = this
; ix <- file info block
CLI_GetFileInfoBlock:
	ld e,(ix + CLI.fileInfoBlockReference)
	ld d,(ix + CLI.fileInfoBlockReference + 1)
	ld ixl,e
	ld ixh,d
	ld a,e
	or d
	ret

; ix = this
CLI_Parse: PROC
	push ix
	ld ix,Heap_main
	ld bc,CLI_BUFFER_SIZE
	call Heap_Allocate
	pop ix
	push bc
	push de
	ld hl,CLI_parametersEnvName
	ld b,CLI_BUFFER_SIZE
	call DOS_GetEnvironmentItem
	ld hl,Loop
	call System_TryCall
	pop de
	pop bc
	push ix
	ld ix,Heap_main
	call Heap_Free
	pop ix
	call System_Rethrow
	ret
Loop:
	ld a,(de)
	and a
	ret z
	cp "/"
	jr z,Option
	cp " "
	jr nz,Path
	inc de
	jr Loop
Option:
	call CLI_ParseOption
	jr Loop
Path:
	call CLI_ParsePath
	jr Loop
	ENDP

; de = buffer position
; ix = this
CLI_ParseOption: PROC
	inc de
	ld a,(de)
	and 11011111B  ; upper-case
	ld hl,CLI_unknownOptionError
	call System_ThrowExceptionWithMessage
Next:
	ld a,(de)
	and a
	ret z
	cp " "
	ret z
	ld hl,CLI_unknownOptionError
	jp System_ThrowExceptionWithMessage
	ENDP

; de = buffer position
; ix = this
CLI_ParsePath: PROC
	ld a,(ix + CLI.fileInfoBlockReference)
	or (ix + CLI.fileInfoBlockReference + 1)
	ld hl,CLI_multiplePathsError
	jp nz,System_ThrowExceptionWithMessage
	push de
	call DOS_ParsePathname
	ld a,(de)
	and a
	jr z,FindFile
	ld a,0
	ld (de),a
	inc de
FindFile:
	pop hl
	push de
	ex de,hl
	push ix
	ld bc,CLI.fileInfoBlock
	add ix,bc
	ld b,0
	call DOS_FindFirstEntry
	call DOS_TerminateIfError
	ld e,ixl
	ld d,ixh
	pop ix
	ld (ix + CLI.fileInfoBlockReference),e
	ld (ix + CLI.fileInfoBlockReference + 1),d
	pop de
	ret
	ENDP

;
CLI_parametersEnvName:
	db "PARAMETERS",0

CLI_unknownOptionError:
	db "Unknown command line option.",13,10,0

CLI_multiplePathsError:
	db "Can not specify more than one file path.",13,10,0
