;
;
;
HTMLParser_NAMEBUFFER_SIZE: equ 1000H

HTMLParser: MACRO
	nameWriter:
		Writer
	swallowWhiteSpace:
		db 1
	displayNone:
		db 0
	ENDM

; ix = this
HTMLParser_Construct:
	ld hl,HTMLParser_nameBuffer
	ld bc,HTMLParser_NAMEBUFFER_SIZE
	ld de,System_ThrowException
	call Writer_Construct
	ret

; ix = this
HTMLParser_Destruct:
	ret

HTMLParser_FinishName:
	ld a,0
	jp Writer_Write

HTMLParser_ClearName:
	ld a,(ix + HTMLParser.nameWriter + Writer.bufferStart)
	ld (ix + HTMLParser.nameWriter + Writer.bufferPosition),a
	ld a,(ix + HTMLParser.nameWriter + Writer.bufferStart + 1)
	ld (ix + HTMLParser.nameWriter + Writer.bufferPosition + 1),a
	ret

HTMLParser_GetNameBuffer:
	ld l,(ix + HTMLParser.nameWriter + Writer.bufferStart)
	ld h,(ix + HTMLParser.nameWriter + Writer.bufferStart + 1)
	ret

; a = character
; f <- z: yes
HTMLParser_IsWhitespace:
	cp 9
	ret z
	cp 10
	ret z
	cp 11
	ret z
	cp 12
	ret z
	cp 13
	ret z
	cp 32
	ret

; ix = this
; iy = reader
HTMLParser_Parse:
	jr HTMLParser_ParseTextStart

HTMLParser_ParseTextStart:
	call Reader_Read_IY
	cp "<"
	jr z,HTMLParser_ParseElementStart
	call Writer_Write
	jr HTMLParser_ParseText

HTMLParser_ParseText:
	call Reader_Read_IY
	cp "<"
	jr z,HTMLParser_ParseTextEnd
	call Writer_Write
	jr HTMLParser_ParseText

HTMLParser_ParseTextEnd:
	call HTMLParser_EmitText
	jr HTMLParser_ParseElementStart

HTMLParser_ParseElementStart:
	call Reader_Read_IY
	call HTMLParser_IsWhitespace
	call z,System_ThrowException
	cp ">"
	call z,System_ThrowException
	cp "/"
	jr z,HTMLParser_ParseCloseElementStart
	cp "!"
	jp z,HTMLParser_ParseCommentStart
	call Writer_Write
	jr HTMLParser_ParseElementName

HTMLParser_ParseElementName:
	call Reader_Read_IY
	call HTMLParser_IsWhitespace
	jr z,HTMLParser_ParseElementNameSpace
	cp ">"
	jr z,HTMLParser_ParseElementNameEnd
	cp "/"
	jr z,HTMLParser_ParseElementNameEmptyClose
	call Writer_Write
	jr HTMLParser_ParseElementName

HTMLParser_ParseElementNameSpace:
	call HTMLParser_EmitElement
	jr HTMLParser_ParseAttributeNameStart

HTMLParser_ParseElementNameEnd:
	call HTMLParser_EmitElement
	jr HTMLParser_ParseElementEnd

HTMLParser_ParseElementNameEmptyClose:
	call HTMLParser_EmitElement
	jr HTMLParser_ParseElementEmptyClose

HTMLParser_ParseElementEmptyClose:
	call Reader_Read_IY
	cp ">"
	call nz,System_ThrowException
	call HTMLParser_EmitCloseElement
	jr HTMLParser_ParseElementEnd

HTMLParser_ParseCloseElementStart:
	call Reader_Read_IY
	call HTMLParser_IsWhitespace
	call z,System_ThrowException
	cp ">"
	call z,System_ThrowException
	cp "/"
	call z,System_ThrowException
	call Writer_Write
	jr HTMLParser_ParseCloseElementName

HTMLParser_ParseCloseElementName:
	call Reader_Read_IY
	call HTMLParser_IsWhitespace
	call z,System_ThrowException
	cp ">"
	jr z,HTMLParser_ParseCloseElementEnd
	cp "/"
	call z,System_ThrowException
	call Writer_Write
	jr HTMLParser_ParseCloseElementName

HTMLParser_ParseCloseElementEnd:
	call HTMLParser_EmitCloseElement
	jr HTMLParser_ParseElementEnd

HTMLParser_ParseElementEnd:
	jp HTMLParser_ParseTextStart

HTMLParser_ParseAttributeNameStart:
	call Reader_Read_IY
	call HTMLParser_IsWhitespace
	jr z,HTMLParser_ParseAttributeNameStart
	cp "="
	call z,System_ThrowException
	cp ">"
	jr z,HTMLParser_ParseElementEnd
	cp "/"
	jr z,HTMLParser_ParseElementEmptyClose
	call Writer_Write
	jr HTMLParser_ParseAttributeName

