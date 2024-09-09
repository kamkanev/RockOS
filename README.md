# RockOS

This is a mini project of creating an operating system from scratch using all my knowage in computer architerture and operating systems. I'm using assembly x86 in 16 bit real mode togehter with mashine code.

<img title="" src="./screenshots/1.png" alt="Screenshot OS" width="554">

### Goals:

The main goal of RockOS is to be able to run on ony computer (regadless of architecture) and also virtually (using virtual machine).

**Other goals**:

- [ ] create and run thirth party software (custome made apps)

- [ ] create and save binary files

- [ ] create and save text files

- [ ] connection to inthernet/ethernet

- [ ] access to disks (mounting/dismounting)

- [x] graphical interface (themes and mouse(not yet))

- [x] real time clock

- [x] play games

- [x] gives CPU information

- [ ] gives hardware information

---

## Download:

Get the version you like: [Releases · kamkanev/RockOS · GitHub](https://github.com/kamkanev/RockOS/releases)

## Build it yourself

### Preparations:

#### Windows (unavaiable for now)

#### Linux:

Install NASM for assembly x86:

    For Debian, Ubuntu, Linux Mint 

```batch
sudo apt install nasm
```

    For RHEL, Fedora, AlmaLinux:

```batch
sudo dnf install nasm
```

    For Arch, Manjaro, EndeavourOS

```batch
sudo pacman -S nasm
```

Install QEMU simulator:

    More information here: [Download QEMU for Linux](https://www.qemu.org/download/#linux)

```batch
sudo apt-get install qemu-system
sudo pacman -S qemu
sudo dnf install @virtualization
```

### Installation:

Download the github repo:

```batch
gh repo clone kamkanev/RockOS
```

```batch
git clone https://github.com/kamkanev/RockOS.git
```

Go into the folder of the project and run the Makefile:

```batch
cd RockOS    
```

```batch
make
```

    After running the command you should get a **.img** file.

    Alternativly using the following command you can get a **.iso** file.

```batch
make iso
```

### Run in simulation:

    You can either run the files on a virtual machine or in [Virtual x86](https://copy.sh/v86/) or you can run the following command to run the OS in QEMU simulator.

```batch
make run
```

![Screenshot](./screenshots/info.png)

```batch
make iso-run
```

To clean up use:

```batch
make clean
```

```batch
make iso-clean
```

### Run on bootable USB

You can also make a bootable USB using:

```batch
sudo dd if=RockOS.img of=/dev/sda count=2880 bs=512
```

Find your USB using

```batch
sudo blkid
```

---

## Usage:

At the momment the only working commands are `help` and all the commands use see there:

#### Contols for the games:

**pong**

- first to 5 points wins

- `q` to exit to the shell

- *On win or lose reboots (bug)*

- *the scores stays in shell after exit. Use <u>clear</u> cmd. (bug)*

**mines**

- move cursor with `arrow keys`

- `space` to view the box

- `enter` to put a flag

- to game over or win restart the game with `r`

- `q` to exit the game at any time

- *text game over and win doesn't show (bug)*

**snake**

- `WASD` to move around

- `q` to exit

- *Use <u>clear</u> to reset the theme (bug)*

<img title="" src="./screenshots/list.png" alt="listsc" width="627" data-align="left"><img title="" src="./screenshots/theme.png" alt="theme" width="640" data-align="inline">

![pong](./screenshots/pong.png)

## RAM Memory table:

| Start       | End         | Size        | Desc.      |
| ----------- | ----------- | ----------- | ---------- |
| 0x0000_0500 | 0x0000_7BFF | 30463 bytes | Stack      |
| 0x0000_7C00 | 0x0000_7DFF | 512 bytes   | Bootloader |
| 0x0000_7E00 | 0x0000_7FFF | 512 bytes   | Files      |
| 0x0000_8000 | 0x0000_81FF | 512 bytes   | Shell      |
| 0x0000_8200 | 0x0000_8399 | 512 bytes   | Theme      |

## Floppy image map:

| Start       | End         | Size      | Description | Sector |
| ----------- | ----------- | --------- | ----------- | ------ |
| 0x0000_0000 | 0x0000_01FF | 512 bytes | bootloader  | 1      |
| 0x0000_0200 | 0x0000_03FF | 512 bytes | files       | 2      |
| 0x0000_0400 | 0x0000_05FF | 512 bytes | shell       | 3      |
| 0x0000_0600 | 0x0000_07FF | 512 bytes | help        | 4      |
| 0x0000_0800 | 0x0000_09FF | 512 bytes | info        | 5      |
| 0x0000_0A00 | 0x0000_0BFF | 512 bytes | clear       | 6      |
| 0x0000_0C00 | 0x0000_0DFF | 512 bytes | theme       | 7      |
| 0x0000_0E00 | 0x0000_0FFF | 512 bytes | clock       | 8      |
| 0x0000_1000 | 0x0000_11FF | 512 bytes | snake       | 9      |
| 0x0000_1200 | 0x0000_13FF | 512 bytes | mines       | 10     |
| 0x0000_1400 | 0x0000_15FF | 512 bytes | pong        | 11     |
| 0x0000_1600 | 0x0000_17FF | 512 bytes | reboot      | 12     |

---

## Problems:

- [x] Not all games return you the shell

- [ ] Can't load files/games larger than **512bytes**. (In Progress)

- [x] Optimize the **stack** and **heap** (to best of my abilities)

- [ ] On game exit theme may change

- [ ] Last row in shell is not included in the theme

## Credits

Minesweeper (BootMine) from [io12]([io12 (Benjamin Levy) · GitHub](https://github.com/io12))

Theme code and other programs from [Code Monkey King]([maksimKorzh (Code Monkey King) · GitHub](https://github.com/maksimKorzh))
