;
; HTMLView
;
; HTML document viewer
;

	INCLUDE "Macros.asm"

DEBUG: equ 1

HEAP: equ 0C000H
HEAP_SIZE: equ 1580H
STACK_SIZE: equ 100H
READBUFFER_SIZE: equ 0C00H

	org 100H

RAM_PAGE0: ds 3F00H
RAM_PAGE1: ds 4000H

TPA: equ RAM_PAGE0
TPA_PAGE0: equ RAM_PAGE0
RAM_RESIDENT: equ RAM_PAGE0
TPA_PAGE1: equ RAM_PAGE1
RAM: equ RAM_PAGE1

	SECTION TPA

	DOS2Runtime Application_Main

	INCLUDE "DOS.asm"
	INCLUDE "BIOS.asm"
	INCLUDE "Class.asm"
	INCLUDE "System.asm"
	INCLUDE "Memory.asm"
	INCLUDE "Mapper.asm"
	INCLUDE "Heap.asm"
	INCLUDE "DOS2Runtime.asm"
	INCLUDE "Application.asm"
	INCLUDE "Reader.asm"
	INCLUDE "Writer.asm"
	INCLUDE "FileReader.asm"

	ENDS

	SECTION TPA_PAGE1

	INCLUDE "VDP.asm"
	INCLUDE "VDPCommand.asm"
	INCLUDE "CLI.asm"
	INCLUDE "MemoryTest.asm"
	INCLUDE "HeapTest.asm"
	INCLUDE "HTMLParser.asm"

	ENDS

	SECTION RAM_PAGE0

Heap_main:
	Heap HEAP, HEAP_SIZE

	ALIGN 100H
READBUFFER: ds READBUFFER_SIZE

	ENDS
