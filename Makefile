all: floppy

main:
	nasm -f bin -o boot.bin boot.asm

	nasm -f bin files.asm -o files.bin
	nasm -f bin ls.asm -o ls.bin
	nasm -f bin clear.asm -o clear.bin
	nasm -f bin theme.asm -o theme.bin
	nasm -f bin reboot.asm -o reboot.bin
	nasm -f bin ./cpuinfo/cpuinfo.asm -o ./cpuinfo/info.bin
	nasm -f bin ./clock/clock.asm -o ./clock/clock.bin

	nasm -f bin shell.asm -o shell.bin 
	
run:
	qemu-system-i386 -hda RockOS.img
# 2880 - 4 sectors used = 2876
# NEVER MOVE THE THEME FILES SHELL (must be changed in bootloader to whitch sector they point)
floppy: main
	dd if=/dev/zero of=floppy.bin count=2876 bs=512
	cat boot.bin files.bin shell.bin 	\
	ls.bin								\
	 ./cpuinfo/info.bin					\
	 clear.bin							\
	 theme.bin							\
	 ./clock/clock.bin					\
	 ./games/snake.img					\
	 ./games/bootmine.img 				\
	 ./pong/pong2.bin					\
	 reboot.bin							\
	 floppy.bin > RockOS.img
	rm -f *.bin

iso: main
	dd if=/dev/zero of=floppy.bin count=2876 bs=512
	cat boot.bin files.bin shell.bin 			\
	ls.bin 										\
	 ./cpuinfo/info.bin							\
	 clear.bin									\
	 theme.bin									\
	 ./clock/clock.bin							\
	 ./games/snake.img							\
	 ./games/tetris.img 						\
	 ./pong/pong2.bin							\
	 reboot.bin									\
	 floppy.bin > RockOS.iso
	rm -f *.bin

iso-run:
	qemu-system-i386 -hda RockOS.iso

iso-clean:
	rm -f *.iso

clean:
	rm -f *.bin
	rm -f *.img
