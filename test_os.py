import pexpect
import sys

child = pexpect.spawn('qemu-system-i386 -hda RockOS.img -display none -serial stdio')
child.logfile = sys.stdout.buffer

try:
    child.expect('Welcome', timeout=2)
    child.expect('>', timeout=2)
except Exception:
    pass

child.sendline('mkdir test')
child.expect('>', timeout=2)
child.sendline('ls')
child.expect('>', timeout=2)

print("\n\nAll output reading done")
child.close()