HTMLParser_ParseAttributeName:
	call Reader_Read_IY
	cp "="
	jr z,HTMLParser_ParseAttributeValueStart
	cp ">"
	jr z,HTMLParser_ParseAttributeNameElementEnd
	cp "/"
	jr z,HTMLParser_ParseAttributeNameElementEmptyClose
	call Writer_Write
	jr HTMLParser_ParseAttributeName

HTMLParser_ParseAttributeNameElementEnd:
	call HTMLParser_EmitAttributeName
	jr HTMLParser_ParseElementEnd

HTMLParser_ParseAttributeNameElementEmptyClose:
	call HTMLParser_EmitAttributeName
	jr HTMLParser_ParseElementEmptyClose

HTMLParser_ParseAttributeValueStart:
	call HTMLParser_EmitAttributeName
	call Reader_Read_IY
	cp "\""
	jp z,HTMLParser_ParseAttributeValueQuote
	cp "'"
	jp z,HTMLParser_ParseAttributeValueApostrophe
	call HTMLParser_IsWhitespace
	call z,System_ThrowException
	call Writer_Write
	jp HTMLParser_ParseAttributeValueSpace

HTMLParser_ParseAttributeValueQuote:
	call Reader_Read_IY
	cp "\""
	jr z,HTMLParser_ParseAttributeValueEnd
	call Writer_Write
	jr HTMLParser_ParseAttributeValueQuote

HTMLParser_ParseAttributeValueApostrophe:
	call Reader_Read_IY
	cp "\'"
	jr z,HTMLParser_ParseAttributeValueEnd
	call Writer_Write
	jr HTMLParser_ParseAttributeValueApostrophe

HTMLParser_ParseAttributeValueSpace:
	call Reader_Read_IY
	call HTMLParser_IsWhitespace
	jr z,HTMLParser_ParseAttributeValueEnd
	call Writer_Write
	jr HTMLParser_ParseAttributeValueSpace

HTMLParser_ParseAttributeValueEnd:
	call HTMLParser_EmitAttributeValue
	jp HTMLParser_ParseAttributeNameStart

HTMLParser_ParseCommentStart: PROC
	call Reader_Read_IY
	cp "["
	jr z,HTMLParser_ParseCDATAStart
	cp "D"
	jr z,HTMLParser_ParseDOCTYPEStart
	cp "-"
	call nz,System_ThrowException
	call Reader_Read_IY
	cp "-"
	call nz,System_ThrowException
Loop:
	call Reader_Read_IY
	cp "-"
	jr nz,Loop
	call Reader_Read_IY
	cp "-"
	jr nz,Loop
	call Reader_Read_IY
	cp ">"
	call nz,System_ThrowException
	jp HTMLParser_ParseTextStart
	ENDP

HTMLParser_ParseCDATAStart: PROC
	call Reader_Read_IY
	cp "C"
	call nz,System_ThrowException
	call Reader_Read_IY
	cp "D"
	call nz,System_ThrowException
	call Reader_Read_IY
	cp "A"
	call nz,System_ThrowException
	call Reader_Read_IY
	cp "T"
	call nz,System_ThrowException
	call Reader_Read_IY
	cp "A"
	call nz,System_ThrowException
	call Reader_Read_IY
	cp "["
	call nz,System_ThrowException
Loop:
	call Reader_Read_IY
	cp "]"
	jr nz,Loop
	call Reader_Read_IY
	cp "]"
	jr nz,Loop
	call Reader_Read_IY
	cp ">"
	jr nz,Loop
	jp HTMLParser_ParseTextStart
	ENDP

HTMLParser_ParseDOCTYPEStart: PROC
	call Reader_Read_IY
	and 11011111B  ; upper-case
	cp "O"
	call nz,System_ThrowException
	call Reader_Read_IY
	and 11011111B  ; upper-case
	cp "C"
	call nz,System_ThrowException
	call Reader_Read_IY
	and 11011111B  ; upper-case
	cp "T"
	call nz,System_ThrowException
	call Reader_Read_IY
	and 11011111B  ; upper-case
	cp "Y"
	call nz,System_ThrowException
	call Reader_Read_IY
	and 11011111B  ; upper-case
	cp "P"
	call nz,System_ThrowException
	call Reader_Read_IY
	and 11011111B  ; upper-case
	cp "E"
	call nz,System_ThrowException
Loop:
	call Reader_Read_IY
	cp ">"
	jr nz,Loop
	jp HTMLParser_ParseTextStart
	ENDP

HTMLParser_EmitText:
	call HTMLParser_FinishName
	call HTMLParser_GetNameBuffer
	call HTMLParser_ProcessText
	jp HTMLParser_ClearName

HTMLParser_EmitElement:
	call HTMLParser_FinishName
	call HTMLParser_GetNameBuffer
	call HTMLParser_ProcessElement
	jp HTMLParser_ClearName

HTMLParser_EmitCloseElement:
	call HTMLParser_FinishName
	call HTMLParser_GetNameBuffer
	call HTMLParser_ProcessCloseElement
	jp HTMLParser_ClearName

HTMLParser_EmitAttributeName:
	call HTMLParser_FinishName
	call HTMLParser_GetNameBuffer
	call HTMLParser_ProcessAttributeName
	jp HTMLParser_ClearName

