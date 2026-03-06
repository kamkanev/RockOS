import pexpect
import sys
import time

child = pexpect.spawn('qemu-system-i386 -hda RockOS.img -display none -serial stdio')
time.sleep(1)

child.sendline('mkdir test')
time.sleep(1)
child.close()
