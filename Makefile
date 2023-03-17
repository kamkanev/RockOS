all: floppy

main:
	nasm -f bin -o boot.bin boot.asm
	nasm -f bin shell.asm -o shell.bin 
	nasm -f bin files.asm -o files.bin
	
run:
	qemu-system-i386 -hda RockOS.img

floppy: main
	dd if=/dev/zero of=floppy.bin count=2877 bs=512
	cat boot.bin files.bin shell.bin ./games/snake.img floppy.bin > RockOS.img
	rm -f *.bin

clean:
	rm -f *.bin
	rm -f *.img
