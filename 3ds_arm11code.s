.section .init
.global _start
.arm

//This is a loader for hblauncher, for the Old3DS/New3DS system web-browsers. For spiderhax(Old3DS system web-browser) this is hard-coded for system-version v10.1 USA atm.
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

@ Allocate linearmem for the hblauncher payload. The kernel clears this memory during allocation, therefore the below code will not clear this buffer.
menustubcpy_end:
ldr r3, =0x1b000 @ size
mov r1, #0 @ addr
ldr r0, =0x10003 @ operation
mov r4, #3 @ permissions
mov r2, #0 @ addr1
blx svcControlMemory
ldr r3, =0x70707070
blx checkerror_triggercrash @ Trigger crash on memalloc fail.
mov r5, r1

mov r0, r5
bl loadsd_payload
ldr r3, =0x80808080
blx checkerror_triggercrash @ Trigger crash on payload loading fail.

mov r0, r5 @ payloadbuf
ldr r1, =0xa000 @ payloadbufsize
add r2, sp, #20 @ output
bl locatepayload_data
ldr r3, =0x77777778
blx checkerror_triggercrash

ldr r0, [sp, #20] @ Src offset in the payload.
ldr r6, [sp, #24] @ Size of the menuropbin.

ldr r1, =0xa000 @ dst0
ldr r2, =(0xa000+0x8000) @ dst1
add r0, r0, r5
add r1, r1, r5
add r2, r2, r5
mov r3, #0

setup_initial_menuropdata: @ Copy the 0x8000-bytes from src to dst0 and dst1.
ldr r4, [r0, r3]
str r4, [r1, r3]
str r4, [r2, r3]
add r3, r3, #4
cmp r3, r6
blt setup_initial_menuropdata

mov r0, r1
mov r1, #1
ldrb r2, [sp, #16]
bl patchPayload
ldr r3, =0xa0a0a0a0
blx checkerror_triggercrash @ Trigger crash on payload-patching fail.

ldr r0, =0xa000
add r0, r0, r5 @ Flush dcache for the menuropbin data.
ldr r1, =0x10000
ldr r3, [r7, #0x20]
blx r3

@ Copy the menuropbin via the GPU.

ldrb r2, [sp, #16]
cmp r2, #0
beq menuropbin_vramcopy

ldr r0, =0xa000 @ New3DS
add r0, r0, r5
ldr r1, =0x38c40000
ldr r2, =0x10000
bl gxcmd4
blx svcSleepThread_1second

ldr r0, =0x1a000 @ Clear the hblauncher parameter block.
add r0, r0, r5
ldr r1, =0x38c40000 - 0x800*2
ldr r2, =0x800
bl gxcmd4
blx svcSleepThread_1second
b menuropbin_vramcopy_finish

menuropbin_vramcopy: @ Old3DS
ldr r0, =0xa000
add r0, r0, r5
ldr r1, =0x1f500000
ldr r2, =0x10000
bl gxcmd4 @ Copy the menuropbin data into VRAM, which will be loaded by the below homemenu code later.
blx svcSleepThread_1second

menuropbin_vramcopy_finish:
spiderheap_memfree_finish:
ldrb r2, [sp, #16]
cmp r2, #0
beq menutakeover_begin

ldr r0, [sp, #28] @ Src offset in the payload.
ldr r1, [sp, #32] @ Size of the loadropbin blob.
add r0, r0, r5
bl regular_menutakeover
ldr r3, =0xa4a4a4a4
blx checkerror_triggercrash
bl aptExit

mov r0, r5
ldr r1, =0x1b000
bl freemem

ldr r3, =0xa8a8a8a8
blx checkerror_triggercrash
b shutdown_gsp

menutakeover_begin:
mov r0, r5
ldr r1, =0x1b000
bl freemem

ldr r0, =0x09a00000-0xd00000 @ Free some of the spider regular-heap so that there's enough memory available to launch Home Menu.
ldr r1, =(0xd00000)
bl freemem

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

ldr r0, =(0x6500000+0x14000000+0x1000) @ .text+0x1000
ldr r5, =0x1f510000
ldr r6, =0x1f510000+0x5000-0x4
ldr r4, [r6]
mov r1, r5
ldr r2, =0x5000
bl gxcmd4 @ Copy 0x5000-bytes of Home Menu .text+0x1000 to VRAM+0x510000.

waitcodevramcpy_finish: @ Wait for the above copy to completely finish.
ldr r0, [r6]
cmp r0, r4
beq waitcodevramcpy_finish

@ Begin auto-locating the target code for homemenu takeover.
ldr r4, =0x00101000
mov r0, r4
mov r1, r5

ldr r2, =0xef000003 @ Locate the "svc 0x03" instruction, which is the function right before main().
_start_locatecode_l0:
ldr r3, [r1]
add r1, r1, #4
add r0, r0, #4
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

add r0, r0, #0x18 @ Get the address of function begin called with the bl-instruction @ +0x18 in the above function.
mov r1, r0
sub r1, r1, r4
add r1, r1, r5

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
ldr r1, =(0x6500000+0x14000000) @ .text+<above offset>
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
push {lr}
mov r3, r1 @ size
mov r1, r0 @ addr
mov r0, #1 @ operation
mov r4, #0 @ permissions
mov r2, #0 @ addr1
blx svcControlMemory
pop {pc}

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

.type loadsd_payload, %function
loadsd_payload: @ r0 = load addr
push {r4, r5, lr}
sub sp, sp, #0x20
mov r4, r0

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

ldr r3, [sp, #4] @ Filesize must be <=0xa000.
ldr r1, =0xa000
mov r2, #2
mvn r0, r2
cmp r3, r1
bgt loadsd_payload_end

@ Read the file with the above size into the input buffer.
add r0, sp, #12 @ ctx
add r1, sp, #0 @ u32* readcount
mov r2, r4
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
add sp, sp, #0x20
pop {r4, r5, pc}
.pool

@ This extracts info from the otherapp payload. Proper metadata/whatever for this stuff would be ideal, but it has to be done this way for now.
locatepayload_data: @ r0 = payloadbuf, r1 = size, r2 = u32* output
push {r4, r5, r6, lr}
mov r4, r0
mov r5, r1
mov r6, r2

mov r0, #0 @ Locate the otherapp-payload main() .pool(the code which runs under the actual "otherapp") via the 0x6e4c5f4e value.
ldr r1, =0x6e4c5f4e
locatepayload_data_lp:
ldr r2, [r4, r0]
cmp r1, r2
beq locatepayload_data_lpend

locatepayload_data_lpnext:
add r0, r0, #4
cmp r0, r5
blt locatepayload_data_lp
mov r0, #0
mvn r0, r0
b locatepayload_data_end

locatepayload_data_lpend: @ Locate the "b ." instruction at the end of main(), which is also right before the .pool.
ldr r1, =0xeafffffe
sub r0, r0, #4

locatepayload_data_lp2:
ldr r2, [r4, r0]
cmp r1, r2
beq locatepayload_data_lp2end

locatepayload_data_lp2next:
sub r0, r0, #4
cmp r0, #0
bgt locatepayload_data_lp2
mov r0, #1
mvn r0, r0
b locatepayload_data_end

locatepayload_data_lp2end:
add r0, r0, #4 @ r0 = offset for main() .pool. The below code assumes that the required values are always located at the same relative-offset in the .pool.

mov r1, r5
mov r2, r6
mov r3, r0
add r3, r3, r4
add r3, r3, #8
mov r0, r4
bl locatepayload_writeoutput @ Load the menuropbin offset/size + verify them, and write to the output.
cmp r0, #0
bne locatepayload_data_end

mov r0, #0 @ Locate the inject_payload() function .pool in the otherapp-payload(which actually runs under the "otherapp").
ldr r1, =0x00989680
ldr r3, =0xdeadcafe
locatepayload_data_lp3:
ldr r2, [r4, r0]
cmp r1, r2
bne locatepayload_data_lp3next
mov r2, r0
add r2, r2, r4
ldr r2, [r2, #0x10]
cmp r3, r2
beq locatepayload_data_lp3end

locatepayload_data_lp3next:
add r0, r0, #4
cmp r0, r5
blt locatepayload_data_lp3
mov r0, #7
mvn r0, r0
b locatepayload_data_end

locatepayload_data_lp3end:
add r0, r0, #4

mov r1, r5
mov r2, r6
add r2, r2, #8
mov r3, r0
add r3, r3, r4
mov r0, r4
bl locatepayload_writeoutput @ Load the loadropbin blob offset/size + verify them, and write to the output+8.
cmp r0, #0
bne locatepayload_data_end

mov r0, #0

locatepayload_data_end:
pop {r4, r5, r6, pc}
.pool

locatepayload_writeoutput: @ r0 = payloadbuf, r1 = payloadbufsize, r2 = u32* out. r3 = ptr to two words: +0 = <ptr to size in payload>, +4 = address of the binary.
push {r4, r5, r6, lr}
mov r4, r0
mov r5, r1
mov r6, r2

mov r1, r3
mov r2, r3
ldr r1, [r1, #0] @ ptr to size.
ldr r2, [r2, #4] @ address of the binary.

mov r0, #2
mvn r0, r0
ldr r3, =0x00101000
sub r2, r2, r3 @ r2 = offset of binary, which is written to *(inr2+0).
cmp r2, r5
bcs locatepayload_writeoutput_end @ The binary offset must be within the payloadbuf.
str r2, [r6, #0]

@ Write the size of the binary to *(inr2+4).
mov r0, #3
mvn r0, r0
sub r1, r1, r3
cmp r1, r5
bcs locatepayload_writeoutput_end @ The calculated offset in the payload must be within the input size.
mov r0, #4
mvn r0, r0
ldr r1, [r4, r1]
cmp r1, r5
bcs locatepayload_writeoutput_end @ The binary size must be within the payloadbuf.
str r1, [r6, #4]

mov r0, #5
mvn r0, r0
mov r3, r2
add r3, r3, r1
cmp r3, r5
bcs locatepayload_writeoutput_end @ binary_offset + binary_size must be within the payloadbuf.
mov r0, #6
mvn r0, r0
cmp r3, r2
bcc locatepayload_writeoutput_end @ Check for integer-overflow with the above add.

mov r0, #0

locatepayload_writeoutput_end:
pop {r4, r5, r6, pc}
.pool

patchPayload: @ r0 = menuropbin*, r1 = targetProcessIndex, r2 = new3ds_flag. This is somewhat based on code from hblauncher with the same function name(minus the code for locating the dlplay memorymap structure).
push {r4, r5, r6, r7, lr}
sub sp, sp, #8

cmp r2, #0
bne patchPayload_new3dsinit

ldr r4, =(0x30000000+0x04000000)//Old3DS
b patchPayload_init

patchPayload_new3dsinit:
ldr r4, =(0x30000000+0x07c00000)

patchPayload_init:
str r4, [sp, #4]

ldr r2, =(0x8000-4)
mov r3, #0

patchPayload_lp: @ Locate the memorymap structure for the dlplay app.
ldr r4, [r0, r3]
add r3, r3, #4
ldr r5, [r0, r3]

cmp r4, #4
bne patchPayload_lpnext
ldr r6, =0x193000
cmp r5, r6
bne patchPayload_lpnext

sub r3, r3, #4
b patchPayload_lpend

patchPayload_lpnext:
cmp r3, r2
blt patchPayload_lp

patchPayload_lpend:
cmp r2, r3
beq patchPayload_enderror

add r4, r0, r3

ldr r2, =(0x8000-0x40)
mov r3, #0

patchPayload_patchlp:
ldr r5, [r0, r3]

lsr r6, r5, #4 @ The loaded word value must be 0xBABE0001..0xBABE0007.
ldr r7, =0xBABE000
cmp r6, r7
bne patchPayload_patchlpnext
mov r6, #0xf
and r6, r6, r5
cmp r6, #0
beq patchPayload_patchlpnext
cmp r6, #7
bgt patchPayload_patchlpnext

cmp r6, #1
bne patchPayload_patchlp_l2
str r1, [r0, r3] @ targetProcessIndex
b patchPayload_patchlpnext

patchPayload_patchlp_l2:
cmp r6, #2
bne patchPayload_patchlp_l3
ldr r6, [sp, #4]
ldr r7, [r4, #0x10]
sub r6, r6, r7
str r6, [r0, r3] @ APP_START_LINEAR
b patchPayload_patchlpnext

patchPayload_patchlp_l3:
cmp r6, #3
bne patchPayload_patchlp_l4
ldr r7, [r4, #0x14]
str r7, [r0, r3] @ processHookAddress
b patchPayload_patchlpnext

patchPayload_patchlp_l4:
cmp r6, #4
bne patchPayload_patchlp_l5
ldr r7, [r4, #0x1c]
str r7, [r0, r3] @ TID-low
b patchPayload_patchlpnext

patchPayload_patchlp_l5:
cmp r6, #5
bne patchPayload_patchlp_l7
ldr r7, [r4, #0x20]
str r7, [r0, r3] @ TID-high
b patchPayload_patchlpnext

patchPayload_patchlp_l7:
cmp r6, #7
bne patchPayload_patchlp_l6
ldr r7, [r4, #0x18]
str r7, [r0, r3] @ processAppCodeAddress
b patchPayload_patchlpnext

patchPayload_patchlp_l6:
cmp r6, #6 @ memorymap
bne patchPayload_patchlpnext

ldr r6, [r4, #0] @ Calculate the memorymap structure size, and restrict the size if needed.
mov r5, #0xc
mul r6, r6, r5
add r6, r6, #0x30
ldr r5, =0x8000
cmp r6, r5
bcc patchPayload_memorymap_cpy_init
mov r6, r5

patchPayload_memorymap_cpy_init:
mov r5, #0
str r6, [sp, #0]

patchPayload_memorymap_cpy: @ Copy the memorymap structure to the current ropbin location.
ldr r7, [r4, r5]
mov r6, r3
add r6, r6, r5
str r7, [r0, r6]
add r5, r5, #4
ldr r6, [sp, #0]
cmp r5, r6
blt patchPayload_memorymap_cpy

patchPayload_patchlpnext:
add r3, r3, #4
cmp r3, r2
blt patchPayload_patchlp

b patchPayload_endsuccess

patchPayload_enderror:
mov r0, #0
mvn r0, r0
b patchPayload_end

patchPayload_endsuccess:
mov r0, #0

patchPayload_end:
add sp, sp, #8
pop {r4, r5, r6, r7, pc}
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

ldr r5, =0x37c00000

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

sdpayload_path:
.string16 "sdmc:/browserhax_hblauncher_payload.bin"

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

ldr r3, =0x138e8c//gsp_initialize_wrap
blx r3

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

ldr r0, =(~0x733a6d61) @ Locate the "am:sys" string in the homemenu .(ro)data.
ldr r1, =(~0x7379)
mvn r0, r0
mvn r1, r1
str r0, [sp, #0x24]
str r1, [sp, #0x28]

ldr r0, =0x00100000
add r4, sp, #0x24
mov r1, #0
menustub_amsysinitlocate_l0:
ldrb r2, [r0, r1]
ldrb r3, [r4, r1]
cmp r2, r3
bne menustub_amsysinitlocate_l0_lpnext
add r1, r1, #1
cmp r1, #7
bge menustub_amsysinitlocate_l0_lpfinish
b menustub_amsysinitlocate_l0

menustub_amsysinitlocate_l0_lpnext:
mov r1, #0
add r0, r0, #1
b menustub_amsysinitlocate_l0

menustub_amsysinitlocate_l0_lpfinish: @ At this point r0 is the address of the "am:sys" string mentioned above.

ldr r1, =0x00100000 @ Locate the .pool of the amsys_initialize function.
menustub_amsysinitlocate_l1:
ldr r2, [r1]
add r1, r1, #4
cmp r2, r0
bne menustub_amsysinitlocate_l1
sub r1, r1, #4

mov r2, r1
mov r0, #0
ldr r1, =0xe92d4010//push {r4, lr}
bl menustub_locatecode

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

