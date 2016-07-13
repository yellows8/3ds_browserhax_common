.section .init
.global _start
.arm

//This is a loader for hblauncher, for the Old3DS/New3DS system web-browsers.
//Also note that APT would be broken even worse than with other hax which boot hblauncher, with the spider version of this.

_start:
mov r7, r0
ldr sp, =(0x10000000-0x7000)

add r1, pc, #1
bx r1
.thumb

ldr r0, =0x3a545041 @ Get APT:U handle, @ sp+12.
str r0, [sp, #4]
mov r0, #0x55
str r0, [sp, #8]

add r0, sp, #12
add r1, sp, #4
mov r2, #5
mov r3, #0
ldr r4, [r7, #0x18]
blx r4 @ srv_GetServiceHandle
ldr r3, =0x24242424
blx checkerror_triggercrash

add r0, sp, #12
add r1, sp, #16 @ u8 out new3ds flag, this will be zero if the func returns any errors. 0 = Old3DS, 1 = New3DS.
bl APT_CheckNew3DS

ldr r0, [sp, #12]
blx svcCloseHandle

ldrb r0, [sp, #16]
cmp r0, #0
bne menustubcpy_end

blx getaddrs_menustub
mov r2, r1
mov r1, r0
ldr r0, =0x1000
add r0, r0, r7

menustubcpy:
ldr r3, [r1]
str r3, [r0]
add r1, r1, #4
add r0, r0, #4
cmp r1, r2
blt menustubcpy

ldr r0, =0x1000 @ Flush dcache for the menustub data.
add r0, r0, r7
ldr r1, =0x320
ldr r3, [r7, #0x20]
blx r3

menustubcpy_end:
add r0, sp, #36
add r1, sp, #40
bl loadsd_payload
cmp r0, #0
beq _start_loadsd_success
add r0, sp, #36
add r1, sp, #40
ldrb r2, [sp, #16]
bl http_download_payload

_start_loadsd_success:
ldr r3, =0x80808080
blx checkerror_triggercrash @ Trigger crash on payload loading fail.

ldr r5, [sp, #36]
ldr r6, [sp, #40]

mov r0, r5 @ Flush dcache for the menuropbin data.
ldr r1, =0x10000
ldr r3, [r7, #0x20]
blx r3

ldr r0, =0x1ED02A04
ldr r1, =0x0100A5FF
bl gsp_writereg @ Set sub-screen colorfill to orange.

@ Copy the menuropbin via the GPU.

ldrb r2, [sp, #16]
cmp r2, #0
beq menuropbin_vramcopy

mov r0, r5 @ New3DS
ldr r1, =0x38c40000
ldr r2, =0x10000
bl gxcmd4
blx svcSleepThread_1second

@ Clear the hblauncher parameter block.
mov r0, r5

mov r1, #0
mov r2, r1
ldr r3, =0x2800

hblauncher_clear_paramblk:
str r1, [r0, r2]
add r2, r2, #4
cmp r2, r3
blt hblauncher_clear_paramblk

mov r1, r3
ldr r3, [r7, #0x20]
blx r3

mov r0, r5
ldr r1, =0x38c40000 - 0x800*6
ldr r2, =0x2800 @ 0x2000 is included for backwards-compatibility.
bl gxcmd4
blx svcSleepThread_1second
b menuropbin_vramcopy_finish

menuropbin_vramcopy: @ Old3DS
mov r0, r5
ldr r1, =0x1f500000
ldr r2, =0x10000
bl gxcmd4 @ Copy the menuropbin data into VRAM, which will be loaded by the below homemenu code later.
blx svcSleepThread_1second

menuropbin_vramcopy_finish:
mov r0, r6
bl calcverify_payload_size
mov r6, r0

ldrb r2, [sp, #16]
cmp r2, #0
beq menutakeover_begin

ldr r3, =0x10000
mov r0, r5
add r0, r0, r3 @ loadropbin blob address
ldr r1, [sp, #40]
sub r1, r1, r3 @ loadropbin blob size

bl regular_menutakeover
ldr r3, =0xa4a4a4a4
blx checkerror_triggercrash
bl aptExit

mov r0, r5
mov r1, r6
bl freemem

ldr r3, =0xa8a8a8a8
blx checkerror_triggercrash
b shutdown_gsp

menutakeover_begin:
mov r0, #0
str r0, [sp, #44]

mov r0, r5
mov r1, r6
bl freemem

ldr r0, =0x09a00000-0xd00000 @ Free some of the spider regular-heap so that there's enough memory available to launch Home Menu.
ldr r1, =(0xd00000)
bl freemem
cmp r0, #0
beq menutakeover_begin_aptinit

ldr r0, =0x100000
str r0, [sp, #44]

ldr r0, =0x09a00000-0xd00000-0x100000 @ If the above free failed it's probably because this is running under the CHN or TWN browser. Try again with an addr for the CHN/TWN browser.
ldr r1, =(0xd00000)
bl freemem
cmp r0, #0
beq menutakeover_begin_aptinit

@ Trigger a crash since freemem failed.
ldr r3, =0xf0f0f0f0
str r0, [r3]

menutakeover_begin_aptinit:
add r0, sp, #12 @ Get APT:U handle, @ sp+12.
add r1, sp, #4
mov r2, #5
mov r3, #0
ldr r4, [r7, #0x18]
blx r4 @ srv_GetServiceHandle
ldr r3, =0x48484848
blx checkerror_triggercrash

add r0, sp, #12
ldr r1, =0x101
bl APT_PreloadLibraryApplet @ Launch Home Menu as a "LibraryApplet".
ldr r3, =0xc0c0c0c0
blx checkerror_triggercrash

add r0, sp, #12
ldr r1, =0x101
bl APT_FinishPreloadingLibraryApplet
ldr r3, =0xd0d0d0d0
blx checkerror_triggercrash

ldr r0, [sp, #12]
blx svcCloseHandle

ldr r0, =(0x6500000+0x14000000)
ldr r3, [sp, #44]
add r3, r3, r0
str r3, [sp, #44]
mov r0, #0
str r0, [sp, #48]

menutextphys_search: @ v10.4 loader-process in FIRM added "randomization" for the codebin physmem of certain processes, including Home Menu.
ldr r0, [sp, #44]
ldr r5, =0x1f510000

mov r1, r5
ldr r2, =0xf0000
mov r6, r1
add r6, r6, r2
sub r6, r6, #4
ldr r4, [r6]
bl gxcmd4 @ Copy <above size> of Home Menu .text to <outbuf>. 0x10000-bytes is the lowest possible size of a chunk with the physmem-randomization.

waitcodevramcpy_finish: @ Wait for the above copy to completely finish.
ldr r0, [r6]
cmp r0, r4
beq waitcodevramcpy_finish

menutextphys_search_checkword:
ldr r3, =0xeb000007 @ Check whether section+0 matches homemenu .text+0.
ldr r1, [r5]
cmp r1, r3
beq menutextphys_search_done

ldr r2, =0x10000
ldr r0, [sp, #44]
add r0, r0, r2
str r0, [sp, #44]

//ldr r0, =0x00204BBC
ldr r0, =0xf0000
ldr r1, [sp, #48]
add r1, r1, r2
str r1, [sp, #48]
add r5, r5, r2
cmp r1, r0
//bcc menutextphys_search//Looping with gxcmd4 here is useless since homemenu takeover will fail due to .text not being overwritten in time.
bcc menutextphys_search_checkword

ldr r3, =0xa819f288 @ Trigger crash on failure.
str r3, [r3]

menutextphys_search_done:
@ Begin auto-locating the target code for homemenu takeover.
ldr r4, =0x00100000
mov r0, r4
//ldr r2, =0x1000
//add r5, r5, r2
mov r1, r5

@ Locate the "svc 0x03" instruction followed by bx-lr, which is the function right before main().
_start_locatecode_l0:
ldr r2, =0xef000003
ldr r3, [r1]
add r1, r1, #4
add r0, r0, #4
cmp r3, r2
bne _start_locatecode_l0
ldr r2, =0xe12fff1e
ldr r3, [r1]
cmp r3, r2
bne _start_locatecode_l0

ldr r2, =0xe3a00000 @ Locate the bl instruction following a "mov r0, #0", in main().
_start_locatecode_l1:
ldr r3, [r1]
add r1, r1, #4
add r0, r0, #4
cmp r3, r2
bne _start_locatecode_l1

ldr r1, [r1]
blx parse_branch

@ Get the address of the function being called with the bl-instruction @ <second-to-last func-call in the first chunk of func-calls> in the above function.
mov r1, r0
sub r1, r1, r4
add r1, r1, r5

_start_locatecode_l1_blstart: @ Locate the first bl instruction in the chunk.
ldr r3, [r1]
add r0, r0, #4
add r1, r1, #4
lsr r3, r3, #24
cmp r3, #0xeb
bne _start_locatecode_l1_blstart

_start_locatecode_l1_blend: @ Locate the last bl instruction in the chunk, by searching for the first non-bl instruction.
ldr r3, [r1]
add r0, r0, #4
add r1, r1, #4
lsr r3, r3, #24
cmp r3, #0xeb
beq _start_locatecode_l1_blend

sub r0, r0, #12
sub r1, r1, #12

ldr r1, [r1]
blx parse_branch
mov r1, r0
sub r1, r1, r4
add r1, r1, r5 @ r0/r1 is now the addresses for the target heap-init function.

/*mov r6, #2 @ Search for two "cmp <reg>, #100" instructions.
_start_locatecode_l2:
ldr r3, [r1]
add r1, r1, #4
add r0, r0, #4
ldr r2, =0xf0000
bic r3, r3, r2
ldr r2, =0xe3500064
cmp r3, r2
bne _start_locatecode_l2
sub r6, r6, #1
cmp r6, #0
bgt _start_locatecode_l2

mov r6, #4 @ Search for 4 bl instructions.
_start_locatecode_l3:
ldrb r3, [r1, #3]
add r1, r1, #4
add r0, r0, #4
cmp r3, #0xeb
bne _start_locatecode_l3
sub r6, r6, #1
cmp r6, #0
bgt _start_locatecode_l3

sub r0, r0, #4
sub r0, r0, #0x10
*/

add r0, r0, #0x10

mov r3, #4 @ Clear the low 4-bits for GPU alignment.
lsr r0, r0, r3
lsl r0, r0, r3
sub r0, r0, r4
mov r3, r0

ldr r0, =0x1000
ldr r1, [sp, #44] @ .text+<above offset>
add r1, r1, r3
add r1, r1, r0
add r0, r0, r7
ldr r2, =0x320
bl gxcmd4 @ Overwrite the homemenu code which handles allocating+initializing the initial heaps(the target code is near the beginning of the function).
/*
ldr r0, =100000
mov r1, #0
blx svcSleepThread

ldr r0, =(0x6500000+0x14000000) @ .text+0
ldr r1, =0x1f510000
ldr r2, =0xf0000
bl gxcmd4 @ Copy the first 0xf0000-bytes of Home Menu .text to VRAM+0x510000.
*/
@ Shutdown GSP.
shutdown_gsp:
bl GSPGPU_UnregisterInterruptRelayQueue
bl GSPGPU_ReleaseRight

svc 0x03 @ Terminate the browser process.
b .
.pool

.type freemem, %function
freemem: @ r0 = addr, r1 = size
push {r4, lr}
mov r3, r1 @ size
mov r1, r0 @ addr
mov r0, #1 @ operation
mov r4, #0 @ permissions
mov r2, #0 @ addr1
blx svcControlMemory
pop {r4, pc}

.type gxcmd4, %function
gxcmd4: @ r0 = src, r1 = dst, r2 = size
push {r4, lr}
sub sp, #16
mov r3, #0
str r3, [sp, #0]
str r3, [sp, #4]
str r3, [sp, #8]
mov r3, #0x8
str r3, [sp, #12]
mov r3, #0

ldr r4, [r7, #0x1c] @ gxcmd4
blx r4

add sp, sp, #16
pop {r4, pc}
.pool

.type APT_PreloadLibraryApplet, %function
APT_PreloadLibraryApplet: @ inr0=handle*, inr1=NS_APPID appID
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r0, [sp, #0]

ldr r5, =0x00160040
str r5, [r4, #0]
ldr r1, [sp, #4]
str r1, [r4, #4]

ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne APT_PreloadLibraryApplet_end
ldr r0, [r4, #4]

APT_PreloadLibraryApplet_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

.type APT_FinishPreloadingLibraryApplet, %function
APT_FinishPreloadingLibraryApplet: @ inr0=handle*, inr1=NS_APPID appID
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r0, [sp, #0]

ldr r5, =0x00170040
str r5, [r4, #0]
ldr r1, [sp, #4]
str r1, [r4, #4]

ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne APT_FinishPreloadingLibraryApplet_end
ldr r0, [r4, #4]

APT_FinishPreloadingLibraryApplet_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

APT_PrepareToStartSystemApplet: @ inr0=handle*, inr1=NS_APPID appID
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r0, [sp, #0]

ldr r5, =0x00190040
str r5, [r4, #0]
ldr r1, [sp, #4]
str r1, [r4, #4]

ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne APT_PrepareToStartSystemApplet_end
ldr r0, [r4, #4]

APT_PrepareToStartSystemApplet_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

APT_StartSystemApplet: @ inr0=handle*, inr1=appid, inr2=inhandle, inr3=u32 bufsize, insp0=u32* buf
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r0, [sp, #0]

ldr r5, =0x001F0084
str r5, [r4, #0]
ldr r1, [sp, #4] @ appid
str r1, [r4, #4]
mov r1, #0
str r1, [r4, #12]
ldr r1, [sp, #8] @ inhandle
str r1, [r4, #16]
ldr r1, [sp, #12] @ bufsize
str r1, [r4, #8]
mov r3, #2
lsl r1, r1, #14
orr r1, r1, r3
str r1, [r4, #20]
ldr r1, [sp, #28] @ buf0
str r1, [r4, #24]

ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne APT_StartSystemApplet_end
ldr r0, [r4, #4]

APT_StartSystemApplet_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

APT_CheckNew3DS: @ inr0=handle*, inr1=u8* out
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r2, [sp, #4]
mov r3, #0
strb r3, [r2]

ldr r0, [sp, #0]

ldr r5, =0x01020000
str r5, [r4, #0]

ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne APT_CheckNew3DS_end
ldr r0, [r4, #4]
cmp r0, #0
bne APT_CheckNew3DS_end

ldrb r1, [r4, #8]
ldr r2, [sp, #4]
strb r1, [r2]

APT_CheckNew3DS_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

GSPGPU_UnregisterInterruptRelayQueue:
push {r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, =0x00140000
str r1, [r4, #0]

ldr r0, [r7, #0x58]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne GSPGPU_UnregisterInterruptRelayQueue_end
ldr r0, [r4, #4]

GSPGPU_UnregisterInterruptRelayQueue_end:
pop {r4, pc}
.pool

GSPGPU_ReleaseRight:
push {r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, =0x00170000
str r1, [r4, #0]

ldr r0, [r7, #0x58]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne GSPGPU_ReleaseRight_end
ldr r0, [r4, #4]

GSPGPU_ReleaseRight_end:
pop {r4, pc}
.pool

gsp_writereg: @ Write an u32 to a GPU reg. r0 = regaddr, r1 = u32 val. regaddr can be IO vaddr, or relative to 0x1EB00000.
push {lr}
sub sp, sp, #4

ldr r3, =0x1EB00000
cmp r0, r3
blt gsp_writereg_start
sub r0, r0, r3

gsp_writereg_start:
str r1, [sp, #0]

mov r1, sp
mov r2, #4
bl GSPGPU_WriteHWRegs

add sp, sp, #4
pop {pc}
.pool

GSPGPU_WriteHWRegs: @ r0=gpuregadr, r1=buf*, r2=size
push {r0, r1, r2, r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, =0x00010082
str r1, [r4, #0]
ldr r1, [sp, #0]
str r1, [r4, #4]
ldr r1, [sp, #8]
str r1, [r4, #8]
lsl r1, r1, #14
mov r2, #2
orr r1, r1, r2
str r1, [r4, #12]
ldr r1, [sp, #4]
str r1, [r4, #16]

ldr r0, [r7, #0x58]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne GSPGPU_WriteHWRegs_end
ldr r0, [r4, #4]

GSPGPU_WriteHWRegs_end:
add sp, sp, #12
pop {r4, pc}
.pool

calcverify_payload_size: @ r0 = raw payload size.
@ The sizes must not have bitmask 0xf0000000 set. Returns the allocsize on success, <0 on error.
mov r3, r0
mov r1, #2
mvn r0, r1

mov r2, r3
lsr r2, r2, #28
cmp r2, #0
bne calcverify_payload_size_end @ Verify the raw payload size.

ldr r1, =0x10004
cmp r3, r1
bcc calcverify_payload_size_end @ Original payload size must be at least 0x10004-bytes.

ldr r1, =0xfff
add r3, r3, r1
bic r3, r3, r1

mov r2, r3
lsr r2, r2, #28
cmp r2, #0
bne calcverify_payload_size_end

mov r0, r3

calcverify_payload_size_end:
bx lr
.pool

.type loadsd_payload, %function
loadsd_payload: @ r0 = ptr where the address of the allocbuf is written, r1 = u32* output payload-size.
push {r4, r5, lr}
push {r0, r1}
sub sp, sp, #0x20

blx getaddr_sdpayload_path
mov r5, r0

add r0, sp, #12 @ ctx

mov r1, #0
mov r2, r1
mov r3, #0x14

loadsd_payload_ctxclr:
str r1, [r0, r2]
add r2, r2, #4
cmp r2, r3
blt loadsd_payload_ctxclr

mov r1, r5 @ UTF-16 filepath
mov r2, #1 @ openflags
ldr r3, [r7, #0x24]
blx r3 @ IFile_Open
mov r2, #0 @ Set r2 for debug.
cmp r0, #0
bne loadsd_payload_end

add r0, sp, #12
add r1, sp, #4
ldr r3, [r7, #0x2c]
blx r3 @ IFile_GetSize
cmp r0, #0
bne loadsd_payload_end

ldr r0, [sp, #4]
bl calcverify_payload_size
cmp r0, #0
blt loadsd_payload_end
mov r3, r0

mov r1, #0 @ addr
ldr r0, =0x10003 @ operation
mov r4, #3 @ permissions
mov r2, #0 @ addr1
blx svcControlMemory
ldr r3, =0x70707070
blx checkerror_triggercrash @ Trigger crash on memalloc fail.
mov r4, r1
ldr r2, [sp, #0x20]
str r4, [r2]

@ Read the file with the above size into the input buffer.
add r0, sp, #12 @ ctx
add r1, sp, #0 @ u32* readcount
mov r2, r4
ldr r3, [sp, #4]
ldr r4, [sp, #0x24]
str r3, [r4]
ldr r4, [r7, #0x34]
blx r4 @ IFile_Read
mov r2, #3
cmp r0, #0
bne loadsd_payload_end

mov r2, #4
mvn r0, r2 @ Return ~4 when readcount is zero.
ldr r1, [sp, #0]
cmp r1, #0
beq loadsd_payload_end

ldr r0, [sp, #12]
ldr r3, [r7, #0x28]
blx r3 @ IFile_Close
mov r0, #0

loadsd_payload_end:
add sp, sp, #0x28
pop {r4, r5, pc}
.pool

@ This is based on code from hblauncher.
regular_menutakeover: @ r0 = src loadropbin blob address, r1 = blob size.
push {r4, r5, r6, lr}
sub sp, sp, #8
str r0, [sp, #0]
str r1, [sp, #4]

ldr r3, =0x10000 @ size
mov r1, #0 @ addr
ldr r0, =0x10003 @ operation
mov r4, #3 @ permissions
mov r2, #0 @ addr1
blx svcControlMemory
ldr r3, =0x74747474
blx checkerror_triggercrash @ Trigger crash on memalloc fail.
mov r4, r1

ldr r5, =0x37c00000 @ Hard-coded for New3DS, since this function is only used by this loader on New3DS.

regular_menutakeover_lp:
mov r0, r4 @ Flush buffer dcache.
ldr r1, =0x10000
ldr r3, [r7, #0x20]
blx r3

mov r0, r5
mov r1, r4
ldr r2, =0x10000
bl gxcmd4 @ Copy homemenu linearmem heap data into the above buffer, then wait for the copy to finish.
ldr r0, =1000000
mov r1, #0
blx svcSleepThread

mov r0, #0
regular_menutakeover_scanlp:
mov r2, r0
add r2, r2, r4
ldr r1, [r2, #0x8]
ldr r3, =0x5544
cmp r1, r3
bne regular_menutakeover_scanlpnext

ldr r1, [r2, #0xc]
cmp r1, #0x80
bne regular_menutakeover_scanlpnext

ldr r1, [r2, #0x18]
cmp r1, #0
beq regular_menutakeover_scanlpnext

ldr r1, [r2, #0x7c]
ldr r3, =0x6E4C5F4E
cmp r1, r3
bne regular_menutakeover_scanlpnext

mov r1, r5
add r1, r1, r0
add r1, r1, #0x18
mov r0, r4
ldr r2, [sp, #0]
ldr r3, [sp, #4]
bl inject_payload
mov r6, r0
b regular_menutakeover_end

regular_menutakeover_scanlpnext:
add r0, r0, #4
ldr r1, =(0x10000-0x10)
cmp r0, r1
bcc regular_menutakeover_scanlp

regular_menutakeover_lpnext:
ldr r1, =(0x10000-0x100)
ldr r3, =(0x37c00000+0x01000000)
add r5, r5, r1
cmp r5, r3
bcc regular_menutakeover_lp

mov r6, #0
mvn r6, r6

regular_menutakeover_end:
ldr r0, =100000000
mov r1, #0
blx svcSleepThread

mov r0, r4
ldr r1, =0x10000
bl freemem

mov r0, r6
add sp, sp, #8
pop {r4, r5, r6, pc}
.pool

@ This is based on code from hblauncher.
inject_payload: @ r0 = buffer, r1 = target_address, r2 = binaryblob*, r3 = binaryblobsize.
push {r4, r5, r6, lr}
sub sp, sp, #12
str r2, [sp, #0]
str r3, [sp, #4]
str r1, [sp, #8]

mov r4, r0
mov r5, r1
mov r6, r1
lsr r5, r5, #8
lsl r5, r5, #8
sub r6, r6, r5
add r6, r6, r4

mov r0, r4 @ Flush buffer dcache.
ldr r1, =0x1000
ldr r3, [r7, #0x20]
blx r3

@ Read homemenu memory + wait for the copy to finish.
mov r0, r5
mov r1, r4
ldr r2, =0x1000
bl gxcmd4
ldr r0, =10000000
mov r1, #0
blx svcSleepThread

mov r0, r4 @ Flush buffer dcache.
ldr r1, =0x1000
ldr r3, [r7, #0x20]
blx r3

mov r0, #0 @ Copy the binary into the buffer with patches when needed.
ldr r1, [sp, #0]
inject_payload_lp:
ldr r2, [r1, r0]
ldr r3, =(0xBABE0000+0x100)
cmp r2, r3
bcs inject_payload_lp0
ldr r3, =(0xBABE0000-0x100+1)
cmp r2, r3
bcc inject_payload_lp0
ldr r3, [sp, #8]
add r2, r2, r3
ldr r3, =0xBABE0000
sub r2, r2, r3
str r2, [r6, r0]
b inject_payload_lpnext

inject_payload_lp0:
ldr r3, =0xDEADCAFE
cmp r2, r3
beq inject_payload_lpnext

str r2, [r6, r0]

inject_payload_lpnext:
add r0, r0, #4
ldr r2, [sp, #4]
cmp r0, r2
bcc inject_payload_lp

@ Write homemenu memory + wait for the copy to finish.
mov r0, r4 @ Flush buffer dcache.
ldr r1, =0x1000
ldr r3, [r7, #0x20]
blx r3

mov r0, r4
mov r1, r5
ldr r2, =0x1000
bl gxcmd4
ldr r0, =10000000
mov r1, #0
blx svcSleepThread

mov r0, #0

add sp, sp, #12
pop {r4, r5, r6, pc}
.pool

aptExit: @ Exit from the current system-applet with APT(homemenu takeover won't work without exiting via APT properly). This is only used on New3DS.
push {r4, r5, r6, lr}
sub sp, sp, #16

ldr r0, =0x3a545041
str r0, [sp, #4]
mov r0, #0x55
str r0, [sp, #8]

add r0, sp, #12 @ Get APT:U handle, @ sp+12.
add r1, sp, #4
mov r2, #5
mov r3, #0
ldr r4, [r7, #0x18]
blx r4 @ srv_GetServiceHandle
mov r4, r0
cmp r0, #0
bne aptExit_end

add r0, sp, #12
ldr r1, =0x101
bl APT_PrepareToStartSystemApplet
mov r4, r0
cmp r4, #0
bne aptExit_finished

add r0, sp, #12 @ handle*
ldr r1, =0x101 @ appid
mov r2, #0 @ inhandle
mov r3, #0
str r3, [sp, #0] @ bufsize/buf*
bl APT_StartSystemApplet
mov r4, r0
cmp r4, #0
bne aptExit_finished

aptExit_finished:
ldr r0, [sp, #12]
blx svcCloseHandle

aptExit_end:
mov r0, r4
add sp, sp, #16
pop {r4, r5, r6, pc}
.pool

fsuser_initialize:
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r0, [sp, #0]

ldr r5, =0x08010002
str r5, [r4, #0]
mov r1, #0x20
str r1, [r4, #4]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne fsuser_initialize_end
ldr r0, [r4, #4]

fsuser_initialize_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

fsuser_openfiledirectly: @ r0=fsuser* handle, r1=archiveid, r2=archive lowpath type, r3=archive lowpath bufptr, sp0=archive lowpath bufsize, sp4=file lowpath type, sp8=file lowpath bufptr*, sp12=file lowpath bufsize, sp16=openflags, sp20=file out handle*
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r0, [sp, #0]
ldr r1, [sp, #4]
ldr r2, [sp, #8]

ldr r5, =0x08030204
str r5, [r4, #0]
mov r5, #0
str r5, [r4, #4] @ transaction
str r1, [r4, #8] @ archiveid
str r2, [r4, #12] @ Archive LowPath.Type
ldr r2, [sp, #28]
str r2, [r4, #16] @ Archive LowPath.Size
ldr r2, [sp, #32]
str r2, [r4, #20] @ File LowPath.Type
ldr r3, [sp, #40]
str r3, [r4, #24] @ File LowPath.Size
ldr r5, [sp, #44]
str r5, [r4, #28] @ Openflags
mov r5, #0
str r5, [r4, #32] @ Attributes
ldr r3, [sp, #28]
ldr r5, =0x802
lsl r3, r3, #14
orr r3, r3, r5
str r3, [r4, #36] @ archive lowpath translate hdr/ptr
ldr r5, [sp, #12]
str r5, [r4, #40]
ldr r3, [sp, #40]
mov r5, #2
lsl r3, r3, #14
orr r3, r3, r5
str r3, [r4, #44] @ file lowpath translate hdr/ptr
ldr r2, [sp, #36]
str r2, [r4, #48]

ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne fsuser_openfiledirectly_end

ldr r0, [r4, #4]
ldr r2, [sp, #48]
ldr r1, [r4, #12]
cmp r0, #0
bne fsuser_openfiledirectly_end
str r1, [r2]

fsuser_openfiledirectly_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

fsfile_read: @ r0=filehandle*, r1=u32 filepos, r2=buf*, r3=size, sp0=u32* total transfersize
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r0, [sp, #0]
ldr r1, [sp, #4]
ldr r2, [sp, #8]
ldr r3, [sp, #12]

ldr r5, =0x080200C2
str r5, [r4, #0]
str r1, [r4, #4] @ filepos
mov r1, #0
str r1, [r4, #8]
str r3, [r4, #12] @ Size
mov r5, #12
lsl r3, r3, #4
orr r3, r3, r5
str r3, [r4, #16] @ buf lowpath translate hdr/ptr
str r2, [r4, #20]

ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne fsfile_read_end
ldr r0, [r4, #4]
ldr r2, [sp, #28]
ldr r1, [r4, #8]
cmp r0, #0
bne fsfile_read_end
str r1, [r2]

fsfile_read_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

fsfile_getsize: @ r0=filehandle*, r1=u64* outsize
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r0, [sp, #0]

ldr r5, =0x08040000
str r5, [r4, #0]

ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne fsfile_getsize_end
ldr r0, [r4, #4]
ldr r1, [sp, #4]
cmp r0, #0
bne fsfile_getsize_end
cmp r1, #0
beq fsfile_getsize_end
ldr r2, [r4, #8]
ldr r3, [r4, #12]
str r2, [r1, #0]
str r3, [r1, #4]

fsfile_getsize_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

fsfile_close: @ r0=filehandle*
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r0, [sp, #0]

ldr r5, =0x08080000
str r5, [r4, #0]

ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne fsfile_close_end
ldr r0, [r4, #4]

fsfile_close_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

@ Most of the HTTPC code here is from smashbroshax.
HTTPC_sendcmd:
push {r0, r1, r2, r3, r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, [sp, #12]
str r1, [r4, #0]
ldr r1, [sp, #4]
str r1, [r4, #4]
ldr r1, [sp, #8]
str r1, [r4, #8]

ldr r0, [sp, #0]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne HTTPC_sendcmd_end
ldr r0, [r4, #4]

HTTPC_sendcmd_end:
add sp, sp, #16
pop {r4, pc}
.pool

HTTPC_Initialize:
push {r0, r1, r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, =0x00010044
str r1, [r4, #0]
ldr r1, =0x1000
str r1, [r4, #4]
mov r1, #0x20
str r1, [r4, #8]
mov r1, #0
str r1, [r4, #16]
str r1, [r4, #20]

ldr r0, [sp, #0]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne HTTPC_Initialize_end
ldr r0, [r4, #4]

HTTPC_Initialize_end:
pop {r1, r2, r4, pc}
.pool

HTTPC_InitializeConnectionSession:
mov r2, #0x20
ldr r3, =0x00080042
b HTTPC_sendcmd
.pool

HTTPC_SetProxyDefault:
ldr r3, =0x000e0040
b HTTPC_sendcmd
.pool

HTTPC_CloseContext:
ldr r3, =0x00030040
b HTTPC_sendcmd
.pool

HTTPC_BeginRequest:
ldr r3, =0x00090040
b HTTPC_sendcmd
.pool

HTTPC_CreateContext: @ r0=handle*, r1=ctxhandle*, r2=urlbuf*, r3=urlbufsize
push {r0, r1, r2, r3, r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, =0x00020082
str r1, [r4, #0]
ldr r1, [sp, #12]
str r1, [r4, #4]
lsl r1, r1, #4
mov r2, #0xa
orr r1, r1, r2
str r1, [r4, #12]
ldr r2, [sp, #8]
str r2, [r4, #16]
mov r3, #1
str r3, [r4, #8]

ldr r0, [sp, #0]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne HTTPC_CreateContext_end
ldr r0, [r4, #4]
cmp r0, #0
bne HTTPC_CreateContext_end
ldr r2, [sp, #4]
ldr r1, [r4, #8]
str r1, [r2]

HTTPC_CreateContext_end:
add sp, sp, #16
pop {r4, pc}
.pool

HTTPC_GetDownloadSizeState: @ r0=handle*, r1=ctxhandle*, r2=u32* downloadedsize, r3=u32* contentsize
push {r0, r1, r2, r3, r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, =0x00060040
str r1, [r4, #0]
ldr r1, [sp, #4]
str r1, [r4, #4]

ldr r0, [sp, #0]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne HTTPC_GetDownloadSizeState_end
ldr r0, [r4, #4]
cmp r0, #0
bne HTTPC_GetDownloadSizeState_end
ldr r2, [sp, #8]
ldr r1, [r4, #8]
cmp r2, #0
beq HTTPC_GetDownloadSizeState_finish0
str r1, [r2]

HTTPC_GetDownloadSizeState_finish0:
ldr r2, [sp, #12]
ldr r1, [r4, #12]
cmp r2, #0
beq HTTPC_GetDownloadSizeState_end
str r1, [r2]

HTTPC_GetDownloadSizeState_end:
add sp, sp, #16
pop {r4, pc}
.pool

HTTPC_ReceiveData: @ r0=handle*, r1=ctxhandle, r2=buf*, r3=bufsize
push {r0, r1, r2, r3, r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, =0x000B0082
str r1, [r4, #0]
ldr r1, [sp, #4]
str r1, [r4, #4]
ldr r1, [sp, #12]
str r1, [r4, #8]
lsl r1, r1, #4
mov r2, #0xc
orr r1, r1, r2
str r1, [r4, #12]
ldr r2, [sp, #8]
str r2, [r4, #16]

ldr r0, [sp, #0]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne HTTPC_ReceiveData_end
ldr r0, [r4, #4]

HTTPC_ReceiveData_end:
add sp, sp, #16
pop {r4, pc}
.pool

HTTPC_AddRequestHeaderField: @ r0=handle*, r1=ctxhandle, r2=headername*, r3=headernamesize, sp0=valuebuf*, sp4=valuebufsize
push {r0, r1, r2, r3, r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, =0x001100c4
str r1, [r4, #0]
ldr r1, [sp, #4]
str r1, [r4, #4]
ldr r1, [sp, #12]
str r1, [r4, #8]
ldr r1, [sp, #28]
str r1, [r4, #12]
ldr r1, [sp, #12]
lsl r1, r1, #14
ldr r2, =0xc02
orr r1, r1, r2
str r1, [r4, #16]
ldr r2, [sp, #8]
str r2, [r4, #20]

ldr r1, [sp, #28]
lsl r1, r1, #4
mov r2, #0xa
orr r1, r1, r2
str r1, [r4, #24]
ldr r2, [sp, #24]
str r2, [r4, #28]

ldr r0, [sp, #0]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne HTTPC_AddRequestHeaderField_end
ldr r0, [r4, #4]

HTTPC_AddRequestHeaderField_end:
add sp, sp, #16
pop {r4, pc}
.pool

HTTPC_GetResponseHeader: @ r0=handle*, r1=ctxhandle, r2=headername*, r3=headernamesize, sp0=outvaluebuf*, sp4=outmaxsize, sp8=u32* actual value stringlen.
push {r0, r1, r2, r3, r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, =0x001E00C4
str r1, [r4, #0]
ldr r1, [sp, #4]
str r1, [r4, #4]
ldr r1, [sp, #12]
str r1, [r4, #8]
ldr r1, [sp, #28]
str r1, [r4, #12]
ldr r1, [sp, #12]
lsl r1, r1, #14
ldr r2, =0xc02
orr r1, r1, r2
str r1, [r4, #16]
ldr r2, [sp, #8]
str r2, [r4, #20]

ldr r1, [sp, #28]
lsl r1, r1, #4
mov r2, #0xc
orr r1, r1, r2
str r1, [r4, #24]
ldr r2, [sp, #24]
str r2, [r4, #28]

ldr r0, [sp, #0]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne HTTPC_GetResponseHeader_end
ldr r0, [r4, #4]
ldr r2, [sp, #32]
cmp r2, #0
beq HTTPC_GetResponseHeader_end
ldr r3, [r4, #8]
str r3, [r2]

HTTPC_GetResponseHeader_end:
add sp, sp, #16
pop {r4, pc}
.pool

HTTPC_GetResponseStatusCode: @ r0=handle*, r1=ctxhandle*, r2=u32* out
push {r0, r1, r2, r3, r4, lr}
blx get_cmdbufptr
mov r4, r0

ldr r1, =0x00220040
str r1, [r4, #0]
ldr r1, [sp, #4]
str r1, [r4, #4]

ldr r0, [sp, #0]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne HTTPC_GetResponseStatusCode_end
ldr r0, [r4, #4]
cmp r0, #0
bne HTTPC_GetResponseStatusCode_end
ldr r2, [sp, #8]
ldr r1, [r4, #8]
cmp r2, #0
beq HTTPC_GetResponseStatusCode_end
str r1, [r2]

HTTPC_GetResponseStatusCode_end:
add sp, sp, #16
pop {r4, pc}
.pool

load_romfs: @ r0 = programID-low, r1 = programID-high, r2 = mediatype, r3 = ncch contentindex, sp0 = ptr where the address of the allocated romfs buffer will be written, sp4 = u32* where the romfs size will be written.
push {r4, r5, r6, lr}
sub sp, sp, #0x64

add r4, sp, #0x2c @ Setup the archive lowpath
str r0, [r4, #0]
str r1, [r4, #4]
str r2, [r4, #8]
mov r0, #0
str r0, [r4, #0xc]

add r4, sp, #0x3c @ Setup the file lowpath.
mov r0, #0
mov r1, r0
load_romfs_clrfilelowpath:
str r1, [r4, r0]
add r0, r0, #4
cmp r0, #0x14
blt load_romfs_clrfilelowpath

str r3, [r4, #0x4]

mov r1, #0
str r1, [sp, #0x60]

ldr r0, =0x553a7366
str r0, [sp, #0x20]
ldr r0, =0x524553
str r0, [sp, #0x24]

add r0, sp, #0x18 @ Get fs:USER handle, @ sp+0x18.
add r1, sp, #0x20
mov r2, #7
mov r3, #0
ldr r4, [r7, #0x18]
blx r4 @ srv_GetServiceHandle
mov r4, r0
cmp r4, #0
bne load_romfs_end

add r0, sp, #0x18
bl fsuser_initialize
mov r4, r0
cmp r4, #0
bne load_romfs_finish

mov r0, #0x10
str r0, [sp, #0] @ archive lowpath bufsize
mov r0, #0x2
str r0, [sp, #4] @ file lowpath type
add r0, sp, #0x3c
str r0, [sp, #8] @ file lowpath bufptr*
mov r0, #0x14
str r0, [sp, #12] @ file lowpath bufsize
mov r0, #0x1
str r0, [sp, #16] @ openflags
add r0, sp, #0x50
str r0, [sp, #20] @ file out handle*
add r0, sp, #0x18 @ fsuser* handle
ldr r1, =0x2345678A @ archiveid
mov r2, #0x2 @ archive lowpath type
add r3, sp, #0x2c @ archive lowpath bufptr
bl fsuser_openfiledirectly
mov r4, r0
cmp r4, #0
bne load_romfs_finish

add r0, sp, #0x50
add r1, sp, #0x54
bl fsfile_getsize
mov r4, r0
cmp r4, #0
bne load_romfs_finishfile

ldr r2, =0xfff
ldr r3, [sp, #0x54] @ size
add r3, r3, r2
bic r3, r3, r2
mov r1, #0 @ addr
ldr r0, =0x10003 @ operation
mov r4, #3 @ permissions
mov r2, #0 @ addr1
blx svcControlMemory
mov r4, r0
cmp r4, #0
bne load_romfs_finishfile
str r1, [sp, #0x60]

mov r2, r1 @ buf*
add r0, sp, #0x5c
str r0, [sp, #0] @ u32* total transfersize
add r0, sp, #0x50 @ filehandle*
mov r1, #0 @ filepos
ldr r3, [sp, #0x54] @ size
bl fsfile_read
mov r4, r0
cmp r4, #0
bne load_romfs_finishfile

ldr r2, [sp, #0x54] @ Validate that the read-size matches the specified size.
ldr r3, [sp, #0x5c]
cmp r2, r3
beq load_romfs_finishfile
mov r4, #0
mvn r4, r4

load_romfs_finishfile:
add r0, sp, #0x50
bl fsfile_close

ldr r0, [sp, #0x50]
blx svcCloseHandle

load_romfs_finish:
ldr r0, [sp, #0x18]
blx svcCloseHandle

cmp r4, #0
bne load_romfs_end

ldr r1, [sp, #0x60]
ldr r2, [sp, #0x74]
str r1, [r2] @ Write the bufptr to the output.
ldr r3, [sp, #0x54]
ldr r2, [sp, #0x78]
str r3, [r2] @ Write the size to the output.

load_romfs_end:
cmp r4, #0
beq load_romfs_exit

ldr r0, [sp, #0x60]
ldr r1, [sp, #0x54]

ldr r2, =0xfff
add r1, r1, r2
bic r1, r1, r2
bl freemem

load_romfs_exit:
mov r0, r4
add sp, sp, #0x64
pop {r4, r5, r6, pc}
.pool

read_romfs_file: @ r0 = programID-low, r1 = programID-high, r2 = mediatype, r3 = ncch contentindex, sp0 = utf16 filename, sp4 = filename char len, sp8 = outbuf*, sp12 = exact_size.
push {r4, r5, r6, lr}
sub sp, sp, #0x14

add r4, sp, #0x8
str r4, [sp, #0x0]
add r4, sp, #0xc
str r4, [sp, #0x4]
bl load_romfs
str r0, [sp, #0x10]
cmp r0, #0
bne read_romfs_file_end

ldr r0, [sp, #0x8]
ldr r1, [sp, #0xc]

mov r2, #1
mvn r2, r2
str r2, [sp, #0x10]
ldr r2, [r0, #0x1c] @ "File Metadata Table Offset"
cmp r2, r1
bcs read_romfs_file_end @ The above offset must be <imagesize.
ldr r3, [r0, #0x20] @ "File Metadata Table Size"
cmp r3, r1
bhi read_romfs_file_end @ The above size must be <=imagesize.
add r3, r3, r2
cmp r3, r1
bhi read_romfs_file_end @ The above offset+size must be <=imagesize.
cmp r2, r3
bcs read_romfs_file_end @ Check for integer overflow.
ldr r3, [r0, #0x20]
add r2, r2, r0
mov r4, r2

read_romfs_file_entfile_lp:
ldr r5, [r4, #0x1c]
ldr r6, [sp, #0x28]
cmp r5, r6
bne read_romfs_file_entfile_lpnext

mov r0, r4
add r0, r0, #0x20
ldr r1, [sp, #0x24]
mov r3, #0

read_romfs_file_entfile_lp_filenamelp:
ldrh r5, [r0, r3]
ldrh r6, [r1, r3]
cmp r5, r6
bne read_romfs_file_entfile_lpnext
add r3, r3, #0x2
ldr r5, [sp, #0x28]
cmp r3, r5
bne read_romfs_file_entfile_lp_filenamelp
b read_romfs_file_entfile_lpfinish

read_romfs_file_entfile_lpnext:
ldr r5, [r4, #0x4]
mov r6, #0
mvn r6, r6
cmp r5, r6
beq read_romfs_file_entfile_lpend
ldr r0, [sp, #0x8]
ldr r3, [r0, #0x20]
cmp r5, r3
bcs read_romfs_file_entfile_lpend
mov r4, r2
add r4, r4, r5
b read_romfs_file_entfile_lp

read_romfs_file_entfile_lpend:
mov r2, #2
mvn r2, r2
str r2, [sp, #0x10]
b read_romfs_file_exit

read_romfs_file_entfile_lpfinish:
ldr r0, [sp, #0x8]
ldr r1, [sp, #0xc]

ldr r2, [r0, #0x24] @ "File Data Offset"

mov r6, #3
mvn r6, r6
str r6, [sp, #0x10]
ldr r0, [r4, #0x8]
add r0, r0, r2
cmp r0, r1
bhi read_romfs_file_exit @ fileoffset+filedatastart must be <=imagesize.
cmp r2, r0
bhi read_romfs_file_exit @ Check for integer overflow.

ldr r1, [r4, #0x10]

mov r3, #4
mvn r3, r3
str r3, [sp, #0x10]
ldr r3, [sp, #0x30] @ Filesize must match the input size.
cmp r1, r3
bne read_romfs_file_exit

ldr r1, [sp, #0x8]
add r0, r0, r1 @ r0 = src data in romfs image.
ldr r1, [sp, #0x2c] @ r1 = dst buf
mov r2, #0

read_romfs_file_datacpy:
ldrb r4, [r0, r2]
strb r4, [r1, r2]
add r2, r2, #1
cmp r2, r3
blt read_romfs_file_datacpy

mov r0, #0
str r0, [sp, #0x10]

read_romfs_file_exit:
ldr r0, [sp, #0x8]
ldr r1, [sp, #0xc]
ldr r2, =0xfff
add r1, r1, r2
bic r1, r1, r2
bl freemem

read_romfs_file_end:
ldr r0, [sp, #0x10]
add sp, sp, #0x14
pop {r4, r5, r6, pc}
.pool

load_systemversion: @ r0 = outurl*, r1 = new3ds_flag.
push {r0, r4, r5, r6, lr}
sub sp, sp, #0x30

mov r2, #29
lsl r1, r1, r2
mov r5, r1

ldr r2, =0x444c4f//"OLD"
cmp r1, #0
beq load_systemversion_getregioninfo
ldr r2, =0x57454e//"NEW"

@ Get region-specific info.
load_systemversion_getregioninfo:
str r2, [sp, #0x2c]
bl getregion
add r1, sp, #0x20 @ output structure: +0 = NVer tidlow, +4 = CVer tidlow, +8 = regionid string(as a word, not ptr).
blx getregion_entrydata

adr r4, versionbin_filename @ Load NVer.
str r4, [sp, #0x0]
mov r4, #0x16
str r4, [sp, #0x4]
add r4, sp, #0x10
str r4, [sp, #0x8]
mov r4, #0x8
str r4, [sp, #0xc]
ldr r0, [sp, #0x20]
orr r0, r0, r5
ldr r1, =0x000400DB
mov r2, #0
mov r3, #0
bl read_romfs_file
cmp r0, #0
bne load_systemversion_exit

adr r4, versionbin_filename @ Load CVer.
str r4, [sp, #0x0]
mov r4, #0x16
str r4, [sp, #0x4]
add r4, sp, #0x18
str r4, [sp, #0x8]
mov r4, #0x8
str r4, [sp, #0xc]
ldr r0, [sp, #0x24]
ldr r1, =0x000400DB
mov r2, #0
mov r3, #0
bl read_romfs_file
cmp r0, #0
bne load_systemversion_exit

blx getaddr_payloadurl_formatstr
mov r2, r0
ldr r0, [sp, #0x30]
mov r1, #0x80
sub r1, r1, #0x1
mov r3, sp
ldrb r3, [r3, #0x1a]
str r3, [sp, #0]
mov r3, sp
ldrb r3, [r3, #0x19]
str r3, [sp, #4]
mov r3, sp
ldrb r3, [r3, #0x18]
str r3, [sp, #8]
mov r3, sp
ldrb r3, [r3, #0x12]
str r3, [sp, #12]
add r3, sp, #0x28
str r3, [sp, #16]
add r3, sp, #0x2c
ldr r4, [r7, #0x68]
blx r4 @ snprintf, for the URL.
mov r0, #0

load_systemversion_exit:
add sp, sp, #0x30
add sp, sp, #4
pop {r4, r5, r6, pc}
.pool

http_do_request: @ r0 = output, r1 = url, r2 = flag, r3 = u32* outsize.
push {r4, r5, r6, lr}
sub sp, sp, #0x5c
mov r5, r0

str r1, [sp, #0x50]
str r2, [sp, #0x54]
str r3, [sp, #0x58]

add r0, sp, #24
mov r3, #0
str r3, [r0]
add r1, sp, #8
ldr r3, =0x70747468
str r3, [r1, #0]
ldr r3, =0x433a
str r3, [r1, #4]
mov r2, #6
mov r3, #0
ldr r4, [r7, #0x18]
blx r4 @ srv_GetServiceHandle
cmp r0, #0
beq http_do_request_getsecondservhandle
bl http_do_request_end

http_do_request_getsecondservhandle:
add r0, sp, #16
mov r3, #0
str r3, [r0]
add r1, sp, #8
mov r2, #6
mov r3, #0
ldr r4, [r7, #0x18]
blx r4 @ srv_GetServiceHandle
cmp r0, #0
bne http_do_request_exit0

mov r4, #0

add r0, sp, #24
bl HTTPC_Initialize
cmp r0, #0
bne http_do_request_exit0

ldr r2, [sp, #0x50] @ url
mov r3, #0

http_do_request_strlen: @ Get strlen for the url.
ldrb r0, [r2, r3]
add r3, r3, #1
cmp r0, #0
bne http_do_request_strlen
sub r3, r3, #1

add r0, sp, #24
add r1, sp, #20
bl HTTPC_CreateContext
cmp r0, #0
bne http_do_request_exit0

add r0, sp, #16
ldr r1, [sp, #20]
bl HTTPC_InitializeConnectionSession
cmp r0, #0
bne http_do_request_close

blx getaddr_httphdrstrs_useragent @ Set the http User-Agent.
str r2, [sp, #0]
str r3, [sp, #4]
mov r2, r0
mov r3, r1

add r0, sp, #16
ldr r1, [sp, #20]
bl HTTPC_AddRequestHeaderField @ r0=handle*, r1=ctxhandle, r2=headername*, r3=headernamesize, sp0=valuebuf*, sp4=valuebufsize
cmp r0, #0
bne http_do_request_close

add r0, sp, #16
ldr r1, [sp, #20]
bl HTTPC_BeginRequest
cmp r0, #0
bne http_do_request_close

ldr r0, [sp, #0x54]
cmp r0, #0
bne http_do_request_recvdata

str r5, [sp, #0]
mov r3, #0x80
str r3, [sp, #4]
mov r3, #0
str r3, [sp, #8]
blx getaddr_httphdr_locationstr
mov r2, r0
mov r3, #9
add r0, sp, #16
ldr r1, [sp, #20]
bl HTTPC_GetResponseHeader @ r0=handle*, r1=ctxhandle, r2=headername*, r3=headernamesize, sp0=outvaluebuf*, sp4=outmaxsize, sp8=u32* actual value stringlen.
b http_do_request_close

http_do_request_recvdata:
add r0, sp, #16 @ Verify that the status-code is 200(and also so that it won't continue until the http response was actually received).
ldr r1, [sp, #20]
add r2, sp, #0
bl HTTPC_GetResponseStatusCode @ r0=handle*, r1=ctxhandle*, r2=u32* out
cmp r0, #0
bne http_do_request_close
ldr r0, [sp, #0]
cmp r0, #200
bne http_do_request_close

add r0, sp, #16
ldr r1, [sp, #20]
mov r2, #0
add r3, sp, #0
bl HTTPC_GetDownloadSizeState @ r0=handle*, r1=ctxhandle*, r2=u32* downloadedsize, r3=u32* contentsize
cmp r0, #0
bne http_do_request_close

ldr r0, [sp, #0]
ldr r3, [sp, #0x58]
str r0, [r3]
bl calcverify_payload_size
cmp r0, #0
blt http_do_request_close
mov r3, r0

mov r1, #0 @ addr
ldr r0, =0x10003 @ operation
mov r4, #3 @ permissions
mov r2, #0 @ addr1
blx svcControlMemory
ldr r3, =0x74747474
blx checkerror_triggercrash @ Trigger crash on memalloc fail.
str r1, [r5]
mov r2, r1

add r0, sp, #16
ldr r1, [sp, #20]
ldr r3, [sp, #0]
bl HTTPC_ReceiveData

http_do_request_close:
mov r5, r0
add r0, sp, #16
ldr r1, [sp, #20]
bl HTTPC_CloseContext
cmp r0, #0
bne http_do_request_end
mov r0, r5

http_do_request_exit0:
mov r5, r0
ldr r0, [sp, #24]
blx svcCloseHandle

http_do_request_exit1:
ldr r0, [sp, #16]
blx svcCloseHandle

mov r0, r5

http_do_request_end:
add sp, sp, #0x5c
pop {r4, r5, r6, pc}
.pool

http_download_payload: @ r0 = ptr where the payload allocbuf addr will be written, r1 = u32* payloadsize, r2 = new3ds_flag
push {r4, r5, r6, lr}
sub sp, sp, #0xd0
mov r5, r0
mov r6, r1

add r0, sp, #0x50
mov r1, r2
bl load_systemversion
cmp r0, #0
bne http_download_payload_end

@ Get the actual payload URL via the Location header with the initial HTTP request.
add r0, sp, #0x50
add r1, sp, #0x50
mov r2, #0
mov r3, #0
bl http_do_request @ r0 = output, r1 = url, r2 = flag.
cmp r0, #0
bne http_download_payload_end

@ Actual payload download.
mov r0, r5
add r1, sp, #0x50
mov r2, #1
mov r3, r6
bl http_do_request

http_download_payload_end:
add sp, sp, #0xd0
pop {r4, r5, r6, pc}
.pool

getregion: @ Returns region u8.
push {lr}
sub sp, sp, #16

ldr r3, =0x3a676663 @ "cfg:u"
str r3, [sp, #8]
mov r3, #0x75
str r3, [sp, #12]

add r0, sp, #0 @ Out handle
add r1, sp, #8
mov r2, #5
mov r3, #0
ldr r4, [r7, #0x18]
blx r4 @ srv_GetServiceHandle
ldr r3, =0x4e4e4e4e
blx checkerror_triggercrash

add r0, sp, #0 @ cfg handle
add r1, sp, #4 @ u8* out
mov r2, #0
str r2, [r1]
bl cfg_getregion
ldr r3, =0x4f4f4f4f
blx checkerror_triggercrash

ldr r0, [sp, #0]
blx svcCloseHandle

mov r3, sp
ldrb r3, [r3, #4]
cmp r3, #7
blt getregion_end
ldr r3, =0x49494949
mov r0, #0
mvn r0, r0
blx checkerror_triggercrash

getregion_end:
mov r0, r3
add sp, sp, #16
pop {pc}
.pool

cfg_getregion: @ inr0=cfg handle*, inr1=u8* out
push {r0, r1, r2, r3, r4, r5, lr}
blx get_cmdbufptr
mov r4, r0

ldr r0, [sp, #0]

ldr r5, =0x00020000
str r5, [r4, #0]
ldr r0, [r0]
blx svcSendSyncRequest
cmp r0, #0
bne cfg_getregion_end
ldr r0, [r4, #4]
cmp r0, #0
bne cfg_getregion_end

ldr r2, [sp, #4]
ldrb r1, [r4, #8]
strb r1, [r2]

cfg_getregion_end:
add sp, sp, #16
pop {r4, r5, pc}
.pool

.arm

get_cmdbufptr:
mrc 15, 0, r0, cr13, cr0, 3
add r0, r0, #0x80
bx lr

svcControlMemory:
svc 0x01
bx lr

svcExitThread:
svc 0x09
b .

svcSleepThread_1second:
ldr r0, =1000000000
mov r1, #0

svcSleepThread:
svc 0x0a
bx lr
.pool

svcCloseHandle:
svc 0x23
bx lr

svcSendSyncRequest:
svc 0x32
bx lr

checkerror_triggercrash:
cmp r0, #0
bxeq lr
str r0, [r3]
b .

parse_branch: @ r0 = addr of branch instruction, r1 = branch instruction u32 value
cmp r1, #0
ldreq r1, [r0]
lsl r1, r1, #8
lsr r1, r1, #8
tst r1, #0x800000
moveq r2, #0
ldrne r2, =0xff000000
orr r2, r2, r1
lsl r2, r2, #2
add r0, r0, #8
add r0, r0, r2
bx lr
.pool

getaddr_sdpayload_path:
adr r0, sdpayload_path
bx lr

getregion_entrydata: @ r0 = output value from getregion(), r1 = output structure: +0 = NVer tidlow, +4 = CVer tidlow, +8 = regionid string.
mov r3, #2
lsl r0, r0, r3

adr r2, NVer_tidlow_regionarray
ldr r2, [r2, r0]
str r2, [r1, #0]

adr r2, CVer_tidlow_regionarray
ldr r2, [r2, r0]
str r2, [r1, #4]

adr r2, regionids_array
ldr r2, [r2, r0]
str r2, [r1, #8]
bx lr

getaddr_payloadurl_formatstr:
adr r0, payloadurl_formatstr
bx lr

getaddr_httphdr_locationstr:
adr r0, httphdr_locationstr
bx lr

getaddr_httphdrstrs_useragent:
adr r0, httphdr_useragentstr
mov r1, #0xb
adr r2, httphdr_useragentvaluestr
mov r3, #0x25
bx lr
.pool

sdpayload_path:
.string16 "sdmc:/browserhax_hblauncher_ropbin_payload.bin"

.align 2

versionbin_filename:
.string16 "version.bin"

NVer_tidlow_regionarray:
.word 0x00016202 @ JPN
.word 0x00016302 @ USA
.word 0x00016102 @ EUR
.word 0x00016202 @ "AUS"
.word 0x00016402 @ CHN
.word 0x00016502 @ KOR
.word 0x00016602 @ TWN

CVer_tidlow_regionarray:
.word 0x00017202 @ JPN
.word 0x00017302 @ USA
.word 0x00017102 @ EUR
.word 0x00017202 @ "AUS"
.word 0x00017402 @ CHN
.word 0x00017502 @ KOR
.word 0x00017602 @ TWN

regionids_array:
.string "JPN" @ JPN
.string "USA" @ USA
.string "EUR" @ EUR
.string "JPN" @ "AUS"
.string "CHN" @ CHN
.string "KOR" @ KOR
.string "TWN" @ TWN

.align 2

payloadurl_formatstr:
.string "http://smea.mtheall.com/get_ropbin_payload.php?version=%s-%d-%d-%d-%d-%s" //Sample URL: http://smea.mtheall.com/get_payload.php?version=NEW-10-1-0-27-JPN
payloadurl_formatstr_end:
.align 2

httphdr_locationstr:
.string "Location"
.align 2

httphdr_useragentstr:
.string "User-Agent"
.align 2

httphdr_useragentvaluestr:
.string "3dsbrowserhax_hblauncher_loader/v1.2"
.align 2

getaddrs_menustub:
adr r0, menustub_start
b getaddrs_menustub_end

.align 2

menustub_start:
add r1, pc, #1
bx r1
.thumb

@ Wait for spider to terminate.
ldr r0, =3000000000
mov r1, #0
blx menustub_svcSleepThread

@ Allocate linearmem with the same total size as Home Menu when it's fully loaded. Since the kernel will clear all of this during allocation, there's no need to clear the hblauncher parameter block contained within this memory anyway.
menustub_memalloc:
ldr r3, =(0x25652000-0x24352000) @ size
mov r1, #0 @ addr
ldr r0, =0x10003 @ operation
mov r4, #3 @ permissions
mov r2, #0 @ addr1
blx menustub_svcControlMemory
cmp r0, #0
bne menustub_memalloc @ Sometimes spider doesn't always terminate by the time the above sleep code finishes, so keep trying to alloc memory until it's successful.

@ The constants below for auto-locating are "obfuscated" in order to avoid this code triggering on this menustub data in .text.

@ Auto-locate the gsp_initialize function.
ldr r0, =(~0x3a707367)
ldr r1, =(~0x7570473a)
mvn r0, r0
mvn r1, r1
str r0, [sp, #0x24]
str r1, [sp, #0x28]

mov r0, #0x10
str r0, [sp, #0]
ldr r0, =0xe8bd4070-1//pop {r4, r5, r6, lr}
add r0, r0, #1
str r0, [sp, #4]
add r0, sp, #0x24
mov r1, #8
ldr r2, =0xe92d4070-1//push {r4, r5, r6, lr}
add r2, r2, #1
ldr r3, =0x80000004
bl menustub_locateservinitcode

blx r0//gsp_initialize

add r0, sp, #0x10 @ Auto-locate gxcmd4.
ldr r1, =0xe92d43f0-1//push {r4, r5, r6, r7, r8, r9, lr}
add r1, r1, #1
ldr r2, =0xe3a0c004-1//mov ip, #4
add r2, r2, #1
ldr r3, =0xe58d901c-1//str r9, [sp, #28]
add r3, r3, #1
str r2, [r0, #0]
str r3, [r0, #4]
bl menustub_locatecode
mov r7, r0

@ Copy the menuropbin data from VRAM to the homemenu linearmem, via the GPU.
ldr r0, =0x1f500000 @ src
ldr r1, =0x35040000 @ dst
ldr r2, =0x10000 @ size
mov r3, #0
str r3, [sp, #0x0]
str r3, [sp, #0x4]
str r3, [sp, #0x8]
mov r3, #0x8
str r3, [sp, #0xc]
blx r7//gxcmd4

ldr r0, =1000000000 @ Wait for the above copy to finish.
mov r1, #0
blx menustub_svcSleepThread

@ Auto-locate the amsys_initialize function.
ldr r0, =(~0x733a6d61)
ldr r1, =(~0x7379)
mvn r0, r0
mvn r1, r1
str r0, [sp, #0x24]
str r1, [sp, #0x28]

add r0, sp, #0x24
mov r1, #7
ldr r2, =0xe92d4010-1
add r2, r2, #1
mov r3, #0
str r3, [sp, #0]
str r3, [sp, #4]
bl menustub_locateservinitcode

blx r0//amsys_initialize

@ No need to initialize the "ir:rst" handle since that's left at value 0x0 when homemenu is properly running on Old3DS anyway.

@ Auto-locate the aptipc_Initialize function, and load the APT handle address from the function's .pool too.
add r0, sp, #0x10
ldr r1, =0xe92d4070-1//push {r4, r5, r6, lr}
add r1, r1, #1
ldr r2, =0xe8bd8070-1 //pop {r4, r5, r6, pc}
add r2, r2, #1
ldr r3, =0x00020080-1
add r3, r3, #1
str r2, [r0, #0]
str r3, [r0, #4]
bl menustub_locatecode

str r0, [sp, #0x20]
ldr r2, [r1, #0x8]
str r2, [sp, #0x18] @ APT handle*

add r0, sp, #0x10 @ Auto-locate APT_GetServHandle.
ldr r1, =0xe92d41f0-1//push {r4, r5, r6, r7, r8, lr}
add r1, r1, #1
ldr r2, =0xe0a0cff9-1
add r2, r2, #1
ldr r3, [sp, #0x18]
str r2, [r0, #0]
str r3, [r0, #4]
bl menustub_locatecode
mov r3, r0

sub r1, r1, #4
ldr r1, [r1]

@ Force the homemenu APT_GetServHandle code to use APT:S.
adr r0, menustub_apts_servicestr
str r0, [r1, #8]
@ Do APT init for Home Menu.
blx r3//APT_GetServHandle

ldr r0, =0x101
ldr r1, =0x20000002
mov r2, sp
mov r3, sp
ldr r7, [sp, #0x20]
blx r7//aptipc_Initialize

add r0, sp, #16 @ Auto-locate aptipc_Enable.
ldr r1, =0xe92d4010-1//push {r4, lr}
add r1, r1, #1
ldr r2, =0x00030040-1
add r2, r2, #1
ldr r3, [sp, #0x18]
str r2, [r0, #0]
str r3, [r0, #4]
bl menustub_locatecode
mov r3, r0

ldr r0, =0x20000002
blx r3//aptipc_Enable

add r0, sp, #0x10 @ Auto-locate aptipc_ReceiveParameter.
ldr r1, =0xe92d5ff0-1
add r1, r1, #1
ldr r2, =0x000d0080-1
add r2, r2, #1
str r2, [r0, #0]
bl menustub_locatecode
mov r7, r0

@ Recv the param sent by NS during "LibraryApplet" startup.
add r0, sp, #0x1c
ldr r1, =0x101
mov r2, r0
mov r3, #0
str r3, [sp, #0x0]
str r0, [sp, #0x4]
str r0, [sp, #0x8]
blx r7 @ aptipc_ReceiveParameter inr0=u32* out appid inr1=u32 input appid inr2=u32* out signaltype inr3=buf insp0=size insp4=u32* out actual parambuf size insp8=outhandle*

ldr r5, [sp, #0x18] @ Close the APT handle.
ldr r0, [r5]
blx menustub_svcCloseHandle
mov r1, #0
str r1, [r5]

blx menustub_runropbin

b .
.pool

@ r0 = u32* buffer for data at the end of the function to search for, size is hard-coded for 2 words. r1 = wordvalue to search for going backwards from the previously located data, for the start address of the function.
@ This returns the address of the located function in r0, and the address of the first word in the input buffer for the function in .text.
menustub_locatecode:
push {r4, r5, lr}
mov r4, r2
mov r5, #0
cmp r0, #0
beq menustub_locatecode_l1
ldr r4, =0x00100000

menustub_locatecode_l0:
ldr r2, [r4]
add r4, r4, #4
ldr r3, [r0, #0]
cmp r2, r3
bne menustub_locatecode_l0
ldr r2, [r4]
ldr r3, [r0, #4]
cmp r2, r3
bne menustub_locatecode_l0
sub r4, r4, #4
mov r5, r4

menustub_locatecode_l1:
ldr r2, [r4]
sub r4, r4, #4
cmp r2, r1
bne menustub_locatecode_l1
add r0, r4, #4

mov r1, r5
pop {r4, r5, pc}
.pool

menustub_locateservinitcode: @ r0 = servicenamestr*, r1 = compare-byte-len, r2 = r1 value to pass to menustub_locatecode(). r3 = <see below when this has bit31 set>. The rest only matter when r3 bit31 is set: sp0 = when a matching value is found in .pool where sp0 is non-zero, subtract the current address by this value and compare with the word loaded from there with the data from sp4. sp4 = see sp0 info.
@ When inr3 bit31 is set, this code will then do the following with bit31 cleared: after locating the address of the service-str, it will then search for a ptr for this in memory. Once found, the current address is subtracted by the masked inr3 value, then it will continue to search for the target function's .pool with this new address.
push {r4, r5, r6, lr}
sub sp, sp, #4
mov r4, r0
mov r5, r1
mov r6, r2
str r3, [sp, #0]

@ Locate the specified string in the homemenu .(ro)data.

ldr r0, =0x00100000
mov r1, #0
menustub_locateservinitcode_l0:
ldrb r2, [r0, r1]
ldrb r3, [r4, r1]
cmp r2, r3
bne menustub_locateservinitcode_lpnext
add r1, r1, #1
cmp r1, r5
bge menustub_locateservinitcode_lpfinish
b menustub_locateservinitcode_l0

menustub_locateservinitcode_lpnext:
mov r1, #0
add r0, r0, #1
b menustub_locateservinitcode_l0

menustub_locateservinitcode_lpfinish: @ At this point r0 is the address of the string mentioned above.
ldr r3, [sp, #0]
cmp r3, #0
bge menustub_locateservinitcode_searchpool @ Check for bit31.
mov r1, #1
lsl r3, r3, r1
lsr r3, r3, r1

ldr r1, =0x00100000 @ Locate the base address where there's a ptr to the service-str.
menustub_locateservinitcode_l1:
ldr r2, [r1]
add r1, r1, #4
cmp r2, r0
bne menustub_locateservinitcode_l1
sub r1, r1, #4
sub r0, r1, r3

menustub_locateservinitcode_searchpool:
ldr r1, =0x00100000 @ Locate the .pool of the target function.
menustub_locateservinitcode_l2:
ldr r2, [r1]
add r1, r1, #4
cmp r2, r0
bne menustub_locateservinitcode_l2
sub r1, r1, #4

ldr r3, [sp, #20]
cmp r3, #0
beq menustub_locateservinitcode_searchpool_finish
mov r5, r1
sub r5, r5, r3
ldr r2, [r5]
ldr r3, [sp, #24]
add r1, r1, #4
cmp r2, r3
bne menustub_locateservinitcode_l2

sub r1, r1, #4

menustub_locateservinitcode_searchpool_finish:
mov r2, r1
mov r0, #0
mov r1, r6
bl menustub_locatecode
add sp, sp, #4
pop {r4, r5, r6, pc}
.pool

.arm
menustub_svcSleepThread:
svc 0x0a
bx lr

menustub_svcControlMemory:
svc 0x01
bx lr

menustub_svcCloseHandle:
svc 0x23
bx lr

menustub_runropbin:
ldr sp, =0x35040000 @ Start running the menuropbin.
pop {pc}
.pool

menustub_apts_servicestr:
.string "APT:S"
.align 2

.space (menustub_start + 0x320) - .
menustub_end:
.word 0

getaddrs_menustub_end:
adr r1, menustub_end
bx lr

