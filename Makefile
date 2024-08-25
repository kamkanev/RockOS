all: floppy

main:
	nasm -f bin -o boot.bin boot.asm
	nasm -f bin shell.asm -o shell.bin 
	nasm -f bin files.asm -o files.bin
	
run:
	qemu-system-i386 -hda RockOS.img
# 2880 - 4 sectors used = 2876
floppy: main
	dd if=/dev/zero of=floppy.bin count=2876 bs=512
	cat boot.bin files.bin shell.bin 	\
	 ./games/snake.img					\
	 ./games/tetris.img 				\
	 ./pong/pong.bin					\
	 floppy.bin > RockOS.img
	rm -f *.bin

iso: main
	dd if=/dev/zero of=floppy.bin count=2876 bs=512
	cat boot.bin files.bin shell.bin 	\
	 ./games/snake.img					\
	 ./games/tetris.img 				\
	 ./pong/pong.bin					\
	 floppy.bin > RockOS.iso
	rm -f *.bin

iso-run:
	qemu-system-i386 -hda RockOS.iso

iso-clean:
	rm -f *.iso

clean:
	rm -f *.bin
	rm -f *.img
