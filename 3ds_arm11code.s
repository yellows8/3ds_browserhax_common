.section .init
.global _start
.arm

//This is a loader for hblauncher, currently only for spiderhax(Old3DS system web-browser). Right now this is hard-coded for system-version v10.1 USA.
//Also note that APT would be broken even worse than with other hax which boot hblauncher, with the spider version of this.

_start:
mov r7, r0
ldr sp, =(0x10000000-0x1000)

add r1, pc, #1
bx r1
.thumb

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

@ Allocate linearmem for the hblauncher payload.
ldr r3, =0x1a000 @ size
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

ldr r0, =0x1d6c @ src, this offset is hard-coded for "otherapp/POST5_U_21504_usa_9221.bin" for now.
ldr r1, =0xa000 @ dst0
ldr r2, =(0xa000+0x8000) @ dst1
add r0, r0, r5
add r1, r1, r5
add r2, r2, r5
mov r3, #0
ldr r6, =0x8000

setup_initial_menuropdata: @ Copy the 0x8000-bytes from src to dst0 and dst1.
ldr r4, [r0, r3]
str r4, [r1, r3]
str r4, [r2, r3]
add r3, r3, #4
cmp r3, r6
blt setup_initial_menuropdata

mov r0, r1
mov r1, #1
bl patchPayload
ldr r3, =0xa0a0a0a0
blx checkerror_triggercrash @ Trigger crash on payload-patching fail.

