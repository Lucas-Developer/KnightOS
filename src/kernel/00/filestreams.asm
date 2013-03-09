; Inputs:
;   DE: File name
; Outputs:
; (Failure)
;   A: Error code
;   Z: Reset
; (Success)
;   D: File stream ID
;   E: Garbage    
openFileRead:
    push hl
    push de
    push bc
    push af
    ld a, i
    push af
        di
        call findFileEntry
        ex de, hl
        jr nz, .notFound
        ; Create stream based on file entry
        out (6), a
        ld a, (activeFileStreams)
        cp maxFileStreams
        jr nc, .tooManyStreams
        add a \ add a \ add a ; A *= 8
        ld hl, fileHandleTable
        add l \ jr nc, $+3 \ inc hl
        ; HL points to next entry in table
        ld a, (nextStreamId)
        ld (hl), a \ inc a \ ld (nextStreamId), a
        inc hl
        ld (hl), s_readable ; Flags
        inc hl \ inc hl \ inc hl ; Skip buffer address
        ex de, hl
        ; Seek HL to file size in file entry
        ld bc, 7
        or a \ sbc hl, bc
        ; Do some logic with the file size and save it for later
        ld a, (hl) \ inc hl \ or a \ ld a, (hl)
        push af
            dec hl \ dec hl \ dec hl ; Seek HL to block address
            ; Write block address to table
            ld c, (hl) \ dec hl \ ld b, (hl)
            ex de, hl
            ld (hl), c \ inc hl \ ld (hl), b \ inc hl
            ex de, hl
            ; Find the flash address of that section
            ld a, c \ and %11111 \ ld b, a \ ld c, 0
            ld hl, 0x4000 \ add hl, bc
            ; HL now points to flash address of that section
            ex de, hl
            ld (hl), e \ inc hl \ ld (hl), d \ inc hl
        pop af
        ; Get the size of this block in A
        jr z, _
        ld a, $FF
_:      ; A is block size
        ld (hl), a
        ; Get handle ID and return it, we're done here
        ld bc, 7 \ or a \ sbc hl, bc
        ld d, (hl)
    pop af
    jp po, _
    ei
_:  pop af
    pop bc
    inc sp \ inc sp ; Don't pop de
    pop hl
    cp a
    ret
.tooManyStreams:
    pop af
    jp po, _
    ei
_:  pop af
    pop bc
    pop de
    pop hl
    or 1
    ld a, errTooManyStreams
    ret
.notFound:
    pop af
    jp po, _
    ei
_:  pop af
    pop bc
    pop de
    pop hl
    or 1
    ld a, errFileNotFound
    ret
    