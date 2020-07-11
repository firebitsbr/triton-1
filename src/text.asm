;-----------------------------------------------
; Decompresses a specific text sentence from a text bank
; input:
; - de: target destination of decompression
; - c: bank #
; - a: text # within the bank
; output:
; - de: pointer to copy the decompressed text to
get_text_from_bank_reusing_bank:
	ld hl,last_decompressed_text_bank
	push af
		ld a,c
		cp (hl)
		jr z,get_text_from_bank_reusing_bank_reuse
	pop af
	jr get_text_from_bank_entry_point1

get_text_from_bank_reusing_bank_reuse:
	pop af
	push de
		jr get_text_from_bank_entry_point2


get_text_from_bank:
	; save the bank we are decompressing:
	ld hl,last_decompressed_text_bank
get_text_from_bank_entry_point1:	
	ld (hl),c

	ld hl,textBankPointers
	ld b,0
	add hl,bc
	add hl,bc
	push de
		ld e,(hl)
		inc hl
		ld d,(hl)
		ex de,hl	; hl has the pointer of the text bank
		push af
			ld de,buffer5
			; call unpack_compressed
			call pletter_unpack
		pop af
get_text_from_bank_entry_point2:
		ld hl,buffer5
get_text_from_bank_loop:
		or a
		jr z,get_text_from_bank_found
		ld b,0
		ld c,(hl)
		inc hl
		add hl,bc
		dec a
		jr get_text_from_bank_loop
get_text_from_bank_found:
	pop de
	; copy the desired string to "de":
	ld b,0
	ld c,(hl)
    inc bc
	ldir
	ret


; ------------------------------------------------
; input:
; - a,c: text ID
; - de: address to render
; - iyl: color
; - b: expected length in bytes
draw_text_from_bank_16:
	ld b,16*8
draw_text_from_bank:
	push bc
    push de
    push iy
        ld de,text_buffer
        call get_text_from_bank
draw_text_from_bank_entry_point:
        call clear_text_rendering_buffer
    pop iy
    pop de
    pop bc
    ld hl,text_buffer
    ld c,b
    ld b,0
    jp draw_sentence


; ------------------------------------------------
; same as "draw_text_from_bank", but checks if we already have the text bank we want
; decompressed, to prevent decompressing again.
draw_text_from_bank_reusing:
	push bc
    push de
    push iy
        ld de,text_buffer
        call get_text_from_bank_reusing_bank
        jr draw_text_from_bank_entry_point


; ------------------------------------------------
draw_text_from_bank_slow:
	push bc
    push de
    push iy
        ld de,text_buffer
        call get_text_from_bank
        call clear_text_rendering_buffer
    pop iy
    pop de
    pop bc
    ld hl,text_buffer
    ld c,b
    ld b,0
    jp draw_sentence_slow


; ------------------------------------------------
clear_text_rendering_buffer:
    ld hl,text_draw_buffer
    ld de,text_draw_buffer+1
    xor a
    ld (hl),a
    ld bc,32*8-1
    ldir
    ret


; ------------------------------------------------
; - de: VRAM address where to start drawing
; - a: attribute (color)
; - bc: expected length in bytes
render_text_draw_buffer:
	ld hl,text_draw_buffer
	push af
	push bc
		push de
			call fast_LDIRVM
		pop hl
		ld bc,CLRTBL2-CHRTBL2
		add hl,bc
	pop bc
	pop af
	jp fast_FILVRM


; ------------------------------------------------
; - de: VRAM address where to start drawing
; - a: attribute (color)
; - bc: expected length in bytes
render_text_draw_buffer_slow:
	; copy color attribute first:
	push de
	push bc
		ex de,hl
		ld de,CLRTBL2-CHRTBL2
		add hl,de
		call fast_FILVRM
	pop bc
	pop de

	ld hl,text_draw_buffer

	; we divide the # of bytes by 8:
    srl b
    rr c
    srl b
    rr c
    srl b
    rr c
    ld a,c
    push af
    	ld bc,8
		call fast_LDIRVM
	pop af
	dec a
	ret z
render_text_draw_buffer_slow_loop:	
	push af
		ld a,(text_skip)
		or a
		jr nz,render_text_draw_buffer_slow_loop_skip
		halt
		halt
render_text_draw_buffer_slow_loop_skip:
		push hl
	    	call update_keyboard_buffers
	    pop hl
		; wait a few seconds and skip to the menu:
	    ld a,(keyboard_line_clicks)
	    bit 0,a
	    jp z,render_text_draw_buffer_slow_loop_no_skip
	    ld a,1
	    ld (text_skip),a
render_text_draw_buffer_slow_loop_no_skip:
		ld bc,8
		call copy_to_VDP
	pop af
	dec a
	jr nz,render_text_draw_buffer_slow_loop
	ret


