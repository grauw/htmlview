;
;
;
HTMLParser: MACRO
	nameLength:
		db 0
	nameBuffer:
		ds 256
	ENDM

; ix = this
HTMLParser_Construct:
	ret

; ix = this
HTMLParser_Destruct:
	ret

HTMLParser_FinishName:
	ld e,(ix + HTMLParser.nameLength)
	ld d,0
	push ix
	add ix,de
	ld (ix + HTMLParser.nameBuffer),0
	pop ix
	ret

HTMLParser_ClearName:
	ld (ix + HTMLParser.nameLength),0
	ret

HTMLParser_GetNameBuffer:
	ld e,ixl
	ld d,ixh
	ld hl,HTMLParser.nameBuffer
	add hl,de
	ret

; a = character
HTMLParser_AddNameCharacter:
	ld e,(ix + HTMLParser.nameLength)
	ld d,0
	inc e
	call z,System_ThrowException
	ld (ix + HTMLParser.nameLength),e
	dec e
	push ix
	add ix,de
	ld (ix + HTMLParser.nameBuffer),a
	pop ix
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
	call HTMLParser_ParseText
	ret

HTMLParser_ParseText:
	call Reader_Read_IY
	cp "<"
	jr z,HTMLParser_ParseElementStart
	call HTMLParser_EmitText
	jr HTMLParser_ParseText

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
	call HTMLParser_AddNameCharacter
	jr HTMLParser_ParseElementName

HTMLParser_ParseElementName:
	call Reader_Read_IY
	call HTMLParser_IsWhitespace
	jr z,HTMLParser_ParseElementNameSpace
	cp ">"
	jr z,HTMLParser_ParseElementNameEnd
	cp "/"
	jr z,HTMLParser_ParseElementNameEmptyClose
	call HTMLParser_AddNameCharacter
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
	call HTMLParser_AddNameCharacter
	jr HTMLParser_ParseCloseElementName

HTMLParser_ParseCloseElementName:
	call Reader_Read_IY
	call HTMLParser_IsWhitespace
	call z,System_ThrowException
	cp ">"
	jr z,HTMLParser_ParseCloseElementEnd
	cp "/"
	call z,System_ThrowException
	call HTMLParser_AddNameCharacter
	jr HTMLParser_ParseCloseElementName

HTMLParser_ParseCloseElementEnd:
	call HTMLParser_EmitCloseElement
	jr HTMLParser_ParseElementEnd

HTMLParser_ParseElementEnd:
	jp HTMLParser_ParseText

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
	call HTMLParser_AddNameCharacter
	jr HTMLParser_ParseAttributeName

HTMLParser_ParseAttributeName:
	call Reader_Read_IY
	cp "="
	jr z,HTMLParser_ParseAttributeValueStart
	cp ">"
	jr z,HTMLParser_ParseAttributeNameElementEnd
	cp "/"
	jr z,HTMLParser_ParseAttributeNameElementEmptyClose
	call HTMLParser_AddNameCharacter
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
	call HTMLParser_AddNameCharacter
	jp HTMLParser_ParseAttributeValueSpace

HTMLParser_ParseAttributeValueQuote:
	call Reader_Read_IY
	cp "\""
	jr z,HTMLParser_ParseAttributeValueEnd
	call HTMLParser_AddNameCharacter
	jr HTMLParser_ParseAttributeValueQuote

HTMLParser_ParseAttributeValueApostrophe:
	call Reader_Read_IY
	cp "\'"
	jr z,HTMLParser_ParseAttributeValueEnd
	call HTMLParser_AddNameCharacter
	jr HTMLParser_ParseAttributeValueApostrophe

HTMLParser_ParseAttributeValueSpace:
	call Reader_Read_IY
	call HTMLParser_IsWhitespace
	jr z,HTMLParser_ParseAttributeValueEnd
	call HTMLParser_AddNameCharacter
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
	jp HTMLParser_ParseText
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
	call nz,System_ThrowException
	jp HTMLParser_ParseText
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
	jp HTMLParser_ParseText
	ENDP

; a = character
HTMLParser_EmitText:
	call HTMLParser_ProcessText
	ret

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

; a = character
HTMLParser_ProcessText: PROC
	call HTMLParser_IsWhitespace
	jr z,WhiteSpace
	cp 32
	call nc,System_PrintChar
	ret
WhiteSpace:
	ld a," "
	call System_PrintChar
	ret
	ENDP

; hl = element name
HTMLParser_ProcessElement:
	ld a,"<"
	call System_PrintChar
	call System_Print
	ld a,">"
	call System_PrintChar
	ret

; hl = element name (or empty string if self-closing)
HTMLParser_ProcessCloseElement:
	ld a,"<"
	call System_PrintChar
	ld a,"/"
	call System_PrintChar
	call System_Print
	ld a,">"
	call System_PrintChar
	ret

; hl = attribute name
HTMLParser_ProcessAttributeName:
	ld a,"["
	call System_PrintChar
	call System_Print
	ld a,"]"
	call System_PrintChar
	ret

; hl = attribute value
HTMLParser_ProcessAttributeValue:
	ld a,"\""
	call System_PrintChar
	call System_Print
	ld a,"\""
	call System_PrintChar
	ret