ldr r0, =0xa000
add r0, r0, r5 @ Flush dcache for the menuropbin data.
ldr r1, =0x10000
ldr r3, [r7, #0x20]
blx r3

ldr r0, =0xa000
add r0, r0, r5
ldr r1, =0x1f500000
ldr r2, =0x10000
bl gxcmd4 @ Copy the menuropbin data into VRAM, which will be loaded by the below homemenu code later.

mov r0, r5
ldr r1, =0x1a000
bl freemem

ldr r0, =0x3a545041 @ Get APT:U handle, @ sp+0.
str r0, [sp, #4]
mov r0, #0x55
str r0, [sp, #8]

add r0, sp, #12
add r1, sp, #4
mov r2, #5
mov r3, #0
ldr r4, [r7, #0x18]
blx r4 @ srv_GetServiceHandle

ldr r0, =0x09a00000-0xd00000
ldr r1, =(0xd00000)
bl freemem

/*ldr r0, =0x18000000+0x352000//0x18b52000-0xa00000
ldr r1, =0x18b52000-0x18352000//(0xa00000)
bl freemem*/

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

//ldr r0, =0x18600000
//ldr r0, =0x1f000000
ldr r0, =0x1000
add r0, r0, r7
ldr r1, =(0x6500000+0x14000000+0x1a40)//(0x14000000+0x4b00000-0x50000)
ldr r2, =0x100//0x2000//0x200000//+0x50000
bl gxcmd4 @ Overwrite homemenu main(), starting with the code following the nss_initialize() call.

mov r0, #0 @ gsp init/shutdown, r0=0 is for shutdown.
ldr r3, =0x1d13e0
blx r3

/*ldr r0, =0x08040000
ldr r1, =0x10000
bl freemem

ldr r3, =0x10000 @ size
mov r1, #0 @ addr
ldr r0, =0x10003 @ operation
mov r4, #3 @ permissions
mov r2, #0 @ addr1
svc 0x01
ldr r3, =0x40404040//(0x10000000-4)
str r1, [r3]*/

/*ldr r0, =0x18600000
//ldr r0, =0x1f000000
ldr r1, =(0x14000000+0x4b00000-0x50000)
ldr r2, =0x100000+0x50000
//bl gxcmd4
*/
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

blx svcSleepThread_1second

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

.type loadsd_payload, %function
loadsd_payload: @ r0 = load addr
push {r4, lr}
sub sp, sp, #0x20
mov r4, r0

add r0, sp, #12 @ ctx

mov r1, #0
mov r2, r1
mov r3, #0x14

loadsd_payload_ctxclr:
str r1, [r0, r2]
add r2, r2, #4
cmp r2, r3
blt loadsd_payload_ctxclr

adr r1, sdpayload_path @ UTF-16 filepath
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
pop {r4, pc}
.pool

patchPayload: @ r0 = payloadbuf, r1 = targetProcessIndex. This is somewhat based on code from hblauncher with the same function name(minus the code for locating the dlplay memorymap structure).
push {r4, r5, r6, r7, lr}
sub sp, sp, #4

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
ldr r6, =(0x30000000+0x04000000)//Hard-coded for Old3DS atm.
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
add sp, sp, #4
pop {r4, r5, r6, r7, pc}
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

getaddrs_menustub:
adr r0, menustub_start
adr r1, menustub_end
bx lr

menustub_start:
add r1, pc, #1
bx r1
.thumb

@ Wait for spider to terminate.
ldr r0, =3000000000
mov r1, #0
blx menustub_svcSleepThread

/*ldr r0, =1000000000
mov r1, #0
blx menustub_svcSleepThread*/

@ Allocate linearmem with the same total size as Home Menu when it's fully loaded.
menustub_memalloc:
ldr r3, =(0x25652000-0x24352000) @ size
mov r1, #0 @ addr
ldr r0, =0x10003 @ operation
mov r4, #3 @ permissions
mov r2, #0 @ addr1
blx menustub_svcControlMemory
cmp r0, #0
bne menustub_memalloc @ Sometimes spider doesn't always terminate by the time the above sleep code finishes, so keep trying to alloc memory until it's successful.
/*ldr r3, =0x90909090
cmp r0, #0
strne r0, [r3] @ Trigger crash on memalloc fail.*/

ldr r3, =0x138e8c//gsp_initialize_wrap
blx r3

@ Copy the menuropbin data from VRAM to the homemenu linearmem, via the GPU.
ldr r0, =0x1f500000 @ src
ldr r1, =0x35040000 @ dst
ldr r2, =0x10000 @ size
mov r3, #0
str r3, [sp, #0]
str r3, [sp, #4]
str r3, [sp, #8]
mov r3, #0x8
str r3, [sp, #12]
ldr r4, =0x14b9cc//gxcmd4
blx r4

ldr r0, =1000000000 @ Wait for the above copy to finish.
mov r1, #0
blx menustub_svcSleepThread

ldr r3, =0x102850//fsuser_initialize
blx r3

ldr r3, =0x231084//amsys_initialize
blx r3

@ No need to initialize the "ir:rst" handle since that's left at value 0x0 when homemenu is properly running on Old3DS anyway.

ldr r0, =0x0032e9bc @ Set an APT flag used by the homemenu code to determine which APT service to use: 0 = APT:A, 1 = APT:U/APT:S. In .data this is initially 0, so if this isn't changed here that homemenu code will trigger a fatalerror due to srv_GetServiceHandle failing with APT:A.
mov r1, #1
strb r1, [r0]
ldr r1, =0x321daf @ Force the homemenu APT_GetServHandle code to try opening APT:S first.
str r1, [r0, #8]

/*ldr r0, =0x101
mov r1, #0
ldr r2, =0x5109d503
ldr r3, =0x107ba8
//ldr r3, =0x104f54//Supposed to be apt-init but no APT service cmds get used when this is called.
blx r3*/
//.word 0xffffffff
/*ldr r0, =3000000000
mov r1, #0
svc 0x0a @ Wait for APT thread to process stuff.*/

@ Do APT init for Home Menu.
ldr r3, =0x0107fbc//APT_GetServHandle
blx r3

ldr r1, =(0x0032de90+20) @ Init the appid used by the below code.
//ldr r1, =0x00340278
ldr r0, =0x101
str r0, [r1]

//ldr r0, =0x101
ldr r1, =0x20000002
mov r2, sp
mov r3, sp
ldr r4, =0x107e64//aptipc_Initialize
blx r4
/*ldr r3, =0xe0e0e0e0
blx menustub_checkerror_triggercrash*/

ldr r0, =0x20000002
ldr r3, =0x11100c//aptipc_finalize
blx r3
/*ldr r3, =0xf0f0f0f0
blx menustub_checkerror_triggercrash*/

ldr r3, =0x107c50//APT_CloseServHandle
blx r3

@ Recv the param sent by NS during "LibraryApplet" startup.
mov r0, #0
mov r1, r0
mov r2, r0
mov r3, r0
str r0, [sp, #0]
str r0, [sp, #4]
ldr r4, =0x139450 @ APT_ReceiveParameter inr0=u32* out appid inr1=u32* out signaltype inr2=buf inr3=bufsize insp0=u32* out actual parambuf size insp4=outhandle* (nullptrs are allowed)
blx r4

blx menustub_runropbin

b .
.pool

.arm
menustub_svcSleepThread:
svc 0x0a
bx lr

menustub_svcControlMemory:
svc 0x01
bx lr

/*menustub_checkerror_triggercrash:
cmp r0, #0
bxeq lr
str r0, [r3]
b .*/

menustub_runropbin:
ldr sp, =0x35040000 @ Start running the menuropbin.
pop {pc}
.pool

.space (menustub_start + 0x100) - .
menustub_end:
.word 0

sdpayload_path:
.string16 "sdmc:/browserhax_hblauncher_payload.bin"