; ------------------------------------------------
; Calculates the maximum length that can be rendered without overflowing a single line of text.
; Only "spaces" are considered as possible splits
; input:
; - hl: sentence
; output:
; - a: number of characters that can be drawn
;max_length_of_sentence_in_one_line:
;    ld ixl,0    ; best found so far
;    ld ixh,0    ; current character
;    ld b,(hl)   ; get the sentence length
;    inc hl
;    xor a    ; pixels drawn
;max_length_of_sentence_in_one_line_loop:
;    ld d,0
;    ld e,(hl)
;    ex af,af'
;        ld a,e
;        or a    ; is it a space?
;        jr nz,max_length_of_sentence_in_one_line_no_space
;        ld a,ixh
;        inc a   ; we increase it in one to skip the space
;        ld ixl,a
;max_length_of_sentence_in_one_line_no_space:
;    ex af,af'
;    push hl
;        ld hl,font
;        add hl,de
;        add hl,de
;        add hl,de   ; index of the letter is a*3
;        add a,(hl)   ; letter width in pixels
;    pop hl
;    inc hl  
;    inc ixh
;    cp 32*8
;    jr nc,max_length_of_sentence_in_one_line_limit_reached
;    djnz max_length_of_sentence_in_one_line_loop
;    ld a,ixh
;    ret
;max_length_of_sentence_in_one_line_limit_reached:
;    ld a,ixl
;    ret


; ------------------------------------------------
; Same as "draw_sentence", but it splits the text into multiple lines
; Arguments:
; - hl: sentence to draw (first byte is the length)
; - de: video memory address
; - iyl: color attribute
;draw_multi_line_sentence:
;    push hl
;    push de
;        call max_length_of_sentence_in_one_line
;    pop de
;    pop hl    
;    ; limit the sentence to that width and rraw it:
;    ld c,(hl)   ; we save the old length
;    ld (hl),a
;    push bc
;    push hl
;    push de
;        call draw_sentence
;    pop hl
;    ld bc,32*8
;    add hl,bc
;    ex de,hl    ; next line
;    pop hl
;    pop bc
;    ld a,c
;    sub (hl)    ; length left
;    ret z   ; if we have drawn the whole sentence, we are done
;    ld c,a
;    push bc
;        ld b,0
;        ld c,(hl)
;        add hl,bc   ; we advance hl to the remainder of the sentence
;    pop bc
;    ld (hl),c
;    jr draw_multi_line_sentence


; ------------------------------------------------
; Draws a sentence to video memory
; Arguments:
; - hl: sentence to draw (first byte is the length)
; - de: target VRAM address
; - iyl: color (attribute byte)
; - bc: expected length in bytes
draw_sentence:
	call draw_sentence_pre_render
	jp render_text_draw_buffer


draw_sentence_slow:
	call draw_sentence_pre_render
	jp render_text_draw_buffer_slow


draw_sentence_pre_render:
	push de
	push iy
	push bc
		ld de,text_draw_buffer
	    ld b,(hl)   ; get the sentence length
	    inc hl
	    ld c,128  ; start in pixel 0
draw_sentence_loop:
	    push bc
	    push hl
	        ld a,(hl)
	        call draw_font_character
	        ld a,c	; we save the pixel mask
	    pop hl
	    pop bc
	    ld c,a

	    ; next character
	    inc hl  
	    djnz draw_sentence_loop
	pop bc
	pop iy
	pop de
	ld a,iyl
	ret


; ------------------------------------------------
; Draws a character to video memory
; Arguments:
; - a: character to draw
; - de: memory address to draw
; - c: pixel offset (to determine whether we start in pixel 0, 1, 2, 3, 4, 5, 6, or 7 in the current tile)
;	- This is a a "mask": 1, 2, 4, 8, 16, 32, ...
draw_font_character:
    ; get the pointer to the character:
    push de
        ; for variable size fonts:
        ld d,0
        ld e,a
        ld hl,font
        add hl,de
        add hl,de
        add hl,de	; index of the letter is a*3
    pop de

    ld b,(hl)	; character size
    inc hl
draw_font_character_loop:
	push bc
	    ld b,(hl)	; column bitmap
	    inc hl

	    ; render one column of the character:
	    ld ixl,8
	    push de
draw_font_character_loop2:
		    ld a,(de)
		    sra b
		    jr nc,draw_font_character_loop_no_pixel
		    or c
		    ld (de),a
draw_font_character_loop_no_pixel:
			inc de
			dec ixl
			jr nz,draw_font_character_loop2
		pop de
    pop bc
    rrc c
    jr nc,draw_font_character_loop_no_next_tile
    push hl
    	ld hl,8
    	add hl,de
    	ex de,hl
    pop hl
draw_font_character_loop_no_next_tile:
    djnz draw_font_character_loop
    ret


; ------------------------------------------------
; input:
; - hl: name table address to start rendering
; - b: length of the text to render
; - a: first tile index to render
draw_text_name_table_ingame:
	push af
		push bc
			call SETWRT
		pop bc
	    ld a,(VDP.DW)
	    ld c,a
	pop af
draw_text_name_table_ingame_loop:
    out (c),a
    inc a
    djnz draw_text_name_table_ingame_loop
	ret