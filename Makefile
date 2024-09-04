all: floppy

main:
	nasm -f bin -o boot.bin boot.asm

	nasm -f bin files.asm -o files.bin
	nasm -f bin ls.asm -o ls.bin
	nasm -f bin clear.asm -o clear.bin
	nasm -f bin theme.asm -o theme.bin

	nasm -f bin shell.asm -o shell.bin 
	
run:
	qemu-system-i386 -hda RockOS.img
# 2880 - 4 sectors used = 2876
floppy: main
	dd if=/dev/zero of=floppy.bin count=2876 bs=512
	cat boot.bin files.bin shell.bin 	\
	ls.bin								\
	 ./cpuinfo/info.bin					\
	 clear.bin							\
	 theme.bin							\
	 ./games/snake.img					\
	 ./games/tetris.img 				\
	 ./pong/pong2.bin					\
	 floppy.bin > RockOS.img
	rm -f *.bin

iso: main
	dd if=/dev/zero of=floppy.bin count=2876 bs=512
	cat boot.bin files.bin shell.bin 			\
	ls.bin 										\
	 ./cpuinfo/info.bin							\
	 clear.bin									\
	 theme.bin									\
	 ./games/snake.img							\
	 ./games/tetris.img 						\
	 ./pong/pong2.bin							\
	 floppy.bin > RockOS.iso
	rm -f *.bin

iso-run:
	qemu-system-i386 -hda RockOS.iso

iso-clean:
	rm -f *.iso

clean:
	rm -f *.bin
	rm -f *.img