HTMLParser_EmitAttributeValue:
	call HTMLParser_FinishName
	call HTMLParser_GetNameBuffer
	call HTMLParser_ProcessAttributeValue
	jp HTMLParser_ClearName

; hl = text
HTMLParser_ProcessText: PROC
	bit 0,(ix + HTMLParser.displayNone)
	ret nz
Loop:
	ld a,(hl)
	and a
	ret z
	inc hl
	call HTMLParser_IsWhitespace
	jr z,WhiteSpace
	call System_PrintChar
	ld (ix + HTMLParser.swallowWhiteSpace),0
	jr Loop
WhiteSpace:
	bit 0,(ix + HTMLParser.swallowWhiteSpace)
	jr nz,Loop
	ld (ix + HTMLParser.swallowWhiteSpace),1
	ld a," "
	call System_PrintChar
	jr Loop
	ENDP

; hl = element name
HTMLParser_ProcessElement: PROC
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "P"
	jr z,StartP
	cp "H"
	jr z,StartH
	cp "U"
	jr z,StartU
	cp "O"
	jp z,StartO
	cp "L"
	jp z,StartL
	cp "S"
	jp z,StartS
	ret

StartH:
	ld a,(hl)
	inc hl
	cp "1"
	jr z,StartHn
	cp "2"
	jr z,StartHn
	cp "3"
	jr z,StartHn
	cp "4"
	jr z,StartHn
	cp "5"
	jr z,StartHn
	cp "6"
	jr z,StartHn
	and 11011111B  ; upper-case
	cp "E"
	jr z,StartHE
	ret

StartHn:
	ld b,a
	ld a,(hl)
	and a
	ret nz
	ld a,b
	sub "0"
	ld b,a
	call System_PrintCrLf
	call System_PrintCrLf
StartH1Loop:
	ld a,"#"
	call System_PrintChar
	djnz StartH1Loop
	ld a," "
	call System_PrintChar
	ld (ix + HTMLParser.swallowWhiteSpace),1
	ret

StartHE:
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "A"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "D"
	ret nz
	ld a,(hl)
	and a
	ret nz
	ld (ix + HTMLParser.displayNone),3
	ret

StartP:
	ld a,(hl)
	and a
	ret nz
	call System_PrintCrLf
	call System_PrintCrLf
	ld (ix + HTMLParser.swallowWhiteSpace),1
	ret

StartU:
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "L"
	ret nz
	ld a,(hl)
	and a
	ret nz
	call System_PrintCrLf
	ld (ix + HTMLParser.swallowWhiteSpace),1
	ret

StartO:
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "L"
	ret nz
	ld a,(hl)
	and a
	ret nz
	call System_PrintCrLf
	ld (ix + HTMLParser.swallowWhiteSpace),1
	ret

StartL:
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "I"
	ret nz
	ld a,(hl)
	and a
	ret nz
	call System_PrintCrLf
	ld a,"o"
	call System_PrintChar
	ld a," "
	call System_PrintChar
	ld (ix + HTMLParser.swallowWhiteSpace),1
	ret

StartS:
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "C"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "R"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "I"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "P"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "T"
	ret nz
	ld a,(hl)
	and a
	ret nz
	set 0,(ix + HTMLParser.displayNone)
	ret

Debug:
	ld a,"<"
	call System_PrintChar
	call System_Print
	ld a,">"
	call System_PrintChar
	ret
	ENDP

; hl = element name (or empty string if self-closing)
HTMLParser_ProcessCloseElement: PROC
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "S"
	jr z,StartS
	cp "H"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "E"
	jr z,StartHE
	cp "T"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "M"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "L"
	ret nz
	ld a,(hl)
	and a
	ret nz
	call System_PrintCrLf
	call System_Unwind
	ret

StartHE:
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "A"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "D"
	ret nz
	ld a,(hl)
	and a
	ret nz
	ld (ix + HTMLParser.displayNone),0
	ret

StartS:
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "C"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "R"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "I"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "P"
	ret nz
	ld a,(hl)
	inc hl
	and 11011111B  ; upper-case
	cp "T"
	ret nz
	ld a,(hl)
	and a
	ret nz
	bit 1,(ix + HTMLParser.displayNone)
	ret nz
	res 0,(ix + HTMLParser.displayNone)
	ret

Debug:
	ld a,"<"
	call System_PrintChar
	ld a,"/"
	call System_PrintChar
	call System_Print
	ld a,">"
	call System_PrintChar
	ret
	ENDP

; hl = attribute name
HTMLParser_ProcessAttributeName:
	ret
	ld a,"["
	call System_PrintChar
	call System_Print
	ld a,"]"
	call System_PrintChar
	ret

; hl = attribute value
HTMLParser_ProcessAttributeValue:
	ret
	ld a,"\""
	call System_PrintChar
	call System_Print
	ld a,"\""
	call System_PrintChar
	ret

	SECTION RAM

	ALIGN 100H
HTMLParser_nameBuffer:
	ds HTMLParser_NAMEBUFFER_SIZE

	ENDS
