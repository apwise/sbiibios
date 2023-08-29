# Intertec Superbrain II BIOS

The Intertec Superbrain is a CP/M machine from the 1980s. The BIOS that
supported this was divided into two parts. One part was published as
source code, while the other part remained a private module, only
distributed as assembled binary. There were two major versions of the
Superbrain - the original from 1979 and a revised second version, the
Superbrain II, from 1982. Each of these versions was sold in three
variants with differing floppy disk capacities. This project was
originally about disassembling the private BIOS module for the Intertec
Superbrain II. However, it's grown a little to encompass also
disassembling the boot ROM and being able to build the O/S installer
from source code.

## Match

The code in the `match` directory is source code (much of it disassembled)
that matches (exact binary match) references. It is divided into three
directories:

 * system - the boot tracks of a bootable floppy
 * sysgen - the O/S installer program (that writes the system tracks)
 * bootrom - the boot ROM of my machine

### System

The code in `match/system` is the source code (a mix of disassembled
code and original source code) that matches the system tracks from a
bootable floppy disk. The code here builds (see the `Makefile`) to
produce `system.dsk` which is compared against the first two tracks
of a bootable floppy which a fellow hobbyist kindly sent to me.
(My Superbrain II Jr - an ebay purchase - came without any disks.)

As always, my work here builds on the work of others that have
preserved software or disassembled parts of the system before me.
The `match/system/originals` directory contains the files that I
started with. The following notes what they are and where I got them
from:

#### References

