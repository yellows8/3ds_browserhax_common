.arm
.text
/*
Build with: arm-none-eabi-as -o webkitdebug.elf webkitdebug.s && arm-none-eabi-objcopy -O binary webkitdebug.elf webkitdebug.bin

0x0FFF8000 structure:
+0: Reserved.
+4: Code to jump to for executing the original webkit_free code. This should be 8-bytes following the "push" instruction.
+8: Base address for the memalloc area. The 0x1000-bytes before this should be unmapped.
+12: Size of the memalloc area.
+16: Address which will be used for the next memalloc.

The above structure must be initialized before any of this code is executed. The memalloc area *must* be located at an address higher than the normal webkit heap.
After initializing that^, the code called by wkc_malloc/wkc_free must be overwritten with code for jumping to the below code. This could be used with non-webkit heap as well with some adjustments.
For example, with this binary being stored at 0x00100000, you can write "0xe51ff004 0x00100000" for the above malloc code, and "0xe51ff004 0x00100004" for the above free code.

This was inspired by: https://developer.apple.com/library/mac/documentation/Performance/Conceptual/ManagingMemory/Articles/MallocDebug.html

NOTE: Originally each allocation had a page-guard before/after the allocated memory. This was disabled due to running out of memory.

This is used for overriding the memory allocation/free functions with the below code. Each allocation will use a dedicated set of memory page(s). Hence, for example, an allocation less than 0x100-bytes will result in 0x1000-bytes being allocated with svcControlMemory. Right before the returned buffer is a 12-byte chunk header. Prior to that is unmapped memory(page-guard), likewise for the end of the allocated buffer. This will never allocate memory at the same vaddr more than once.

This will trigger crashes when there's no more memory available in the memalloc area, or when svcControlMemory fails.

When using this with spider, patching the spider exheader so that memregion=APPLICATION and reslimit=0(APPLICATION) is highly recommended, since there's not much free memory available otherwise.

Hence, this can be used for detecting the following:
Use-after-free: Once memory is freed, that memory will never be mapped again at that vaddr. Hence, if any use-after-free memory r/w access occur, a crash would instantly trigger.
Out-of-bounds memory access / buffer overflow: There's a 0x1000-byte page-guard(unmapped memory) right before the chunk header located before each buffer, and at mappedmem+alignedpagesize. Hence, if any memory access goes out-of-bounds enough to access those guards, a crash will instantly trigger. If out-of-bounds memwrite corrupts the last word in the chunk header(wkc_malloc()-4) without accessing the page-guard, the memfree code below will trigger a crash once the memory is attempted to be freed. There's also a magicnum stored @ <actualbuffer_addr> + <actualbuffer_size>, the memfree code below will trigger a crash if this is corrupted.
Double-free / invalid memptr free: A crash will be triggered by the below memfree code if freeing memory with svcControlMemory fails.

TODO: Figure out some way to automatically set this up during browser boot, since doing it manually after startup will miss the allocations from browser startup.
Also, even after this is setup, it won't catch all memory allocation/freeing.
*/

_start:

webkitmalloc_jump:
b malloc

webkitfree_jump:
b wkc_free

webkitrealloc_jump:
b wkc_realloc

fastmalloc_reallocjump:
b fastmalloc_realloc

malloc:
mov r1, r0
add r1, r1, #16
ldr r2, =0xfff
add r1, r1, r2
bic r1, r1, r2 @ r1 = Total allocated aligned size with header.

push {r0, r1}

