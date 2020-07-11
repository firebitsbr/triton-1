    include "constants.asm"
    include "autogenerated/text-constants.asm"

; the first time this is compiled, we need a few symbols to be defined 
; to bootstrap the process. Comment the inclusion of trition.zym and Uncomment these 
; constant definition lines:
	include "../triton.sym"
player_y:                   equ player_sprite_attributes
player_x:                   equ player_sprite_attributes+1
    
; decompress_boss1_tiles_plt_from_page1:  equ 0
; boss1_sprites_plt:  equ 0
; boss1_frames_plt:   equ 0
; SFX_big_explosion:  equ 0
; wave_types:         equ 0
; boss_hit_gfx:       equ 0

; buffer3: equ 0
; boss1_frames:       equ 0
; boss_state:         equ 0
; boss_state_cycle:   equ 0
; boss_x:             equ 0
; boss_y:             equ 0
; boss_polyphemus_leg_frame:   equ 0
; boss_polyphemus_arm_frame:   equ 0
; boss_polyphemus_eye_frame:   equ 0
; boss_target_y:      equ 0
; enemy_sprite_attributes:    equ 0
; boss_laser_length:  equ 0
; boss_laser_last_length: equ 0
; boss_laser_last_ptr:    equ 0
; boss_polyphemus_moving_direction:   equ 0
; boss_previous_ptr:  equ 0

; init_boss_base:     equ 0
; update_boss_check_if_hit:   equ 0
; update_boss_explosion:  equ 0
; update_boss_fire_bullet:    equ 0
; update_boss_clear_laser:    equ 0
; get_boss_ptr:       equ 0
; update_boss_draw_thruster:  equ 0
; update_boss_draw_laser:     equ 0

; unpack_compressed: equ 0
; fast_LDIRVM: equ 0
; StopMusic:   equ 0
; play_SFX_with_high_priority:    equ 0
; random:         equ 0
; spawn_enemy_wave:   equ 0
; clear_tile_enemy:   equ 0
; copy_non_empty_enemy_tiles: equ 0

    org BOSS_COMPRESSED_CODE_START

    include "boss-polyphemus.asm"