| Filename       | Description                                           |
| -------------- | ----------------------------------------------------- |
| `flopboot.asm` | The bootstrap loader (in the first sector of the first track) from the Maslin archive [qdhdbios.td0](http://www.retroarchive.org/maslin/disks/intertec/qdhdbios.td0) |
| `OS2CCP.ASM`   | CCP source code from [Digital Research Source Code](http://www.retroarchive.org/cpm/archive/unofficial/download/cpm2-plm.zip) |
| `OS3BDOS.ASM`  | BDOS source code from [Digital Research Source Code](http://www.retroarchive.org/cpm/archive/unofficial/download/cpm2-plm.zip) || `qdiibios.asm` | Present, as source code, on the same bootable floppy from which the system tracks were extracted (as `SBIIBOOT.dsk`) - contributed to `SBIIBIOS.ASM` |
| `cse30bs.asm`  | Compustar BIOS from the Don Maslin archive [csr30enh.td0](http://www.retroarchive.org/maslin/disks/intertec/csr30enh.td0) - contributed to `SBIIBIOS.ASM` |
| `qd31bios.asm` | Superbrain (one) BIOS from Dave Dunfield's [image archive](http://dunfield.classiccmp.org/img/) - contributed to `SBIIBIOS.ASM` |
| `SBIIBOOT.dsk` | The first two tracks from a bootable floppy disk supplied by a fellow hobbyist |

#### Source code for binary match

The source files that can be built to match the system tracks are in `match/system`. Several of the files have conditional assembly under the symbol
`xmatch` to get an exact binary match. In particular this affects variables
that ought to be declared with a `ds` pseudo-op, but need to use a `dw`
or `db` pseudo-op with whatever random data happened to be lying around in
memory at the time that the file was originally linked.

| Filename       | Description                                           |
| -------------- | ----------------------------------------------------- |
| `flopboot.asm` | The bootstrap loader. The same code as in `originals` but with better comments, especially explaining the "every-other-sector" behaviour of the loader. |
| `os2ccp.asm`   | CCP - the CP/M command processor. Modified to include the Intertec serial number. |
| `os3bdos.asm`  | BDOS - the CP/M Basic Disk Operating System. Modified to include the Intertec serial number and linking to the Superbrain type-ahead buffer. |
| `SBIIBIOS.ASM` | The published part of the BIOS. I'm aiming at a BIOS for a Superbrain II Junior, but the system tracks in `originals/SBIIBOOT.dsk` are for a QD system - this accounts for several of `xmatch` differences. |
| `pviibios.asm` | The private BIOS module. Entirely disassembled - all comments here are mine. Deals with driving the screen (`CRTOUT`), reading the keyboard (`CRTIN`), and accessing floppy disks (`DISK`). |
| `wmstrt.asm`   | The warm-start loader which reads the CCP and BDOS back into memory after a command in the TPA exits. It is very similar to `flopboot.asm` but calls disk routines from `pviibios.asm` rather than those loaded from the boot ROM. |

#### CP/M tools

In order to build the code on a modern Linux box, the `Makefile` uses
[cpm](https://github.com/jhallen/cpm) as an emulator. This runs the Digital Research [toolchain](http://www.s100computers.com/Software%20Folder/Assembler%20Collection/Digital%20Research%20MAC,RMAC%20&%20LINK.zip). Although there is a `Z80.LIB` bundled there, I used a more recent version of that macro library: [Z80-V3.LIB](http://www.retroarchive.org/cpm/cdrom/CPM/MACLIB/Z80-V3.LIB) (renamed to `Z80.LIB`).

### Sysgen

`SYSGEN` is a CP/M program for copying the system tracks from one bootable
disk to another. It works by reading the system tracks from a source drive
into memory, it may then be written to one or more destination disks. It
is also possible to save a (suitably named copy of) `SYSGEN.COM` with the disk image already "attached". If the user then skips reading the source
drive, this pre-loaded image can be written to disks. This then becomes
an O/S installer program.

This area (`match/sysgen`) takes the digital research source code for a
standard `SYSGEN` and patches it inline with a disassembly of an
Intertec-supplied O/S install program (actually for a Compustar). The
main changes from the DRI code are the necessary changes to reflect the
different disk geometry and a "patch" (at `ENDRW`) to call `HOME` which
forces flushing the last physical sector to disk. There is also one change
to add an `ORA A` instruction in `PRERD` which seems to be a
bug-fix between version 1.4 and version 2.0 of `SYSGEN`.

#### References

In `match/sysgen/originals`:

| Filename       | Description                                           |
| -------------- | ----------------------------------------------------- |
| `SYSGEN.ASM`   | ASM source code from [Digital Research Source Code](http://www.retroarchive.org/cpm/archive/unofficial/download/cpm2-plm.zip) |
| `cs30cpm.com`  | Compustar O/S installer from the Don Maslin archive [csr30enh.td0](http://www.retroarchive.org/maslin/disks/intertec/csr30enh.td0) |

### Bootrom

`match/bootrom` is a disassembly of bootrom found in my SuperBrain II Jr.

#### References

In `match/bootrom/originals`:

| Filename       | Description                                           |
| -------------- | ----------------------------------------------------- |
| `SuperBrain_V4.1.bin`  | Dump of the boot ROM produced by [`READROM.COM`](#readrom) |

## Readrom

`sb_tools/readrom` is a tiny utility to read the bootrom of a Superbrain.

It copies chunks of 128 bytes (one logical CP/M sector) from the bootrom
into upper memory from where it is written to a disk file. The copy from
to bootrom occurs with interrupts disabled because the ROM has to be
mapped in at location zero (so that the interrupt vector isn't available).

## Source code

Clean source code to build the operating system is in the `src` directory.
This has all the `xmatch` conditional compilation removed.

The source files are:

| Filename       | Description                                           |
| -------------- | ----------------------------------------------------- |
| `flopboot.asm` | Bootstrap loader                                      |
| `os2ccp.asm`   | Console Command Processor                             |
| `os3bdos.asm`  | Basic Disc Operating System                           |
| `SBIIBIOS.ASM` | Published BIOS for Superbrain II Jr (Junior - single-sided 35-track) |
| `QDIIBIOS.ASM` | Published BIOS for Superbrain II QD (Quad Density - double-sided 35-track) |
| `SDIIBIOS.ASM` | Published BIOS for Superbrain II SD (Super Density - double-sided 80-track) |
| `pviibios.asm` | Private BIOS module for Superbrain II                 |
| `wmstrt.asm`   | Warm start loader                                     |
| `sysgen.asm`   | Sysgen (O/S installation program)                     |

In truth, I don't know the exact `sgnon` message for either the Jr
(`SBIIBIOS.ASM`) or SD (`SDIIBIOS.ASM`) variants (since I've only ever
seen a genuine boot disk for a QD). Similarly, the disk parameter blocks
for Jr and SD are computed by me, and I might have them wrong. Please
let me know if you have an original boot disk for these variants. 

The `Makefile` builds the following (in the `build` directory):

| Filename       | Description                                           |
| -------------- | ----------------------------------------------------- |
| `SBIICPM.COM`  | Installer for Superbrain II Jr (Junior - single-sided 35-track) |
| `QDIICPM.COM`  | Installer for Superbrain II QD (Quad Density - double-sided 35-track) |
| `SDIICPM.COM`  | Installer for Superbrain II SD (Super Density - double-sided 80-track) |

## Documentation

The `doc` directory contains a short [asciidoctor](https://asciidoctor.org/)
document containing technical information on I/O ports and the overall
memory map that has been learned while working on this project.