ldr r3, =0x0FFF8000
ldr r2, [r3, #8]
ldr r3, [r3, #12]
add r2, r2, r3 @ r2 = endaddr of our memalloc area.

ldr r3, =0x0FFF8000
ldr r3, [r3, #16]

push {r5}
//ldr r5, =0x1000
mov r5, r0
add r5, r5, r1 @ r5 = total_aligned_size with page-guard.
add r3, r3, r5 @ r3 = Endaddr of the memalloc including the page-guard.
pop {r5}

cmp r3, r2 @ Trigger a crash when there's no more memory available in our memalloc area.
ldrcs r4, =0xa4a4a4a4
strcs r3, [r4]

push {r4}
mov r0, #3 @ operation
mov r4, #3 @ permissions
mov r3, r1 @ size

ldr r1, =0x0FFF8000 @ addr0
ldr r1, [r1, #16]

mov r2, #0 @ addr1
svc 0x01
pop {r4}

cmp r0, #0 @ Trigger a crash when memalloc fails.
ldrne r3, =0x90909090
strne r0, [r3]

ldr r0, =0x0FFF8000
ldr r0, [r0, #16]

pop {r2, r3}
str r2, [r0, #0] @ Initialize the chunk header.
str r3, [r0, #4]
ldr r1, =0x42445457
str r1, [r0, #8] @ Store the magicnum at the end of the header to catch chunk corruption in the memfree code below(this is done because the only mapped memory is after this chunk, not before).

mov r1, r0
add r1, r1, #12
add r2, r2, r1
ldr r3, =0x40506073

malloc_meminit:
str r3, [r1], #4
cmp r1, r2
bcc malloc_meminit

ldr r2, [r0, #0]
ldr r3, [r0, #4]

mov r1, r0
add r1, r1, #12
add r1, r1, r2
ldr r2, =0x45425457
str r2, [r1] @ Initialize the magicnum @ <actualbuffer_addr> + <actualbuffer_size>.

//ldr r2, =0x1000
mov r2, #0
add r2, r2, r3
add r2, r2, r0

ldr r3, =0x0FFF8000
str r2, [r3, #16] @ Update the ptr used for the next memalloc.

add r0, r0, #12

bx lr
.pool

free:
cmp r0, #0
bxeq lr

ldr r3, =0x0FFF8000 @ if(inputptr < <base_memalloc_addr>)return 1;
ldr r2, [r3, #8]
cmp r0, r2
movcc r0, #1
bxcc lr

sub r0, r0, #12 @ Get the actual page address, since the first 12-bytes before the actual buffer is the header.

ldr r3, =0x42445457 @ Validate the chunk magicnum, and trigger a crash if it's invalid.
ldr r2, [r0, #8]
cmp r2, r3
ldrne r4, =0xa8a8a8a8
strne r2, [r4]

ldr r2, [r0, #0] @ Validate the magicnum @ <actualbuffer_addr> + <actualbuffer_size>, and trigger a crash if it's invalid.
add r2, r2, r0
add r2, r2, #12
ldr r2, [r2]
ldr r3, =0x45425457
cmp r2, r3
//ldrne r4, =0xacacacac
//strne r2, [r4] @ Disabled because of libcurl(?) use-after-free issues.

ldr r3, [r0, #4] @ Aligned total size.

push {r4}
mov r1, r0 @ addr0
mov r0, #1 @ operation
mov r4, #0 @ permissions

mov r2, #0 @ addr1
svc 0x01
pop {r4}

cmp r0, #0 @ If everything works as intended, this should only ever happen on double-frees / invalid inputptr.
ldrne r3, =0x94949494
strne r0, [r3]

mov r0, #0
bx lr
.pool

wkc_free:
mov r1, #0
b _free

_free:
push {r0, r1, lr}

bl free

pop {r2, r3, lr}

cmp r0, #0
bxeq lr

@ Instead of letting the normal code free the memory, just overwrite the first 0x8-bytes of the buffer with junk without freeing it at all.

/*ldr r1, =0xcccccccc
str r1, [r1]*/

mov r0, r2
/*mov r1, r3
ldr r3, =0x0FFF8000

cmp r1, #0 @ wkc_free
pusheq {r4, lr}
moveq r4, r0
ldreq r3, [r3, #4]
bxeq r3*/

/*ldr r1, [r0]
lsr r1, r1, #24
cmp r1, #0
bne _free_finish

push {r0, lr}
mov r0, #0x100
bl malloc
push {r0}
ldr r1, [sp, #4]
mov r2, #0xfc
add r0, r0, #4
bl memcpy
ldr r0, [sp, #4]
ldr r1, [sp, #0]
str r0, [r1]
pop {r3}
pop {r0, lr}

_free_finish:*/
ldr r1, =0xcccccccc
add r2, r1, #1
mov r2, r3
add r3, r2, #1

stmia r0!, {r1, r2}

/*stmia r0!, {r1, r2, r3}
add r1, r1, #3
add r2, r2, #3
add r3, r3, #3*/
//str r1, [r0]
/*stmia r0!, {r1, r2, r3}
add r1, r1, #3
add r2, r2, #3
stmia r0!, {r1, r2}*/

bx lr
.pool

wkc_realloc:
mov r2, #0
b realloc

fastmalloc_realloc:
push {r0, lr}
mov r0, r1
mov r1, r2
mov r2, #1
bl realloc
pop {r3, lr}
str r0, [r3]
bx lr

realloc: @ inr0=inmemptr, inr1=size, inr2=id
push {r0, r1, r2, r4, r5, lr}
mov r4, #0

add r5, sp, #0

ldr r0, [r5, #4]
cmp r0, #0
beq realloc_skiptofree

bl malloc
mov r4, r0

ldr r1, [r5, #0]
cmp r1, #0
beq realloc_skiptofree
ldr r2, [r5, #4]
bl memcpy

realloc_skiptofree:
ldr r0, [r5, #0]
cmp r0, #0
beq realloc_finish
/*
//This is commented-out because the libcurl(?) build used with spider oss.cro, has use-after-free issues with the realloc() input memptr.
ldr r1, [sp, #8]
bl _free
#endif*/

realloc_finish:
mov r0, r4

pop {r0, r1, r2, r4, r5, pc}
.pool

memcpy:
cmp r2, #0
bxeq lr
ldr r3, [r1], #4
str r3, [r0], #4
sub r2, r2, #4
cmp r2, #4
bcs memcpy

memcpy_finishlp:
cmp r2, #0
bxeq lr

ldrb r3, [r1], #1
strb r3, [r0], #1
sub r2, r2, #1
b memcpy_finishlp

