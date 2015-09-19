DEFINES	:=	

all:
	arm-none-eabi-gcc -x assembler-with-cpp -nostartfiles -nostdlib $(DEFINES) -o 3ds_arm11code.elf 3ds_arm11code.s
	arm-none-eabi-objcopy -O binary 3ds_arm11code.elf 3ds_arm11code.bin
	cp 3ds_arm11code.bin $(OUTPATH)

clean:
	rm -f 3ds_arm11code.elf 3ds_arm11code.bin

