
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 60 1a 10 f0 	movl   $0xf0101a60,(%esp)
f0100055:	e8 de 08 00 00       	call   f0100938 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 18 07 00 00       	call   f010079f <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 7c 1a 10 f0 	movl   $0xf0101a7c,(%esp)
f0100092:	e8 a1 08 00 00       	call   f0100938 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 c4 14 00 00       	call   f0101589 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 97 1a 10 f0 	movl   $0xf0101a97,(%esp)
f01000d9:	e8 5a 08 00 00       	call   f0100938 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 b3 06 00 00       	call   f01007a9 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 b2 1a 10 f0 	movl   $0xf0101ab2,(%esp)
f010012c:	e8 07 08 00 00       	call   f0100938 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 c8 07 00 00       	call   f0100905 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ee 1a 10 f0 	movl   $0xf0101aee,(%esp)
f0100144:	e8 ef 07 00 00       	call   f0100938 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 54 06 00 00       	call   f01007a9 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ca 1a 10 f0 	movl   $0xf0101aca,(%esp)
f0100176:	e8 bd 07 00 00       	call   f0100938 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 7b 07 00 00       	call   f0100905 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ee 1a 10 f0 	movl   $0xf0101aee,(%esp)
f0100191:	e8 a2 07 00 00       	call   f0100938 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 40 1c 10 f0 	movzbl -0xfefe3c0(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 40 1c 10 f0 	movzbl -0xfefe3c0(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 40 1b 10 f0 	movzbl -0xfefe4c0(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 20 1b 10 f0 	mov    -0xfefe4e0(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 e4 1a 10 f0 	movl   $0xf0101ae4,(%esp)
f01002e9:	e8 4a 06 00 00       	call   f0100938 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100314:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100319:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 21                	jne    f010033f <cons_putc+0x36>
f010031e:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100323:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100328:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032d:	89 ca                	mov    %ecx,%edx
f010032f:	ec                   	in     (%dx),%al
f0100330:	ec                   	in     (%dx),%al
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	89 f2                	mov    %esi,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	a8 20                	test   $0x20,%al
f0100338:	75 05                	jne    f010033f <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033a:	83 eb 01             	sub    $0x1,%ebx
f010033d:	75 ee                	jne    f010032d <cons_putc+0x24>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010033f:	89 f8                	mov    %edi,%eax
f0100341:	0f b6 c0             	movzbl %al,%eax
f0100344:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100347:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010034c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034d:	b2 79                	mov    $0x79,%dl
f010034f:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100350:	84 c0                	test   %al,%al
f0100352:	78 21                	js     f0100375 <cons_putc+0x6c>
f0100354:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100359:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035e:	be 79 03 00 00       	mov    $0x379,%esi
f0100363:	89 ca                	mov    %ecx,%edx
f0100365:	ec                   	in     (%dx),%al
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	ec                   	in     (%dx),%al
f0100369:	89 f2                	mov    %esi,%edx
f010036b:	ec                   	in     (%dx),%al
f010036c:	84 c0                	test   %al,%al
f010036e:	78 05                	js     f0100375 <cons_putc+0x6c>
f0100370:	83 eb 01             	sub    $0x1,%ebx
f0100373:	75 ee                	jne    f0100363 <cons_putc+0x5a>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100375:	ba 78 03 00 00       	mov    $0x378,%edx
f010037a:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037e:	ee                   	out    %al,(%dx)
f010037f:	b2 7a                	mov    $0x7a,%dl
f0100381:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100386:	ee                   	out    %al,(%dx)
f0100387:	b8 08 00 00 00       	mov    $0x8,%eax
f010038c:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038d:	89 fa                	mov    %edi,%edx
f010038f:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100395:	89 f8                	mov    %edi,%eax
f0100397:	80 cc 07             	or     $0x7,%ah
f010039a:	85 d2                	test   %edx,%edx
f010039c:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010039f:	89 f8                	mov    %edi,%eax
f01003a1:	0f b6 c0             	movzbl %al,%eax
f01003a4:	83 f8 09             	cmp    $0x9,%eax
f01003a7:	74 79                	je     f0100422 <cons_putc+0x119>
f01003a9:	83 f8 09             	cmp    $0x9,%eax
f01003ac:	7f 0a                	jg     f01003b8 <cons_putc+0xaf>
f01003ae:	83 f8 08             	cmp    $0x8,%eax
f01003b1:	74 19                	je     f01003cc <cons_putc+0xc3>
f01003b3:	e9 9e 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
f01003b8:	83 f8 0a             	cmp    $0xa,%eax
f01003bb:	90                   	nop
f01003bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003c0:	74 3a                	je     f01003fc <cons_putc+0xf3>
f01003c2:	83 f8 0d             	cmp    $0xd,%eax
f01003c5:	74 3d                	je     f0100404 <cons_putc+0xfb>
f01003c7:	e9 8a 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
	case '\b':
		if (crt_pos > 0) {
f01003cc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003d3:	66 85 c0             	test   %ax,%ax
f01003d6:	0f 84 e5 00 00 00    	je     f01004c1 <cons_putc+0x1b8>
			crt_pos--;
f01003dc:	83 e8 01             	sub    $0x1,%eax
f01003df:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e5:	0f b7 c0             	movzwl %ax,%eax
f01003e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ed:	83 cf 20             	or     $0x20,%edi
f01003f0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fa:	eb 78                	jmp    f0100474 <cons_putc+0x16b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003fc:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f0100403:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100404:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010040b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100411:	c1 e8 16             	shr    $0x16,%eax
f0100414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100417:	c1 e0 04             	shl    $0x4,%eax
f010041a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100420:	eb 52                	jmp    f0100474 <cons_putc+0x16b>
		break;
	case '\t':
		cons_putc(' ');
f0100422:	b8 20 00 00 00       	mov    $0x20,%eax
f0100427:	e8 dd fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010042c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100431:	e8 d3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100436:	b8 20 00 00 00       	mov    $0x20,%eax
f010043b:	e8 c9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100440:	b8 20 00 00 00       	mov    $0x20,%eax
f0100445:	e8 bf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010044a:	b8 20 00 00 00       	mov    $0x20,%eax
f010044f:	e8 b5 fe ff ff       	call   f0100309 <cons_putc>
f0100454:	eb 1e                	jmp    f0100474 <cons_putc+0x16b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100456:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010045d:	8d 50 01             	lea    0x1(%eax),%edx
f0100460:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100467:	0f b7 c0             	movzwl %ax,%eax
f010046a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100470:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100474:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010047b:	cf 07 
f010047d:	76 42                	jbe    f01004c1 <cons_putc+0x1b8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100484:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010048b:	00 
f010048c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100492:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100496:	89 04 24             	mov    %eax,(%esp)
f0100499:	e8 38 11 00 00       	call   f01015d6 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010049e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	83 c0 01             	add    $0x1,%eax
f01004b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b7:	75 f0                	jne    f01004a9 <cons_putc+0x1a0>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004c0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004c1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004cc:	89 ca                	mov    %ecx,%edx
f01004ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004cf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d9:	89 d8                	mov    %ebx,%eax
f01004db:	66 c1 e8 08          	shr    $0x8,%ax
f01004df:	89 f2                	mov    %esi,%edx
f01004e1:	ee                   	out    %al,(%dx)
f01004e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	89 f2                	mov    %esi,%edx
f01004ee:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ef:	83 c4 1c             	add    $0x1c,%esp
f01004f2:	5b                   	pop    %ebx
f01004f3:	5e                   	pop    %esi
f01004f4:	5f                   	pop    %edi
f01004f5:	5d                   	pop    %ebp
f01004f6:	c3                   	ret    

f01004f7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004fe:	74 11                	je     f0100511 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100506:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f010050b:	e8 ac fc ff ff       	call   f01001bc <cons_intr>
}
f0100510:	c9                   	leave  
f0100511:	f3 c3                	repz ret 

f0100513 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100519:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010051e:	e8 99 fc ff ff       	call   f01001bc <cons_intr>
}
f0100523:	c9                   	leave  
f0100524:	c3                   	ret    

f0100525 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100525:	55                   	push   %ebp
f0100526:	89 e5                	mov    %esp,%ebp
f0100528:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052b:	e8 c7 ff ff ff       	call   f01004f7 <serial_intr>
	kbd_intr();
f0100530:	e8 de ff ff ff       	call   f0100513 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100535:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010053a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100540:	74 26                	je     f0100568 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100542:	8d 50 01             	lea    0x1(%eax),%edx
f0100545:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010054b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100552:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100554:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055a:	75 11                	jne    f010056d <cons_getc+0x48>
			cons.rpos = 0;
f010055c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100563:	00 00 00 
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100595:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010059c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005b4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005bc:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ec:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100643:	89 f2                	mov    %esi,%edx
f0100645:	ec                   	in     (%dx),%al
f0100646:	89 da                	mov    %ebx,%edx
f0100648:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100649:	84 c9                	test   %cl,%cl
f010064b:	75 0c                	jne    f0100659 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010064d:	c7 04 24 f0 1a 10 f0 	movl   $0xf0101af0,(%esp)
f0100654:	e8 df 02 00 00       	call   f0100938 <cprintf>
}
f0100659:	83 c4 1c             	add    $0x1c,%esp
f010065c:	5b                   	pop    %ebx
f010065d:	5e                   	pop    %esi
f010065e:	5f                   	pop    %edi
f010065f:	5d                   	pop    %ebp
f0100660:	c3                   	ret    

f0100661 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100667:	8b 45 08             	mov    0x8(%ebp),%eax
f010066a:	e8 9a fc ff ff       	call   f0100309 <cons_putc>
}
f010066f:	c9                   	leave  
f0100670:	c3                   	ret    

f0100671 <getchar>:

int
getchar(void)
{
f0100671:	55                   	push   %ebp
f0100672:	89 e5                	mov    %esp,%ebp
f0100674:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100677:	e8 a9 fe ff ff       	call   f0100525 <cons_getc>
f010067c:	85 c0                	test   %eax,%eax
f010067e:	74 f7                	je     f0100677 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100680:	c9                   	leave  
f0100681:	c3                   	ret    

f0100682 <iscons>:

int
iscons(int fdnum)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100685:	b8 01 00 00 00       	mov    $0x1,%eax
f010068a:	5d                   	pop    %ebp
f010068b:	c3                   	ret    
f010068c:	66 90                	xchg   %ax,%ax
f010068e:	66 90                	xchg   %ax,%ax

f0100690 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100696:	c7 44 24 08 40 1d 10 	movl   $0xf0101d40,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 5e 1d 10 	movl   $0xf0101d5e,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 63 1d 10 f0 	movl   $0xf0101d63,(%esp)
f01006ad:	e8 86 02 00 00       	call   f0100938 <cprintf>
f01006b2:	c7 44 24 08 cc 1d 10 	movl   $0xf0101dcc,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 6c 1d 10 	movl   $0xf0101d6c,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 63 1d 10 f0 	movl   $0xf0101d63,(%esp)
f01006c9:	e8 6a 02 00 00       	call   f0100938 <cprintf>
	return 0;
}
f01006ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d3:	c9                   	leave  
f01006d4:	c3                   	ret    

f01006d5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d5:	55                   	push   %ebp
f01006d6:	89 e5                	mov    %esp,%ebp
f01006d8:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006db:	c7 04 24 75 1d 10 f0 	movl   $0xf0101d75,(%esp)
f01006e2:	e8 51 02 00 00       	call   f0100938 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e7:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ee:	00 
f01006ef:	c7 04 24 f4 1d 10 f0 	movl   $0xf0101df4,(%esp)
f01006f6:	e8 3d 02 00 00       	call   f0100938 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006fb:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100702:	00 
f0100703:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010070a:	f0 
f010070b:	c7 04 24 1c 1e 10 f0 	movl   $0xf0101e1c,(%esp)
f0100712:	e8 21 02 00 00       	call   f0100938 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100717:	c7 44 24 08 47 1a 10 	movl   $0x101a47,0x8(%esp)
f010071e:	00 
f010071f:	c7 44 24 04 47 1a 10 	movl   $0xf0101a47,0x4(%esp)
f0100726:	f0 
f0100727:	c7 04 24 40 1e 10 f0 	movl   $0xf0101e40,(%esp)
f010072e:	e8 05 02 00 00       	call   f0100938 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100733:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f010073a:	00 
f010073b:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f0100742:	f0 
f0100743:	c7 04 24 64 1e 10 f0 	movl   $0xf0101e64,(%esp)
f010074a:	e8 e9 01 00 00       	call   f0100938 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010074f:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100756:	00 
f0100757:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010075e:	f0 
f010075f:	c7 04 24 88 1e 10 f0 	movl   $0xf0101e88,(%esp)
f0100766:	e8 cd 01 00 00       	call   f0100938 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010076b:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100770:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100775:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010077a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100780:	85 c0                	test   %eax,%eax
f0100782:	0f 48 c2             	cmovs  %edx,%eax
f0100785:	c1 f8 0a             	sar    $0xa,%eax
f0100788:	89 44 24 04          	mov    %eax,0x4(%esp)
f010078c:	c7 04 24 ac 1e 10 f0 	movl   $0xf0101eac,(%esp)
f0100793:	e8 a0 01 00 00       	call   f0100938 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100798:	b8 00 00 00 00       	mov    $0x0,%eax
f010079d:	c9                   	leave  
f010079e:	c3                   	ret    

f010079f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010079f:	55                   	push   %ebp
f01007a0:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01007a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a7:	5d                   	pop    %ebp
f01007a8:	c3                   	ret    

f01007a9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007a9:	55                   	push   %ebp
f01007aa:	89 e5                	mov    %esp,%ebp
f01007ac:	57                   	push   %edi
f01007ad:	56                   	push   %esi
f01007ae:	53                   	push   %ebx
f01007af:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007b2:	c7 04 24 d8 1e 10 f0 	movl   $0xf0101ed8,(%esp)
f01007b9:	e8 7a 01 00 00       	call   f0100938 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007be:	c7 04 24 fc 1e 10 f0 	movl   $0xf0101efc,(%esp)
f01007c5:	e8 6e 01 00 00       	call   f0100938 <cprintf>


	while (1) {
		buf = readline("K> ");
f01007ca:	c7 04 24 8e 1d 10 f0 	movl   $0xf0101d8e,(%esp)
f01007d1:	e8 da 0a 00 00       	call   f01012b0 <readline>
f01007d6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007d8:	85 c0                	test   %eax,%eax
f01007da:	74 ee                	je     f01007ca <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007dc:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007e3:	be 00 00 00 00       	mov    $0x0,%esi
f01007e8:	eb 0a                	jmp    f01007f4 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007ea:	c6 03 00             	movb   $0x0,(%ebx)
f01007ed:	89 f7                	mov    %esi,%edi
f01007ef:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007f2:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f4:	0f b6 03             	movzbl (%ebx),%eax
f01007f7:	84 c0                	test   %al,%al
f01007f9:	74 6a                	je     f0100865 <monitor+0xbc>
f01007fb:	0f be c0             	movsbl %al,%eax
f01007fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100802:	c7 04 24 92 1d 10 f0 	movl   $0xf0101d92,(%esp)
f0100809:	e8 1b 0d 00 00       	call   f0101529 <strchr>
f010080e:	85 c0                	test   %eax,%eax
f0100810:	75 d8                	jne    f01007ea <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100812:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100815:	74 4e                	je     f0100865 <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100817:	83 fe 0f             	cmp    $0xf,%esi
f010081a:	75 16                	jne    f0100832 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010081c:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100823:	00 
f0100824:	c7 04 24 97 1d 10 f0 	movl   $0xf0101d97,(%esp)
f010082b:	e8 08 01 00 00       	call   f0100938 <cprintf>
f0100830:	eb 98                	jmp    f01007ca <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100832:	8d 7e 01             	lea    0x1(%esi),%edi
f0100835:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100839:	0f b6 03             	movzbl (%ebx),%eax
f010083c:	84 c0                	test   %al,%al
f010083e:	75 0c                	jne    f010084c <monitor+0xa3>
f0100840:	eb b0                	jmp    f01007f2 <monitor+0x49>
			buf++;
f0100842:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100845:	0f b6 03             	movzbl (%ebx),%eax
f0100848:	84 c0                	test   %al,%al
f010084a:	74 a6                	je     f01007f2 <monitor+0x49>
f010084c:	0f be c0             	movsbl %al,%eax
f010084f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100853:	c7 04 24 92 1d 10 f0 	movl   $0xf0101d92,(%esp)
f010085a:	e8 ca 0c 00 00       	call   f0101529 <strchr>
f010085f:	85 c0                	test   %eax,%eax
f0100861:	74 df                	je     f0100842 <monitor+0x99>
f0100863:	eb 8d                	jmp    f01007f2 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f0100865:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010086c:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010086d:	85 f6                	test   %esi,%esi
f010086f:	0f 84 55 ff ff ff    	je     f01007ca <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100875:	c7 44 24 04 5e 1d 10 	movl   $0xf0101d5e,0x4(%esp)
f010087c:	f0 
f010087d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100880:	89 04 24             	mov    %eax,(%esp)
f0100883:	e8 1d 0c 00 00       	call   f01014a5 <strcmp>
f0100888:	85 c0                	test   %eax,%eax
f010088a:	74 1b                	je     f01008a7 <monitor+0xfe>
f010088c:	c7 44 24 04 6c 1d 10 	movl   $0xf0101d6c,0x4(%esp)
f0100893:	f0 
f0100894:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100897:	89 04 24             	mov    %eax,(%esp)
f010089a:	e8 06 0c 00 00       	call   f01014a5 <strcmp>
f010089f:	85 c0                	test   %eax,%eax
f01008a1:	75 2f                	jne    f01008d2 <monitor+0x129>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008a3:	b0 01                	mov    $0x1,%al
f01008a5:	eb 05                	jmp    f01008ac <monitor+0x103>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a7:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008ac:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008af:	01 d0                	add    %edx,%eax
f01008b1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01008b4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01008b8:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008bb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008bf:	89 34 24             	mov    %esi,(%esp)
f01008c2:	ff 14 85 2c 1f 10 f0 	call   *-0xfefe0d4(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008c9:	85 c0                	test   %eax,%eax
f01008cb:	78 1d                	js     f01008ea <monitor+0x141>
f01008cd:	e9 f8 fe ff ff       	jmp    f01007ca <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008d2:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008d5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d9:	c7 04 24 b4 1d 10 f0 	movl   $0xf0101db4,(%esp)
f01008e0:	e8 53 00 00 00       	call   f0100938 <cprintf>
f01008e5:	e9 e0 fe ff ff       	jmp    f01007ca <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008ea:	83 c4 5c             	add    $0x5c,%esp
f01008ed:	5b                   	pop    %ebx
f01008ee:	5e                   	pop    %esi
f01008ef:	5f                   	pop    %edi
f01008f0:	5d                   	pop    %ebp
f01008f1:	c3                   	ret    

f01008f2 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008f2:	55                   	push   %ebp
f01008f3:	89 e5                	mov    %esp,%ebp
f01008f5:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01008fb:	89 04 24             	mov    %eax,(%esp)
f01008fe:	e8 5e fd ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f0100903:	c9                   	leave  
f0100904:	c3                   	ret    

f0100905 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100905:	55                   	push   %ebp
f0100906:	89 e5                	mov    %esp,%ebp
f0100908:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010090b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100912:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100915:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100919:	8b 45 08             	mov    0x8(%ebp),%eax
f010091c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100920:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100923:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100927:	c7 04 24 f2 08 10 f0 	movl   $0xf01008f2,(%esp)
f010092e:	e8 57 04 00 00       	call   f0100d8a <vprintfmt>
	return cnt;
}
f0100933:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100936:	c9                   	leave  
f0100937:	c3                   	ret    

f0100938 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100938:	55                   	push   %ebp
f0100939:	89 e5                	mov    %esp,%ebp
f010093b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010093e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100941:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100945:	8b 45 08             	mov    0x8(%ebp),%eax
f0100948:	89 04 24             	mov    %eax,(%esp)
f010094b:	e8 b5 ff ff ff       	call   f0100905 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100950:	c9                   	leave  
f0100951:	c3                   	ret    
f0100952:	66 90                	xchg   %ax,%ax
f0100954:	66 90                	xchg   %ax,%ax
f0100956:	66 90                	xchg   %ax,%ax
f0100958:	66 90                	xchg   %ax,%ax
f010095a:	66 90                	xchg   %ax,%ax
f010095c:	66 90                	xchg   %ax,%ax
f010095e:	66 90                	xchg   %ax,%ax

f0100960 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100960:	55                   	push   %ebp
f0100961:	89 e5                	mov    %esp,%ebp
f0100963:	57                   	push   %edi
f0100964:	56                   	push   %esi
f0100965:	53                   	push   %ebx
f0100966:	83 ec 10             	sub    $0x10,%esp
f0100969:	89 c6                	mov    %eax,%esi
f010096b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010096e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100971:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100974:	8b 1a                	mov    (%edx),%ebx
f0100976:	8b 01                	mov    (%ecx),%eax
f0100978:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010097b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100982:	eb 77                	jmp    f01009fb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100984:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100987:	01 d8                	add    %ebx,%eax
f0100989:	b9 02 00 00 00       	mov    $0x2,%ecx
f010098e:	99                   	cltd   
f010098f:	f7 f9                	idiv   %ecx
f0100991:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100993:	eb 01                	jmp    f0100996 <stab_binsearch+0x36>
			m--;
f0100995:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100996:	39 d9                	cmp    %ebx,%ecx
f0100998:	7c 1d                	jl     f01009b7 <stab_binsearch+0x57>
f010099a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f010099d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01009a2:	39 fa                	cmp    %edi,%edx
f01009a4:	75 ef                	jne    f0100995 <stab_binsearch+0x35>
f01009a6:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009a9:	6b d1 0c             	imul   $0xc,%ecx,%edx
f01009ac:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f01009b0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01009b3:	73 18                	jae    f01009cd <stab_binsearch+0x6d>
f01009b5:	eb 05                	jmp    f01009bc <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009b7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f01009ba:	eb 3f                	jmp    f01009fb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01009bc:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01009bf:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f01009c1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009c4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009cb:	eb 2e                	jmp    f01009fb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009cd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009d0:	73 15                	jae    f01009e7 <stab_binsearch+0x87>
			*region_right = m - 1;
f01009d2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009d5:	48                   	dec    %eax
f01009d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009d9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009dc:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009de:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009e5:	eb 14                	jmp    f01009fb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009e7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009ea:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f01009ed:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f01009ef:	ff 45 0c             	incl   0xc(%ebp)
f01009f2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009f4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009fb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009fe:	7e 84                	jle    f0100984 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a00:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a04:	75 0d                	jne    f0100a13 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a06:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a09:	8b 00                	mov    (%eax),%eax
f0100a0b:	48                   	dec    %eax
f0100a0c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a0f:	89 07                	mov    %eax,(%edi)
f0100a11:	eb 22                	jmp    f0100a35 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a16:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a18:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a1b:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a1d:	eb 01                	jmp    f0100a20 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a1f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a20:	39 c1                	cmp    %eax,%ecx
f0100a22:	7d 0c                	jge    f0100a30 <stab_binsearch+0xd0>
f0100a24:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a27:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a2c:	39 fa                	cmp    %edi,%edx
f0100a2e:	75 ef                	jne    f0100a1f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a30:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a33:	89 07                	mov    %eax,(%edi)
	}
}
f0100a35:	83 c4 10             	add    $0x10,%esp
f0100a38:	5b                   	pop    %ebx
f0100a39:	5e                   	pop    %esi
f0100a3a:	5f                   	pop    %edi
f0100a3b:	5d                   	pop    %ebp
f0100a3c:	c3                   	ret    

f0100a3d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a3d:	55                   	push   %ebp
f0100a3e:	89 e5                	mov    %esp,%ebp
f0100a40:	57                   	push   %edi
f0100a41:	56                   	push   %esi
f0100a42:	53                   	push   %ebx
f0100a43:	83 ec 2c             	sub    $0x2c,%esp
f0100a46:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a49:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a4c:	c7 03 3c 1f 10 f0    	movl   $0xf0101f3c,(%ebx)
	info->eip_line = 0;
f0100a52:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a59:	c7 43 08 3c 1f 10 f0 	movl   $0xf0101f3c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a60:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a67:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a6a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a71:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a77:	76 12                	jbe    f0100a8b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a79:	b8 49 73 10 f0       	mov    $0xf0107349,%eax
f0100a7e:	3d 9d 5a 10 f0       	cmp    $0xf0105a9d,%eax
f0100a83:	0f 86 8b 01 00 00    	jbe    f0100c14 <debuginfo_eip+0x1d7>
f0100a89:	eb 1c                	jmp    f0100aa7 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a8b:	c7 44 24 08 46 1f 10 	movl   $0xf0101f46,0x8(%esp)
f0100a92:	f0 
f0100a93:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a9a:	00 
f0100a9b:	c7 04 24 53 1f 10 f0 	movl   $0xf0101f53,(%esp)
f0100aa2:	e8 51 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100aa7:	80 3d 48 73 10 f0 00 	cmpb   $0x0,0xf0107348
f0100aae:	0f 85 67 01 00 00    	jne    f0100c1b <debuginfo_eip+0x1de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ab4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100abb:	b8 9c 5a 10 f0       	mov    $0xf0105a9c,%eax
f0100ac0:	2d 90 21 10 f0       	sub    $0xf0102190,%eax
f0100ac5:	c1 f8 02             	sar    $0x2,%eax
f0100ac8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ace:	83 e8 01             	sub    $0x1,%eax
f0100ad1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ad4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ad8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100adf:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ae2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ae5:	b8 90 21 10 f0       	mov    $0xf0102190,%eax
f0100aea:	e8 71 fe ff ff       	call   f0100960 <stab_binsearch>
	if (lfile == 0)
f0100aef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100af2:	85 c0                	test   %eax,%eax
f0100af4:	0f 84 28 01 00 00    	je     f0100c22 <debuginfo_eip+0x1e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100afa:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100afd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b00:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b03:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b07:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b0e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b11:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b14:	b8 90 21 10 f0       	mov    $0xf0102190,%eax
f0100b19:	e8 42 fe ff ff       	call   f0100960 <stab_binsearch>

	if (lfun <= rfun) {
f0100b1e:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b21:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b24:	7f 2e                	jg     f0100b54 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b26:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b29:	8d 90 90 21 10 f0    	lea    -0xfefde70(%eax),%edx
f0100b2f:	8b 80 90 21 10 f0    	mov    -0xfefde70(%eax),%eax
f0100b35:	b9 49 73 10 f0       	mov    $0xf0107349,%ecx
f0100b3a:	81 e9 9d 5a 10 f0    	sub    $0xf0105a9d,%ecx
f0100b40:	39 c8                	cmp    %ecx,%eax
f0100b42:	73 08                	jae    f0100b4c <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b44:	05 9d 5a 10 f0       	add    $0xf0105a9d,%eax
f0100b49:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b4c:	8b 42 08             	mov    0x8(%edx),%eax
f0100b4f:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b52:	eb 06                	jmp    f0100b5a <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b54:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b5a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b61:	00 
f0100b62:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b65:	89 04 24             	mov    %eax,(%esp)
f0100b68:	e8 f2 09 00 00       	call   f010155f <strfind>
f0100b6d:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b70:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b73:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b76:	39 cf                	cmp    %ecx,%edi
f0100b78:	7c 5c                	jl     f0100bd6 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100b7a:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b7d:	8d b0 90 21 10 f0    	lea    -0xfefde70(%eax),%esi
f0100b83:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0100b87:	80 fa 84             	cmp    $0x84,%dl
f0100b8a:	74 2b                	je     f0100bb7 <debuginfo_eip+0x17a>
f0100b8c:	05 84 21 10 f0       	add    $0xf0102184,%eax
f0100b91:	eb 15                	jmp    f0100ba8 <debuginfo_eip+0x16b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b93:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b96:	39 cf                	cmp    %ecx,%edi
f0100b98:	7c 3c                	jl     f0100bd6 <debuginfo_eip+0x199>
	       && stabs[lline].n_type != N_SOL
f0100b9a:	89 c6                	mov    %eax,%esi
f0100b9c:	83 e8 0c             	sub    $0xc,%eax
f0100b9f:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0100ba3:	80 fa 84             	cmp    $0x84,%dl
f0100ba6:	74 0f                	je     f0100bb7 <debuginfo_eip+0x17a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100ba8:	80 fa 64             	cmp    $0x64,%dl
f0100bab:	75 e6                	jne    f0100b93 <debuginfo_eip+0x156>
f0100bad:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0100bb1:	74 e0                	je     f0100b93 <debuginfo_eip+0x156>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100bb3:	39 f9                	cmp    %edi,%ecx
f0100bb5:	7f 1f                	jg     f0100bd6 <debuginfo_eip+0x199>
f0100bb7:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100bba:	8b 87 90 21 10 f0    	mov    -0xfefde70(%edi),%eax
f0100bc0:	ba 49 73 10 f0       	mov    $0xf0107349,%edx
f0100bc5:	81 ea 9d 5a 10 f0    	sub    $0xf0105a9d,%edx
f0100bcb:	39 d0                	cmp    %edx,%eax
f0100bcd:	73 07                	jae    f0100bd6 <debuginfo_eip+0x199>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bcf:	05 9d 5a 10 f0       	add    $0xf0105a9d,%eax
f0100bd4:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bd6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bd9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bdc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100be1:	39 ca                	cmp    %ecx,%edx
f0100be3:	7d 5e                	jge    f0100c43 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
f0100be5:	8d 42 01             	lea    0x1(%edx),%eax
f0100be8:	39 c1                	cmp    %eax,%ecx
f0100bea:	7e 3d                	jle    f0100c29 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bec:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100bef:	80 ba 94 21 10 f0 a0 	cmpb   $0xa0,-0xfefde6c(%edx)
f0100bf6:	75 38                	jne    f0100c30 <debuginfo_eip+0x1f3>
f0100bf8:	81 c2 84 21 10 f0    	add    $0xf0102184,%edx
		     lline++)
			info->eip_fn_narg++;
f0100bfe:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c02:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c05:	39 c1                	cmp    %eax,%ecx
f0100c07:	7e 2e                	jle    f0100c37 <debuginfo_eip+0x1fa>
f0100c09:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c0c:	80 7a 10 a0          	cmpb   $0xa0,0x10(%edx)
f0100c10:	74 ec                	je     f0100bfe <debuginfo_eip+0x1c1>
f0100c12:	eb 2a                	jmp    f0100c3e <debuginfo_eip+0x201>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c19:	eb 28                	jmp    f0100c43 <debuginfo_eip+0x206>
f0100c1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c20:	eb 21                	jmp    f0100c43 <debuginfo_eip+0x206>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c22:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c27:	eb 1a                	jmp    f0100c43 <debuginfo_eip+0x206>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c29:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c2e:	eb 13                	jmp    f0100c43 <debuginfo_eip+0x206>
f0100c30:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c35:	eb 0c                	jmp    f0100c43 <debuginfo_eip+0x206>
f0100c37:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c3c:	eb 05                	jmp    f0100c43 <debuginfo_eip+0x206>
f0100c3e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c43:	83 c4 2c             	add    $0x2c,%esp
f0100c46:	5b                   	pop    %ebx
f0100c47:	5e                   	pop    %esi
f0100c48:	5f                   	pop    %edi
f0100c49:	5d                   	pop    %ebp
f0100c4a:	c3                   	ret    
f0100c4b:	66 90                	xchg   %ax,%ax
f0100c4d:	66 90                	xchg   %ax,%ax
f0100c4f:	90                   	nop

f0100c50 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c50:	55                   	push   %ebp
f0100c51:	89 e5                	mov    %esp,%ebp
f0100c53:	57                   	push   %edi
f0100c54:	56                   	push   %esi
f0100c55:	53                   	push   %ebx
f0100c56:	83 ec 3c             	sub    $0x3c,%esp
f0100c59:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c5c:	89 d7                	mov    %edx,%edi
f0100c5e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c61:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c64:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100c67:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100c6a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c6d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100c72:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c75:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100c78:	39 f1                	cmp    %esi,%ecx
f0100c7a:	72 14                	jb     f0100c90 <printnum+0x40>
f0100c7c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100c7f:	76 0f                	jbe    f0100c90 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c81:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c84:	8d 70 ff             	lea    -0x1(%eax),%esi
f0100c87:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100c8a:	85 f6                	test   %esi,%esi
f0100c8c:	7f 60                	jg     f0100cee <printnum+0x9e>
f0100c8e:	eb 72                	jmp    f0100d02 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c90:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100c93:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100c97:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0100c9a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100c9d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ca1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ca5:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100ca9:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100cad:	89 c3                	mov    %eax,%ebx
f0100caf:	89 d6                	mov    %edx,%esi
f0100cb1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100cb4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100cb7:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100cbb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100cbf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cc2:	89 04 24             	mov    %eax,(%esp)
f0100cc5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cc8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ccc:	e8 ef 0a 00 00       	call   f01017c0 <__udivdi3>
f0100cd1:	89 d9                	mov    %ebx,%ecx
f0100cd3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100cd7:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100cdb:	89 04 24             	mov    %eax,(%esp)
f0100cde:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ce2:	89 fa                	mov    %edi,%edx
f0100ce4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ce7:	e8 64 ff ff ff       	call   f0100c50 <printnum>
f0100cec:	eb 14                	jmp    f0100d02 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cee:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cf2:	8b 45 18             	mov    0x18(%ebp),%eax
f0100cf5:	89 04 24             	mov    %eax,(%esp)
f0100cf8:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cfa:	83 ee 01             	sub    $0x1,%esi
f0100cfd:	75 ef                	jne    f0100cee <printnum+0x9e>
f0100cff:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d02:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d06:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d0a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d0d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d10:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d14:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d18:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d1b:	89 04 24             	mov    %eax,(%esp)
f0100d1e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d21:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d25:	e8 c6 0b 00 00       	call   f01018f0 <__umoddi3>
f0100d2a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d2e:	0f be 80 61 1f 10 f0 	movsbl -0xfefe09f(%eax),%eax
f0100d35:	89 04 24             	mov    %eax,(%esp)
f0100d38:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d3b:	ff d0                	call   *%eax
}
f0100d3d:	83 c4 3c             	add    $0x3c,%esp
f0100d40:	5b                   	pop    %ebx
f0100d41:	5e                   	pop    %esi
f0100d42:	5f                   	pop    %edi
f0100d43:	5d                   	pop    %ebp
f0100d44:	c3                   	ret    

f0100d45 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d45:	55                   	push   %ebp
f0100d46:	89 e5                	mov    %esp,%ebp
f0100d48:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d4b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d4f:	8b 10                	mov    (%eax),%edx
f0100d51:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d54:	73 0a                	jae    f0100d60 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d56:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d59:	89 08                	mov    %ecx,(%eax)
f0100d5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d5e:	88 02                	mov    %al,(%edx)
}
f0100d60:	5d                   	pop    %ebp
f0100d61:	c3                   	ret    

f0100d62 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d62:	55                   	push   %ebp
f0100d63:	89 e5                	mov    %esp,%ebp
f0100d65:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d68:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d6b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d6f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d72:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d76:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d79:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d80:	89 04 24             	mov    %eax,(%esp)
f0100d83:	e8 02 00 00 00       	call   f0100d8a <vprintfmt>
	va_end(ap);
}
f0100d88:	c9                   	leave  
f0100d89:	c3                   	ret    

f0100d8a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d8a:	55                   	push   %ebp
f0100d8b:	89 e5                	mov    %esp,%ebp
f0100d8d:	57                   	push   %edi
f0100d8e:	56                   	push   %esi
f0100d8f:	53                   	push   %ebx
f0100d90:	83 ec 3c             	sub    $0x3c,%esp
f0100d93:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100d96:	89 df                	mov    %ebx,%edi
f0100d98:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d9b:	eb 03                	jmp    f0100da0 <vprintfmt+0x16>
			break;

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100d9d:	89 75 10             	mov    %esi,0x10(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100da0:	8b 45 10             	mov    0x10(%ebp),%eax
f0100da3:	8d 70 01             	lea    0x1(%eax),%esi
f0100da6:	0f b6 00             	movzbl (%eax),%eax
f0100da9:	83 f8 25             	cmp    $0x25,%eax
f0100dac:	74 2d                	je     f0100ddb <vprintfmt+0x51>
			if (ch == '\0')
f0100dae:	85 c0                	test   %eax,%eax
f0100db0:	75 14                	jne    f0100dc6 <vprintfmt+0x3c>
f0100db2:	e9 6b 04 00 00       	jmp    f0101222 <vprintfmt+0x498>
f0100db7:	85 c0                	test   %eax,%eax
f0100db9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0100dc0:	0f 84 5c 04 00 00    	je     f0101222 <vprintfmt+0x498>
				return;
			putch(ch, putdat);
f0100dc6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100dca:	89 04 24             	mov    %eax,(%esp)
f0100dcd:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100dcf:	83 c6 01             	add    $0x1,%esi
f0100dd2:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f0100dd6:	83 f8 25             	cmp    $0x25,%eax
f0100dd9:	75 dc                	jne    f0100db7 <vprintfmt+0x2d>
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ddb:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100ddf:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100de6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100ded:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100df4:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100df9:	eb 1f                	jmp    f0100e1a <vprintfmt+0x90>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dfb:	8b 75 10             	mov    0x10(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100dfe:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0100e02:	eb 16                	jmp    f0100e1a <vprintfmt+0x90>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e04:	8b 75 10             	mov    0x10(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e07:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100e0b:	eb 0d                	jmp    f0100e1a <vprintfmt+0x90>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100e0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e10:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e13:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e1a:	8d 46 01             	lea    0x1(%esi),%eax
f0100e1d:	89 45 10             	mov    %eax,0x10(%ebp)
f0100e20:	0f b6 06             	movzbl (%esi),%eax
f0100e23:	0f b6 d0             	movzbl %al,%edx
f0100e26:	83 e8 23             	sub    $0x23,%eax
f0100e29:	3c 55                	cmp    $0x55,%al
f0100e2b:	0f 87 c4 03 00 00    	ja     f01011f5 <vprintfmt+0x46b>
f0100e31:	0f b6 c0             	movzbl %al,%eax
f0100e34:	ff 24 85 00 20 10 f0 	jmp    *-0xfefe000(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e3b:	8d 42 d0             	lea    -0x30(%edx),%eax
f0100e3e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100e41:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100e45:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100e48:	83 fa 09             	cmp    $0x9,%edx
f0100e4b:	77 63                	ja     f0100eb0 <vprintfmt+0x126>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e4d:	8b 75 10             	mov    0x10(%ebp),%esi
f0100e50:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100e53:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e56:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100e59:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100e5c:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100e60:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100e63:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100e66:	83 f9 09             	cmp    $0x9,%ecx
f0100e69:	76 eb                	jbe    f0100e56 <vprintfmt+0xcc>
f0100e6b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100e6e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100e71:	eb 40                	jmp    f0100eb3 <vprintfmt+0x129>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e73:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e76:	8b 00                	mov    (%eax),%eax
f0100e78:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100e7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e7e:	8d 40 04             	lea    0x4(%eax),%eax
f0100e81:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e84:	8b 75 10             	mov    0x10(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e87:	eb 2a                	jmp    f0100eb3 <vprintfmt+0x129>
f0100e89:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e8c:	85 d2                	test   %edx,%edx
f0100e8e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e93:	0f 49 c2             	cmovns %edx,%eax
f0100e96:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e99:	8b 75 10             	mov    0x10(%ebp),%esi
f0100e9c:	e9 79 ff ff ff       	jmp    f0100e1a <vprintfmt+0x90>
f0100ea1:	8b 75 10             	mov    0x10(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ea4:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100eab:	e9 6a ff ff ff       	jmp    f0100e1a <vprintfmt+0x90>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb0:	8b 75 10             	mov    0x10(%ebp),%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100eb3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100eb7:	0f 89 5d ff ff ff    	jns    f0100e1a <vprintfmt+0x90>
f0100ebd:	e9 4b ff ff ff       	jmp    f0100e0d <vprintfmt+0x83>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ec2:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ec5:	8b 75 10             	mov    0x10(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ec8:	e9 4d ff ff ff       	jmp    f0100e1a <vprintfmt+0x90>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ecd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ed0:	8d 70 04             	lea    0x4(%eax),%esi
f0100ed3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ed7:	8b 00                	mov    (%eax),%eax
f0100ed9:	89 04 24             	mov    %eax,(%esp)
f0100edc:	ff d7                	call   *%edi
f0100ede:	89 75 14             	mov    %esi,0x14(%ebp)
			break;
f0100ee1:	e9 ba fe ff ff       	jmp    f0100da0 <vprintfmt+0x16>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ee6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee9:	8d 70 04             	lea    0x4(%eax),%esi
f0100eec:	8b 00                	mov    (%eax),%eax
f0100eee:	99                   	cltd   
f0100eef:	31 d0                	xor    %edx,%eax
f0100ef1:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ef3:	83 f8 07             	cmp    $0x7,%eax
f0100ef6:	7f 0b                	jg     f0100f03 <vprintfmt+0x179>
f0100ef8:	8b 14 85 60 21 10 f0 	mov    -0xfefdea0(,%eax,4),%edx
f0100eff:	85 d2                	test   %edx,%edx
f0100f01:	75 20                	jne    f0100f23 <vprintfmt+0x199>
				printfmt(putch, putdat, "error %d", err);
f0100f03:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f07:	c7 44 24 08 79 1f 10 	movl   $0xf0101f79,0x8(%esp)
f0100f0e:	f0 
f0100f0f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f13:	89 3c 24             	mov    %edi,(%esp)
f0100f16:	e8 47 fe ff ff       	call   f0100d62 <printfmt>
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f1b:	89 75 14             	mov    %esi,0x14(%ebp)
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f1e:	e9 7d fe ff ff       	jmp    f0100da0 <vprintfmt+0x16>
			else
				printfmt(putch, putdat, "%s", p);
f0100f23:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f27:	c7 44 24 08 82 1f 10 	movl   $0xf0101f82,0x8(%esp)
f0100f2e:	f0 
f0100f2f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f33:	89 3c 24             	mov    %edi,(%esp)
f0100f36:	e8 27 fe ff ff       	call   f0100d62 <printfmt>
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f3b:	89 75 14             	mov    %esi,0x14(%ebp)
f0100f3e:	e9 5d fe ff ff       	jmp    f0100da0 <vprintfmt+0x16>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f43:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f46:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100f49:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f4c:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100f50:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f0100f52:	85 c0                	test   %eax,%eax
f0100f54:	b9 72 1f 10 f0       	mov    $0xf0101f72,%ecx
f0100f59:	0f 45 c8             	cmovne %eax,%ecx
f0100f5c:	89 4d d0             	mov    %ecx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0100f5f:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f0100f63:	74 04                	je     f0100f69 <vprintfmt+0x1df>
f0100f65:	85 f6                	test   %esi,%esi
f0100f67:	7f 19                	jg     f0100f82 <vprintfmt+0x1f8>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f69:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f6c:	8d 70 01             	lea    0x1(%eax),%esi
f0100f6f:	0f b6 10             	movzbl (%eax),%edx
f0100f72:	0f be c2             	movsbl %dl,%eax
f0100f75:	85 c0                	test   %eax,%eax
f0100f77:	0f 85 9a 00 00 00    	jne    f0101017 <vprintfmt+0x28d>
f0100f7d:	e9 87 00 00 00       	jmp    f0101009 <vprintfmt+0x27f>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f82:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100f86:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f89:	89 04 24             	mov    %eax,(%esp)
f0100f8c:	e8 11 04 00 00       	call   f01013a2 <strnlen>
f0100f91:	29 c6                	sub    %eax,%esi
f0100f93:	89 f0                	mov    %esi,%eax
f0100f95:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100f98:	85 f6                	test   %esi,%esi
f0100f9a:	7e cd                	jle    f0100f69 <vprintfmt+0x1df>
					putch(padc, putdat);
f0100f9c:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0100fa0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fa3:	89 c3                	mov    %eax,%ebx
f0100fa5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fa8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fac:	89 34 24             	mov    %esi,(%esp)
f0100faf:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fb1:	83 eb 01             	sub    $0x1,%ebx
f0100fb4:	75 ef                	jne    f0100fa5 <vprintfmt+0x21b>
f0100fb6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100fb9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fbc:	eb ab                	jmp    f0100f69 <vprintfmt+0x1df>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fbe:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fc2:	74 1e                	je     f0100fe2 <vprintfmt+0x258>
f0100fc4:	0f be d2             	movsbl %dl,%edx
f0100fc7:	83 ea 20             	sub    $0x20,%edx
f0100fca:	83 fa 5e             	cmp    $0x5e,%edx
f0100fcd:	76 13                	jbe    f0100fe2 <vprintfmt+0x258>
					putch('?', putdat);
f0100fcf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fd2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fd6:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100fdd:	ff 55 08             	call   *0x8(%ebp)
f0100fe0:	eb 0d                	jmp    f0100fef <vprintfmt+0x265>
				else
					putch(ch, putdat);
f0100fe2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0100fe5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100fe9:	89 04 24             	mov    %eax,(%esp)
f0100fec:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fef:	83 eb 01             	sub    $0x1,%ebx
f0100ff2:	83 c6 01             	add    $0x1,%esi
f0100ff5:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0100ff9:	0f be c2             	movsbl %dl,%eax
f0100ffc:	85 c0                	test   %eax,%eax
f0100ffe:	75 23                	jne    f0101023 <vprintfmt+0x299>
f0101000:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101003:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101006:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101009:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010100c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101010:	7f 25                	jg     f0101037 <vprintfmt+0x2ad>
f0101012:	e9 89 fd ff ff       	jmp    f0100da0 <vprintfmt+0x16>
f0101017:	89 7d 08             	mov    %edi,0x8(%ebp)
f010101a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010101d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101020:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101023:	85 ff                	test   %edi,%edi
f0101025:	78 97                	js     f0100fbe <vprintfmt+0x234>
f0101027:	83 ef 01             	sub    $0x1,%edi
f010102a:	79 92                	jns    f0100fbe <vprintfmt+0x234>
f010102c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010102f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101032:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101035:	eb d2                	jmp    f0101009 <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101037:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010103b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101042:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101044:	83 ee 01             	sub    $0x1,%esi
f0101047:	75 ee                	jne    f0101037 <vprintfmt+0x2ad>
f0101049:	e9 52 fd ff ff       	jmp    f0100da0 <vprintfmt+0x16>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010104e:	83 f9 01             	cmp    $0x1,%ecx
f0101051:	7e 19                	jle    f010106c <vprintfmt+0x2e2>
		return va_arg(*ap, long long);
f0101053:	8b 45 14             	mov    0x14(%ebp),%eax
f0101056:	8b 50 04             	mov    0x4(%eax),%edx
f0101059:	8b 00                	mov    (%eax),%eax
f010105b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010105e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101061:	8b 45 14             	mov    0x14(%ebp),%eax
f0101064:	8d 40 08             	lea    0x8(%eax),%eax
f0101067:	89 45 14             	mov    %eax,0x14(%ebp)
f010106a:	eb 38                	jmp    f01010a4 <vprintfmt+0x31a>
	else if (lflag)
f010106c:	85 c9                	test   %ecx,%ecx
f010106e:	74 1b                	je     f010108b <vprintfmt+0x301>
		return va_arg(*ap, long);
f0101070:	8b 45 14             	mov    0x14(%ebp),%eax
f0101073:	8b 30                	mov    (%eax),%esi
f0101075:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101078:	89 f0                	mov    %esi,%eax
f010107a:	c1 f8 1f             	sar    $0x1f,%eax
f010107d:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101080:	8b 45 14             	mov    0x14(%ebp),%eax
f0101083:	8d 40 04             	lea    0x4(%eax),%eax
f0101086:	89 45 14             	mov    %eax,0x14(%ebp)
f0101089:	eb 19                	jmp    f01010a4 <vprintfmt+0x31a>
	else
		return va_arg(*ap, int);
f010108b:	8b 45 14             	mov    0x14(%ebp),%eax
f010108e:	8b 30                	mov    (%eax),%esi
f0101090:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101093:	89 f0                	mov    %esi,%eax
f0101095:	c1 f8 1f             	sar    $0x1f,%eax
f0101098:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010109b:	8b 45 14             	mov    0x14(%ebp),%eax
f010109e:	8d 40 04             	lea    0x4(%eax),%eax
f01010a1:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010a4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01010a7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010aa:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010af:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010b3:	0f 89 06 01 00 00    	jns    f01011bf <vprintfmt+0x435>
				putch('-', putdat);
f01010b9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010bd:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010c4:	ff d7                	call   *%edi
				num = -(long long) num;
f01010c6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01010c9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01010cc:	f7 da                	neg    %edx
f01010ce:	83 d1 00             	adc    $0x0,%ecx
f01010d1:	f7 d9                	neg    %ecx
			}
			base = 10;
f01010d3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010d8:	e9 e2 00 00 00       	jmp    f01011bf <vprintfmt+0x435>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010dd:	83 f9 01             	cmp    $0x1,%ecx
f01010e0:	7e 10                	jle    f01010f2 <vprintfmt+0x368>
		return va_arg(*ap, unsigned long long);
f01010e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e5:	8b 10                	mov    (%eax),%edx
f01010e7:	8b 48 04             	mov    0x4(%eax),%ecx
f01010ea:	8d 40 08             	lea    0x8(%eax),%eax
f01010ed:	89 45 14             	mov    %eax,0x14(%ebp)
f01010f0:	eb 26                	jmp    f0101118 <vprintfmt+0x38e>
	else if (lflag)
f01010f2:	85 c9                	test   %ecx,%ecx
f01010f4:	74 12                	je     f0101108 <vprintfmt+0x37e>
		return va_arg(*ap, unsigned long);
f01010f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f9:	8b 10                	mov    (%eax),%edx
f01010fb:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101100:	8d 40 04             	lea    0x4(%eax),%eax
f0101103:	89 45 14             	mov    %eax,0x14(%ebp)
f0101106:	eb 10                	jmp    f0101118 <vprintfmt+0x38e>
	else
		return va_arg(*ap, unsigned int);
f0101108:	8b 45 14             	mov    0x14(%ebp),%eax
f010110b:	8b 10                	mov    (%eax),%edx
f010110d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101112:	8d 40 04             	lea    0x4(%eax),%eax
f0101115:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101118:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010111d:	e9 9d 00 00 00       	jmp    f01011bf <vprintfmt+0x435>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101122:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101126:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010112d:	ff d7                	call   *%edi
			putch('X', putdat);
f010112f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101133:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010113a:	ff d7                	call   *%edi
			putch('X', putdat);
f010113c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101140:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101147:	ff d7                	call   *%edi
			break;
f0101149:	e9 52 fc ff ff       	jmp    f0100da0 <vprintfmt+0x16>

		// pointer
		case 'p':
			putch('0', putdat);
f010114e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101152:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101159:	ff d7                	call   *%edi
			putch('x', putdat);
f010115b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010115f:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101166:	ff d7                	call   *%edi
			num = (unsigned long long)
f0101168:	8b 45 14             	mov    0x14(%ebp),%eax
f010116b:	8b 10                	mov    (%eax),%edx
f010116d:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f0101172:	8d 40 04             	lea    0x4(%eax),%eax
f0101175:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101178:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010117d:	eb 40                	jmp    f01011bf <vprintfmt+0x435>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010117f:	83 f9 01             	cmp    $0x1,%ecx
f0101182:	7e 10                	jle    f0101194 <vprintfmt+0x40a>
		return va_arg(*ap, unsigned long long);
f0101184:	8b 45 14             	mov    0x14(%ebp),%eax
f0101187:	8b 10                	mov    (%eax),%edx
f0101189:	8b 48 04             	mov    0x4(%eax),%ecx
f010118c:	8d 40 08             	lea    0x8(%eax),%eax
f010118f:	89 45 14             	mov    %eax,0x14(%ebp)
f0101192:	eb 26                	jmp    f01011ba <vprintfmt+0x430>
	else if (lflag)
f0101194:	85 c9                	test   %ecx,%ecx
f0101196:	74 12                	je     f01011aa <vprintfmt+0x420>
		return va_arg(*ap, unsigned long);
f0101198:	8b 45 14             	mov    0x14(%ebp),%eax
f010119b:	8b 10                	mov    (%eax),%edx
f010119d:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011a2:	8d 40 04             	lea    0x4(%eax),%eax
f01011a5:	89 45 14             	mov    %eax,0x14(%ebp)
f01011a8:	eb 10                	jmp    f01011ba <vprintfmt+0x430>
	else
		return va_arg(*ap, unsigned int);
f01011aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ad:	8b 10                	mov    (%eax),%edx
f01011af:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011b4:	8d 40 04             	lea    0x4(%eax),%eax
f01011b7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01011ba:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011bf:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f01011c3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01011c7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01011ca:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01011ce:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011d2:	89 14 24             	mov    %edx,(%esp)
f01011d5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01011d9:	89 da                	mov    %ebx,%edx
f01011db:	89 f8                	mov    %edi,%eax
f01011dd:	e8 6e fa ff ff       	call   f0100c50 <printnum>
			break;
f01011e2:	e9 b9 fb ff ff       	jmp    f0100da0 <vprintfmt+0x16>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011e7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011eb:	89 14 24             	mov    %edx,(%esp)
f01011ee:	ff d7                	call   *%edi
			break;
f01011f0:	e9 ab fb ff ff       	jmp    f0100da0 <vprintfmt+0x16>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011f5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011f9:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101200:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101202:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101206:	0f 84 91 fb ff ff    	je     f0100d9d <vprintfmt+0x13>
f010120c:	89 75 10             	mov    %esi,0x10(%ebp)
f010120f:	89 f0                	mov    %esi,%eax
f0101211:	83 e8 01             	sub    $0x1,%eax
f0101214:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101218:	75 f7                	jne    f0101211 <vprintfmt+0x487>
f010121a:	89 45 10             	mov    %eax,0x10(%ebp)
f010121d:	e9 7e fb ff ff       	jmp    f0100da0 <vprintfmt+0x16>
				/* do nothing */;
			break;
		}
	}
}
f0101222:	83 c4 3c             	add    $0x3c,%esp
f0101225:	5b                   	pop    %ebx
f0101226:	5e                   	pop    %esi
f0101227:	5f                   	pop    %edi
f0101228:	5d                   	pop    %ebp
f0101229:	c3                   	ret    

f010122a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010122a:	55                   	push   %ebp
f010122b:	89 e5                	mov    %esp,%ebp
f010122d:	83 ec 28             	sub    $0x28,%esp
f0101230:	8b 45 08             	mov    0x8(%ebp),%eax
f0101233:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101236:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101239:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010123d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101240:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101247:	85 c0                	test   %eax,%eax
f0101249:	74 30                	je     f010127b <vsnprintf+0x51>
f010124b:	85 d2                	test   %edx,%edx
f010124d:	7e 2c                	jle    f010127b <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010124f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101252:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101256:	8b 45 10             	mov    0x10(%ebp),%eax
f0101259:	89 44 24 08          	mov    %eax,0x8(%esp)
f010125d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101260:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101264:	c7 04 24 45 0d 10 f0 	movl   $0xf0100d45,(%esp)
f010126b:	e8 1a fb ff ff       	call   f0100d8a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101270:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101273:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101276:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101279:	eb 05                	jmp    f0101280 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010127b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101280:	c9                   	leave  
f0101281:	c3                   	ret    

f0101282 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101282:	55                   	push   %ebp
f0101283:	89 e5                	mov    %esp,%ebp
f0101285:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101288:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010128b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010128f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101292:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101296:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101299:	89 44 24 04          	mov    %eax,0x4(%esp)
f010129d:	8b 45 08             	mov    0x8(%ebp),%eax
f01012a0:	89 04 24             	mov    %eax,(%esp)
f01012a3:	e8 82 ff ff ff       	call   f010122a <vsnprintf>
	va_end(ap);

	return rc;
}
f01012a8:	c9                   	leave  
f01012a9:	c3                   	ret    
f01012aa:	66 90                	xchg   %ax,%ax
f01012ac:	66 90                	xchg   %ax,%ax
f01012ae:	66 90                	xchg   %ax,%ax

f01012b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012b0:	55                   	push   %ebp
f01012b1:	89 e5                	mov    %esp,%ebp
f01012b3:	57                   	push   %edi
f01012b4:	56                   	push   %esi
f01012b5:	53                   	push   %ebx
f01012b6:	83 ec 1c             	sub    $0x1c,%esp
f01012b9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012bc:	85 c0                	test   %eax,%eax
f01012be:	74 10                	je     f01012d0 <readline+0x20>
		cprintf("%s", prompt);
f01012c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c4:	c7 04 24 82 1f 10 f0 	movl   $0xf0101f82,(%esp)
f01012cb:	e8 68 f6 ff ff       	call   f0100938 <cprintf>

	i = 0;
	echoing = iscons(0);
f01012d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012d7:	e8 a6 f3 ff ff       	call   f0100682 <iscons>
f01012dc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01012de:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01012e3:	e8 89 f3 ff ff       	call   f0100671 <getchar>
f01012e8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012ea:	85 c0                	test   %eax,%eax
f01012ec:	79 17                	jns    f0101305 <readline+0x55>
			cprintf("read error: %e\n", c);
f01012ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f2:	c7 04 24 80 21 10 f0 	movl   $0xf0102180,(%esp)
f01012f9:	e8 3a f6 ff ff       	call   f0100938 <cprintf>
			return NULL;
f01012fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0101303:	eb 6d                	jmp    f0101372 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101305:	83 f8 7f             	cmp    $0x7f,%eax
f0101308:	74 05                	je     f010130f <readline+0x5f>
f010130a:	83 f8 08             	cmp    $0x8,%eax
f010130d:	75 19                	jne    f0101328 <readline+0x78>
f010130f:	85 f6                	test   %esi,%esi
f0101311:	7e 15                	jle    f0101328 <readline+0x78>
			if (echoing)
f0101313:	85 ff                	test   %edi,%edi
f0101315:	74 0c                	je     f0101323 <readline+0x73>
				cputchar('\b');
f0101317:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010131e:	e8 3e f3 ff ff       	call   f0100661 <cputchar>
			i--;
f0101323:	83 ee 01             	sub    $0x1,%esi
f0101326:	eb bb                	jmp    f01012e3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101328:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010132e:	7f 1c                	jg     f010134c <readline+0x9c>
f0101330:	83 fb 1f             	cmp    $0x1f,%ebx
f0101333:	7e 17                	jle    f010134c <readline+0x9c>
			if (echoing)
f0101335:	85 ff                	test   %edi,%edi
f0101337:	74 08                	je     f0101341 <readline+0x91>
				cputchar(c);
f0101339:	89 1c 24             	mov    %ebx,(%esp)
f010133c:	e8 20 f3 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101341:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101347:	8d 76 01             	lea    0x1(%esi),%esi
f010134a:	eb 97                	jmp    f01012e3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010134c:	83 fb 0d             	cmp    $0xd,%ebx
f010134f:	74 05                	je     f0101356 <readline+0xa6>
f0101351:	83 fb 0a             	cmp    $0xa,%ebx
f0101354:	75 8d                	jne    f01012e3 <readline+0x33>
			if (echoing)
f0101356:	85 ff                	test   %edi,%edi
f0101358:	74 0c                	je     f0101366 <readline+0xb6>
				cputchar('\n');
f010135a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101361:	e8 fb f2 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f0101366:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010136d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101372:	83 c4 1c             	add    $0x1c,%esp
f0101375:	5b                   	pop    %ebx
f0101376:	5e                   	pop    %esi
f0101377:	5f                   	pop    %edi
f0101378:	5d                   	pop    %ebp
f0101379:	c3                   	ret    
f010137a:	66 90                	xchg   %ax,%ax
f010137c:	66 90                	xchg   %ax,%ax
f010137e:	66 90                	xchg   %ax,%ax

f0101380 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101380:	55                   	push   %ebp
f0101381:	89 e5                	mov    %esp,%ebp
f0101383:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101386:	80 3a 00             	cmpb   $0x0,(%edx)
f0101389:	74 10                	je     f010139b <strlen+0x1b>
f010138b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101390:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101393:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101397:	75 f7                	jne    f0101390 <strlen+0x10>
f0101399:	eb 05                	jmp    f01013a0 <strlen+0x20>
f010139b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01013a0:	5d                   	pop    %ebp
f01013a1:	c3                   	ret    

f01013a2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013a2:	55                   	push   %ebp
f01013a3:	89 e5                	mov    %esp,%ebp
f01013a5:	53                   	push   %ebx
f01013a6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01013a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013ac:	85 c9                	test   %ecx,%ecx
f01013ae:	74 1c                	je     f01013cc <strnlen+0x2a>
f01013b0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01013b3:	74 1e                	je     f01013d3 <strnlen+0x31>
f01013b5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01013ba:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013bc:	39 ca                	cmp    %ecx,%edx
f01013be:	74 18                	je     f01013d8 <strnlen+0x36>
f01013c0:	83 c2 01             	add    $0x1,%edx
f01013c3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01013c8:	75 f0                	jne    f01013ba <strnlen+0x18>
f01013ca:	eb 0c                	jmp    f01013d8 <strnlen+0x36>
f01013cc:	b8 00 00 00 00       	mov    $0x0,%eax
f01013d1:	eb 05                	jmp    f01013d8 <strnlen+0x36>
f01013d3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01013d8:	5b                   	pop    %ebx
f01013d9:	5d                   	pop    %ebp
f01013da:	c3                   	ret    

f01013db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013db:	55                   	push   %ebp
f01013dc:	89 e5                	mov    %esp,%ebp
f01013de:	53                   	push   %ebx
f01013df:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013e5:	89 c2                	mov    %eax,%edx
f01013e7:	83 c2 01             	add    $0x1,%edx
f01013ea:	83 c1 01             	add    $0x1,%ecx
f01013ed:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01013f1:	88 5a ff             	mov    %bl,-0x1(%edx)
f01013f4:	84 db                	test   %bl,%bl
f01013f6:	75 ef                	jne    f01013e7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013f8:	5b                   	pop    %ebx
f01013f9:	5d                   	pop    %ebp
f01013fa:	c3                   	ret    

f01013fb <strcat>:

char *
strcat(char *dst, const char *src)
{
f01013fb:	55                   	push   %ebp
f01013fc:	89 e5                	mov    %esp,%ebp
f01013fe:	53                   	push   %ebx
f01013ff:	83 ec 08             	sub    $0x8,%esp
f0101402:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101405:	89 1c 24             	mov    %ebx,(%esp)
f0101408:	e8 73 ff ff ff       	call   f0101380 <strlen>
	strcpy(dst + len, src);
f010140d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101410:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101414:	01 d8                	add    %ebx,%eax
f0101416:	89 04 24             	mov    %eax,(%esp)
f0101419:	e8 bd ff ff ff       	call   f01013db <strcpy>
	return dst;
}
f010141e:	89 d8                	mov    %ebx,%eax
f0101420:	83 c4 08             	add    $0x8,%esp
f0101423:	5b                   	pop    %ebx
f0101424:	5d                   	pop    %ebp
f0101425:	c3                   	ret    

f0101426 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101426:	55                   	push   %ebp
f0101427:	89 e5                	mov    %esp,%ebp
f0101429:	56                   	push   %esi
f010142a:	53                   	push   %ebx
f010142b:	8b 75 08             	mov    0x8(%ebp),%esi
f010142e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101431:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101434:	85 db                	test   %ebx,%ebx
f0101436:	74 17                	je     f010144f <strncpy+0x29>
f0101438:	01 f3                	add    %esi,%ebx
f010143a:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f010143c:	83 c1 01             	add    $0x1,%ecx
f010143f:	0f b6 02             	movzbl (%edx),%eax
f0101442:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101445:	80 3a 01             	cmpb   $0x1,(%edx)
f0101448:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010144b:	39 d9                	cmp    %ebx,%ecx
f010144d:	75 ed                	jne    f010143c <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010144f:	89 f0                	mov    %esi,%eax
f0101451:	5b                   	pop    %ebx
f0101452:	5e                   	pop    %esi
f0101453:	5d                   	pop    %ebp
f0101454:	c3                   	ret    

f0101455 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101455:	55                   	push   %ebp
f0101456:	89 e5                	mov    %esp,%ebp
f0101458:	57                   	push   %edi
f0101459:	56                   	push   %esi
f010145a:	53                   	push   %ebx
f010145b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010145e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101461:	8b 75 10             	mov    0x10(%ebp),%esi
f0101464:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101466:	85 f6                	test   %esi,%esi
f0101468:	74 34                	je     f010149e <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010146a:	83 fe 01             	cmp    $0x1,%esi
f010146d:	74 26                	je     f0101495 <strlcpy+0x40>
f010146f:	0f b6 0b             	movzbl (%ebx),%ecx
f0101472:	84 c9                	test   %cl,%cl
f0101474:	74 23                	je     f0101499 <strlcpy+0x44>
f0101476:	83 ee 02             	sub    $0x2,%esi
f0101479:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f010147e:	83 c0 01             	add    $0x1,%eax
f0101481:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101484:	39 f2                	cmp    %esi,%edx
f0101486:	74 13                	je     f010149b <strlcpy+0x46>
f0101488:	83 c2 01             	add    $0x1,%edx
f010148b:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010148f:	84 c9                	test   %cl,%cl
f0101491:	75 eb                	jne    f010147e <strlcpy+0x29>
f0101493:	eb 06                	jmp    f010149b <strlcpy+0x46>
f0101495:	89 f8                	mov    %edi,%eax
f0101497:	eb 02                	jmp    f010149b <strlcpy+0x46>
f0101499:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f010149b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010149e:	29 f8                	sub    %edi,%eax
}
f01014a0:	5b                   	pop    %ebx
f01014a1:	5e                   	pop    %esi
f01014a2:	5f                   	pop    %edi
f01014a3:	5d                   	pop    %ebp
f01014a4:	c3                   	ret    

f01014a5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014a5:	55                   	push   %ebp
f01014a6:	89 e5                	mov    %esp,%ebp
f01014a8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014ab:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014ae:	0f b6 01             	movzbl (%ecx),%eax
f01014b1:	84 c0                	test   %al,%al
f01014b3:	74 15                	je     f01014ca <strcmp+0x25>
f01014b5:	3a 02                	cmp    (%edx),%al
f01014b7:	75 11                	jne    f01014ca <strcmp+0x25>
		p++, q++;
f01014b9:	83 c1 01             	add    $0x1,%ecx
f01014bc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014bf:	0f b6 01             	movzbl (%ecx),%eax
f01014c2:	84 c0                	test   %al,%al
f01014c4:	74 04                	je     f01014ca <strcmp+0x25>
f01014c6:	3a 02                	cmp    (%edx),%al
f01014c8:	74 ef                	je     f01014b9 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014ca:	0f b6 c0             	movzbl %al,%eax
f01014cd:	0f b6 12             	movzbl (%edx),%edx
f01014d0:	29 d0                	sub    %edx,%eax
}
f01014d2:	5d                   	pop    %ebp
f01014d3:	c3                   	ret    

f01014d4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014d4:	55                   	push   %ebp
f01014d5:	89 e5                	mov    %esp,%ebp
f01014d7:	56                   	push   %esi
f01014d8:	53                   	push   %ebx
f01014d9:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014dc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014df:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01014e2:	85 f6                	test   %esi,%esi
f01014e4:	74 29                	je     f010150f <strncmp+0x3b>
f01014e6:	0f b6 03             	movzbl (%ebx),%eax
f01014e9:	84 c0                	test   %al,%al
f01014eb:	74 30                	je     f010151d <strncmp+0x49>
f01014ed:	3a 02                	cmp    (%edx),%al
f01014ef:	75 2c                	jne    f010151d <strncmp+0x49>
f01014f1:	8d 43 01             	lea    0x1(%ebx),%eax
f01014f4:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f01014f6:	89 c3                	mov    %eax,%ebx
f01014f8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014fb:	39 f0                	cmp    %esi,%eax
f01014fd:	74 17                	je     f0101516 <strncmp+0x42>
f01014ff:	0f b6 08             	movzbl (%eax),%ecx
f0101502:	84 c9                	test   %cl,%cl
f0101504:	74 17                	je     f010151d <strncmp+0x49>
f0101506:	83 c0 01             	add    $0x1,%eax
f0101509:	3a 0a                	cmp    (%edx),%cl
f010150b:	74 e9                	je     f01014f6 <strncmp+0x22>
f010150d:	eb 0e                	jmp    f010151d <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f010150f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101514:	eb 0f                	jmp    f0101525 <strncmp+0x51>
f0101516:	b8 00 00 00 00       	mov    $0x0,%eax
f010151b:	eb 08                	jmp    f0101525 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010151d:	0f b6 03             	movzbl (%ebx),%eax
f0101520:	0f b6 12             	movzbl (%edx),%edx
f0101523:	29 d0                	sub    %edx,%eax
}
f0101525:	5b                   	pop    %ebx
f0101526:	5e                   	pop    %esi
f0101527:	5d                   	pop    %ebp
f0101528:	c3                   	ret    

f0101529 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101529:	55                   	push   %ebp
f010152a:	89 e5                	mov    %esp,%ebp
f010152c:	53                   	push   %ebx
f010152d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101530:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101533:	0f b6 18             	movzbl (%eax),%ebx
f0101536:	84 db                	test   %bl,%bl
f0101538:	74 1d                	je     f0101557 <strchr+0x2e>
f010153a:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f010153c:	38 d3                	cmp    %dl,%bl
f010153e:	75 06                	jne    f0101546 <strchr+0x1d>
f0101540:	eb 1a                	jmp    f010155c <strchr+0x33>
f0101542:	38 ca                	cmp    %cl,%dl
f0101544:	74 16                	je     f010155c <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101546:	83 c0 01             	add    $0x1,%eax
f0101549:	0f b6 10             	movzbl (%eax),%edx
f010154c:	84 d2                	test   %dl,%dl
f010154e:	75 f2                	jne    f0101542 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101550:	b8 00 00 00 00       	mov    $0x0,%eax
f0101555:	eb 05                	jmp    f010155c <strchr+0x33>
f0101557:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010155c:	5b                   	pop    %ebx
f010155d:	5d                   	pop    %ebp
f010155e:	c3                   	ret    

f010155f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010155f:	55                   	push   %ebp
f0101560:	89 e5                	mov    %esp,%ebp
f0101562:	53                   	push   %ebx
f0101563:	8b 45 08             	mov    0x8(%ebp),%eax
f0101566:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101569:	0f b6 18             	movzbl (%eax),%ebx
f010156c:	84 db                	test   %bl,%bl
f010156e:	74 16                	je     f0101586 <strfind+0x27>
f0101570:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101572:	38 d3                	cmp    %dl,%bl
f0101574:	75 06                	jne    f010157c <strfind+0x1d>
f0101576:	eb 0e                	jmp    f0101586 <strfind+0x27>
f0101578:	38 ca                	cmp    %cl,%dl
f010157a:	74 0a                	je     f0101586 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010157c:	83 c0 01             	add    $0x1,%eax
f010157f:	0f b6 10             	movzbl (%eax),%edx
f0101582:	84 d2                	test   %dl,%dl
f0101584:	75 f2                	jne    f0101578 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f0101586:	5b                   	pop    %ebx
f0101587:	5d                   	pop    %ebp
f0101588:	c3                   	ret    

f0101589 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101589:	55                   	push   %ebp
f010158a:	89 e5                	mov    %esp,%ebp
f010158c:	57                   	push   %edi
f010158d:	56                   	push   %esi
f010158e:	53                   	push   %ebx
f010158f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101592:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101595:	85 c9                	test   %ecx,%ecx
f0101597:	74 36                	je     f01015cf <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101599:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010159f:	75 28                	jne    f01015c9 <memset+0x40>
f01015a1:	f6 c1 03             	test   $0x3,%cl
f01015a4:	75 23                	jne    f01015c9 <memset+0x40>
		c &= 0xFF;
f01015a6:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015aa:	89 d3                	mov    %edx,%ebx
f01015ac:	c1 e3 08             	shl    $0x8,%ebx
f01015af:	89 d6                	mov    %edx,%esi
f01015b1:	c1 e6 18             	shl    $0x18,%esi
f01015b4:	89 d0                	mov    %edx,%eax
f01015b6:	c1 e0 10             	shl    $0x10,%eax
f01015b9:	09 f0                	or     %esi,%eax
f01015bb:	09 c2                	or     %eax,%edx
f01015bd:	89 d0                	mov    %edx,%eax
f01015bf:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015c1:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01015c4:	fc                   	cld    
f01015c5:	f3 ab                	rep stos %eax,%es:(%edi)
f01015c7:	eb 06                	jmp    f01015cf <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015c9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015cc:	fc                   	cld    
f01015cd:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015cf:	89 f8                	mov    %edi,%eax
f01015d1:	5b                   	pop    %ebx
f01015d2:	5e                   	pop    %esi
f01015d3:	5f                   	pop    %edi
f01015d4:	5d                   	pop    %ebp
f01015d5:	c3                   	ret    

f01015d6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015d6:	55                   	push   %ebp
f01015d7:	89 e5                	mov    %esp,%ebp
f01015d9:	57                   	push   %edi
f01015da:	56                   	push   %esi
f01015db:	8b 45 08             	mov    0x8(%ebp),%eax
f01015de:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015e1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015e4:	39 c6                	cmp    %eax,%esi
f01015e6:	73 35                	jae    f010161d <memmove+0x47>
f01015e8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015eb:	39 d0                	cmp    %edx,%eax
f01015ed:	73 2e                	jae    f010161d <memmove+0x47>
		s += n;
		d += n;
f01015ef:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01015f2:	89 d6                	mov    %edx,%esi
f01015f4:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015f6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015fc:	75 13                	jne    f0101611 <memmove+0x3b>
f01015fe:	f6 c1 03             	test   $0x3,%cl
f0101601:	75 0e                	jne    f0101611 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101603:	83 ef 04             	sub    $0x4,%edi
f0101606:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101609:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010160c:	fd                   	std    
f010160d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010160f:	eb 09                	jmp    f010161a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101611:	83 ef 01             	sub    $0x1,%edi
f0101614:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101617:	fd                   	std    
f0101618:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010161a:	fc                   	cld    
f010161b:	eb 1d                	jmp    f010163a <memmove+0x64>
f010161d:	89 f2                	mov    %esi,%edx
f010161f:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101621:	f6 c2 03             	test   $0x3,%dl
f0101624:	75 0f                	jne    f0101635 <memmove+0x5f>
f0101626:	f6 c1 03             	test   $0x3,%cl
f0101629:	75 0a                	jne    f0101635 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010162b:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010162e:	89 c7                	mov    %eax,%edi
f0101630:	fc                   	cld    
f0101631:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101633:	eb 05                	jmp    f010163a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101635:	89 c7                	mov    %eax,%edi
f0101637:	fc                   	cld    
f0101638:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010163a:	5e                   	pop    %esi
f010163b:	5f                   	pop    %edi
f010163c:	5d                   	pop    %ebp
f010163d:	c3                   	ret    

f010163e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010163e:	55                   	push   %ebp
f010163f:	89 e5                	mov    %esp,%ebp
f0101641:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101644:	8b 45 10             	mov    0x10(%ebp),%eax
f0101647:	89 44 24 08          	mov    %eax,0x8(%esp)
f010164b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010164e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101652:	8b 45 08             	mov    0x8(%ebp),%eax
f0101655:	89 04 24             	mov    %eax,(%esp)
f0101658:	e8 79 ff ff ff       	call   f01015d6 <memmove>
}
f010165d:	c9                   	leave  
f010165e:	c3                   	ret    

f010165f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010165f:	55                   	push   %ebp
f0101660:	89 e5                	mov    %esp,%ebp
f0101662:	57                   	push   %edi
f0101663:	56                   	push   %esi
f0101664:	53                   	push   %ebx
f0101665:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101668:	8b 75 0c             	mov    0xc(%ebp),%esi
f010166b:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010166e:	8d 78 ff             	lea    -0x1(%eax),%edi
f0101671:	85 c0                	test   %eax,%eax
f0101673:	74 36                	je     f01016ab <memcmp+0x4c>
		if (*s1 != *s2)
f0101675:	0f b6 03             	movzbl (%ebx),%eax
f0101678:	0f b6 0e             	movzbl (%esi),%ecx
f010167b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101680:	38 c8                	cmp    %cl,%al
f0101682:	74 1c                	je     f01016a0 <memcmp+0x41>
f0101684:	eb 10                	jmp    f0101696 <memcmp+0x37>
f0101686:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010168b:	83 c2 01             	add    $0x1,%edx
f010168e:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101692:	38 c8                	cmp    %cl,%al
f0101694:	74 0a                	je     f01016a0 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0101696:	0f b6 c0             	movzbl %al,%eax
f0101699:	0f b6 c9             	movzbl %cl,%ecx
f010169c:	29 c8                	sub    %ecx,%eax
f010169e:	eb 10                	jmp    f01016b0 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016a0:	39 fa                	cmp    %edi,%edx
f01016a2:	75 e2                	jne    f0101686 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01016a9:	eb 05                	jmp    f01016b0 <memcmp+0x51>
f01016ab:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016b0:	5b                   	pop    %ebx
f01016b1:	5e                   	pop    %esi
f01016b2:	5f                   	pop    %edi
f01016b3:	5d                   	pop    %ebp
f01016b4:	c3                   	ret    

f01016b5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016b5:	55                   	push   %ebp
f01016b6:	89 e5                	mov    %esp,%ebp
f01016b8:	53                   	push   %ebx
f01016b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01016bc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01016bf:	89 c2                	mov    %eax,%edx
f01016c1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016c4:	39 d0                	cmp    %edx,%eax
f01016c6:	73 13                	jae    f01016db <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016c8:	89 d9                	mov    %ebx,%ecx
f01016ca:	38 18                	cmp    %bl,(%eax)
f01016cc:	75 06                	jne    f01016d4 <memfind+0x1f>
f01016ce:	eb 0b                	jmp    f01016db <memfind+0x26>
f01016d0:	38 08                	cmp    %cl,(%eax)
f01016d2:	74 07                	je     f01016db <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016d4:	83 c0 01             	add    $0x1,%eax
f01016d7:	39 d0                	cmp    %edx,%eax
f01016d9:	75 f5                	jne    f01016d0 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016db:	5b                   	pop    %ebx
f01016dc:	5d                   	pop    %ebp
f01016dd:	c3                   	ret    

f01016de <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016de:	55                   	push   %ebp
f01016df:	89 e5                	mov    %esp,%ebp
f01016e1:	57                   	push   %edi
f01016e2:	56                   	push   %esi
f01016e3:	53                   	push   %ebx
f01016e4:	8b 55 08             	mov    0x8(%ebp),%edx
f01016e7:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016ea:	0f b6 0a             	movzbl (%edx),%ecx
f01016ed:	80 f9 09             	cmp    $0x9,%cl
f01016f0:	74 05                	je     f01016f7 <strtol+0x19>
f01016f2:	80 f9 20             	cmp    $0x20,%cl
f01016f5:	75 10                	jne    f0101707 <strtol+0x29>
		s++;
f01016f7:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016fa:	0f b6 0a             	movzbl (%edx),%ecx
f01016fd:	80 f9 09             	cmp    $0x9,%cl
f0101700:	74 f5                	je     f01016f7 <strtol+0x19>
f0101702:	80 f9 20             	cmp    $0x20,%cl
f0101705:	74 f0                	je     f01016f7 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101707:	80 f9 2b             	cmp    $0x2b,%cl
f010170a:	75 0a                	jne    f0101716 <strtol+0x38>
		s++;
f010170c:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010170f:	bf 00 00 00 00       	mov    $0x0,%edi
f0101714:	eb 11                	jmp    f0101727 <strtol+0x49>
f0101716:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010171b:	80 f9 2d             	cmp    $0x2d,%cl
f010171e:	75 07                	jne    f0101727 <strtol+0x49>
		s++, neg = 1;
f0101720:	83 c2 01             	add    $0x1,%edx
f0101723:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101727:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f010172c:	75 15                	jne    f0101743 <strtol+0x65>
f010172e:	80 3a 30             	cmpb   $0x30,(%edx)
f0101731:	75 10                	jne    f0101743 <strtol+0x65>
f0101733:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101737:	75 0a                	jne    f0101743 <strtol+0x65>
		s += 2, base = 16;
f0101739:	83 c2 02             	add    $0x2,%edx
f010173c:	b8 10 00 00 00       	mov    $0x10,%eax
f0101741:	eb 10                	jmp    f0101753 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f0101743:	85 c0                	test   %eax,%eax
f0101745:	75 0c                	jne    f0101753 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101747:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101749:	80 3a 30             	cmpb   $0x30,(%edx)
f010174c:	75 05                	jne    f0101753 <strtol+0x75>
		s++, base = 8;
f010174e:	83 c2 01             	add    $0x1,%edx
f0101751:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0101753:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101758:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010175b:	0f b6 0a             	movzbl (%edx),%ecx
f010175e:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101761:	89 f0                	mov    %esi,%eax
f0101763:	3c 09                	cmp    $0x9,%al
f0101765:	77 08                	ja     f010176f <strtol+0x91>
			dig = *s - '0';
f0101767:	0f be c9             	movsbl %cl,%ecx
f010176a:	83 e9 30             	sub    $0x30,%ecx
f010176d:	eb 20                	jmp    f010178f <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f010176f:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101772:	89 f0                	mov    %esi,%eax
f0101774:	3c 19                	cmp    $0x19,%al
f0101776:	77 08                	ja     f0101780 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0101778:	0f be c9             	movsbl %cl,%ecx
f010177b:	83 e9 57             	sub    $0x57,%ecx
f010177e:	eb 0f                	jmp    f010178f <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f0101780:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0101783:	89 f0                	mov    %esi,%eax
f0101785:	3c 19                	cmp    $0x19,%al
f0101787:	77 16                	ja     f010179f <strtol+0xc1>
			dig = *s - 'A' + 10;
f0101789:	0f be c9             	movsbl %cl,%ecx
f010178c:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010178f:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0101792:	7d 0f                	jge    f01017a3 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101794:	83 c2 01             	add    $0x1,%edx
f0101797:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f010179b:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f010179d:	eb bc                	jmp    f010175b <strtol+0x7d>
f010179f:	89 d8                	mov    %ebx,%eax
f01017a1:	eb 02                	jmp    f01017a5 <strtol+0xc7>
f01017a3:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01017a5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017a9:	74 05                	je     f01017b0 <strtol+0xd2>
		*endptr = (char *) s;
f01017ab:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017ae:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01017b0:	f7 d8                	neg    %eax
f01017b2:	85 ff                	test   %edi,%edi
f01017b4:	0f 44 c3             	cmove  %ebx,%eax
}
f01017b7:	5b                   	pop    %ebx
f01017b8:	5e                   	pop    %esi
f01017b9:	5f                   	pop    %edi
f01017ba:	5d                   	pop    %ebp
f01017bb:	c3                   	ret    
f01017bc:	66 90                	xchg   %ax,%ax
f01017be:	66 90                	xchg   %ax,%ax

f01017c0 <__udivdi3>:
f01017c0:	55                   	push   %ebp
f01017c1:	57                   	push   %edi
f01017c2:	56                   	push   %esi
f01017c3:	83 ec 0c             	sub    $0xc,%esp
f01017c6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017ca:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01017ce:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01017d2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017d6:	85 c0                	test   %eax,%eax
f01017d8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017dc:	89 ea                	mov    %ebp,%edx
f01017de:	89 0c 24             	mov    %ecx,(%esp)
f01017e1:	75 2d                	jne    f0101810 <__udivdi3+0x50>
f01017e3:	39 e9                	cmp    %ebp,%ecx
f01017e5:	77 61                	ja     f0101848 <__udivdi3+0x88>
f01017e7:	85 c9                	test   %ecx,%ecx
f01017e9:	89 ce                	mov    %ecx,%esi
f01017eb:	75 0b                	jne    f01017f8 <__udivdi3+0x38>
f01017ed:	b8 01 00 00 00       	mov    $0x1,%eax
f01017f2:	31 d2                	xor    %edx,%edx
f01017f4:	f7 f1                	div    %ecx
f01017f6:	89 c6                	mov    %eax,%esi
f01017f8:	31 d2                	xor    %edx,%edx
f01017fa:	89 e8                	mov    %ebp,%eax
f01017fc:	f7 f6                	div    %esi
f01017fe:	89 c5                	mov    %eax,%ebp
f0101800:	89 f8                	mov    %edi,%eax
f0101802:	f7 f6                	div    %esi
f0101804:	89 ea                	mov    %ebp,%edx
f0101806:	83 c4 0c             	add    $0xc,%esp
f0101809:	5e                   	pop    %esi
f010180a:	5f                   	pop    %edi
f010180b:	5d                   	pop    %ebp
f010180c:	c3                   	ret    
f010180d:	8d 76 00             	lea    0x0(%esi),%esi
f0101810:	39 e8                	cmp    %ebp,%eax
f0101812:	77 24                	ja     f0101838 <__udivdi3+0x78>
f0101814:	0f bd e8             	bsr    %eax,%ebp
f0101817:	83 f5 1f             	xor    $0x1f,%ebp
f010181a:	75 3c                	jne    f0101858 <__udivdi3+0x98>
f010181c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101820:	39 34 24             	cmp    %esi,(%esp)
f0101823:	0f 86 9f 00 00 00    	jbe    f01018c8 <__udivdi3+0x108>
f0101829:	39 d0                	cmp    %edx,%eax
f010182b:	0f 82 97 00 00 00    	jb     f01018c8 <__udivdi3+0x108>
f0101831:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101838:	31 d2                	xor    %edx,%edx
f010183a:	31 c0                	xor    %eax,%eax
f010183c:	83 c4 0c             	add    $0xc,%esp
f010183f:	5e                   	pop    %esi
f0101840:	5f                   	pop    %edi
f0101841:	5d                   	pop    %ebp
f0101842:	c3                   	ret    
f0101843:	90                   	nop
f0101844:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101848:	89 f8                	mov    %edi,%eax
f010184a:	f7 f1                	div    %ecx
f010184c:	31 d2                	xor    %edx,%edx
f010184e:	83 c4 0c             	add    $0xc,%esp
f0101851:	5e                   	pop    %esi
f0101852:	5f                   	pop    %edi
f0101853:	5d                   	pop    %ebp
f0101854:	c3                   	ret    
f0101855:	8d 76 00             	lea    0x0(%esi),%esi
f0101858:	89 e9                	mov    %ebp,%ecx
f010185a:	8b 3c 24             	mov    (%esp),%edi
f010185d:	d3 e0                	shl    %cl,%eax
f010185f:	89 c6                	mov    %eax,%esi
f0101861:	b8 20 00 00 00       	mov    $0x20,%eax
f0101866:	29 e8                	sub    %ebp,%eax
f0101868:	89 c1                	mov    %eax,%ecx
f010186a:	d3 ef                	shr    %cl,%edi
f010186c:	89 e9                	mov    %ebp,%ecx
f010186e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101872:	8b 3c 24             	mov    (%esp),%edi
f0101875:	09 74 24 08          	or     %esi,0x8(%esp)
f0101879:	89 d6                	mov    %edx,%esi
f010187b:	d3 e7                	shl    %cl,%edi
f010187d:	89 c1                	mov    %eax,%ecx
f010187f:	89 3c 24             	mov    %edi,(%esp)
f0101882:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101886:	d3 ee                	shr    %cl,%esi
f0101888:	89 e9                	mov    %ebp,%ecx
f010188a:	d3 e2                	shl    %cl,%edx
f010188c:	89 c1                	mov    %eax,%ecx
f010188e:	d3 ef                	shr    %cl,%edi
f0101890:	09 d7                	or     %edx,%edi
f0101892:	89 f2                	mov    %esi,%edx
f0101894:	89 f8                	mov    %edi,%eax
f0101896:	f7 74 24 08          	divl   0x8(%esp)
f010189a:	89 d6                	mov    %edx,%esi
f010189c:	89 c7                	mov    %eax,%edi
f010189e:	f7 24 24             	mull   (%esp)
f01018a1:	39 d6                	cmp    %edx,%esi
f01018a3:	89 14 24             	mov    %edx,(%esp)
f01018a6:	72 30                	jb     f01018d8 <__udivdi3+0x118>
f01018a8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01018ac:	89 e9                	mov    %ebp,%ecx
f01018ae:	d3 e2                	shl    %cl,%edx
f01018b0:	39 c2                	cmp    %eax,%edx
f01018b2:	73 05                	jae    f01018b9 <__udivdi3+0xf9>
f01018b4:	3b 34 24             	cmp    (%esp),%esi
f01018b7:	74 1f                	je     f01018d8 <__udivdi3+0x118>
f01018b9:	89 f8                	mov    %edi,%eax
f01018bb:	31 d2                	xor    %edx,%edx
f01018bd:	e9 7a ff ff ff       	jmp    f010183c <__udivdi3+0x7c>
f01018c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018c8:	31 d2                	xor    %edx,%edx
f01018ca:	b8 01 00 00 00       	mov    $0x1,%eax
f01018cf:	e9 68 ff ff ff       	jmp    f010183c <__udivdi3+0x7c>
f01018d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018d8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01018db:	31 d2                	xor    %edx,%edx
f01018dd:	83 c4 0c             	add    $0xc,%esp
f01018e0:	5e                   	pop    %esi
f01018e1:	5f                   	pop    %edi
f01018e2:	5d                   	pop    %ebp
f01018e3:	c3                   	ret    
f01018e4:	66 90                	xchg   %ax,%ax
f01018e6:	66 90                	xchg   %ax,%ax
f01018e8:	66 90                	xchg   %ax,%ax
f01018ea:	66 90                	xchg   %ax,%ax
f01018ec:	66 90                	xchg   %ax,%ax
f01018ee:	66 90                	xchg   %ax,%ax

f01018f0 <__umoddi3>:
f01018f0:	55                   	push   %ebp
f01018f1:	57                   	push   %edi
f01018f2:	56                   	push   %esi
f01018f3:	83 ec 14             	sub    $0x14,%esp
f01018f6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01018fa:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01018fe:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101902:	89 c7                	mov    %eax,%edi
f0101904:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101908:	8b 44 24 30          	mov    0x30(%esp),%eax
f010190c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101910:	89 34 24             	mov    %esi,(%esp)
f0101913:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101917:	85 c0                	test   %eax,%eax
f0101919:	89 c2                	mov    %eax,%edx
f010191b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010191f:	75 17                	jne    f0101938 <__umoddi3+0x48>
f0101921:	39 fe                	cmp    %edi,%esi
f0101923:	76 4b                	jbe    f0101970 <__umoddi3+0x80>
f0101925:	89 c8                	mov    %ecx,%eax
f0101927:	89 fa                	mov    %edi,%edx
f0101929:	f7 f6                	div    %esi
f010192b:	89 d0                	mov    %edx,%eax
f010192d:	31 d2                	xor    %edx,%edx
f010192f:	83 c4 14             	add    $0x14,%esp
f0101932:	5e                   	pop    %esi
f0101933:	5f                   	pop    %edi
f0101934:	5d                   	pop    %ebp
f0101935:	c3                   	ret    
f0101936:	66 90                	xchg   %ax,%ax
f0101938:	39 f8                	cmp    %edi,%eax
f010193a:	77 54                	ja     f0101990 <__umoddi3+0xa0>
f010193c:	0f bd e8             	bsr    %eax,%ebp
f010193f:	83 f5 1f             	xor    $0x1f,%ebp
f0101942:	75 5c                	jne    f01019a0 <__umoddi3+0xb0>
f0101944:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101948:	39 3c 24             	cmp    %edi,(%esp)
f010194b:	0f 87 e7 00 00 00    	ja     f0101a38 <__umoddi3+0x148>
f0101951:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101955:	29 f1                	sub    %esi,%ecx
f0101957:	19 c7                	sbb    %eax,%edi
f0101959:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010195d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101961:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101965:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101969:	83 c4 14             	add    $0x14,%esp
f010196c:	5e                   	pop    %esi
f010196d:	5f                   	pop    %edi
f010196e:	5d                   	pop    %ebp
f010196f:	c3                   	ret    
f0101970:	85 f6                	test   %esi,%esi
f0101972:	89 f5                	mov    %esi,%ebp
f0101974:	75 0b                	jne    f0101981 <__umoddi3+0x91>
f0101976:	b8 01 00 00 00       	mov    $0x1,%eax
f010197b:	31 d2                	xor    %edx,%edx
f010197d:	f7 f6                	div    %esi
f010197f:	89 c5                	mov    %eax,%ebp
f0101981:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101985:	31 d2                	xor    %edx,%edx
f0101987:	f7 f5                	div    %ebp
f0101989:	89 c8                	mov    %ecx,%eax
f010198b:	f7 f5                	div    %ebp
f010198d:	eb 9c                	jmp    f010192b <__umoddi3+0x3b>
f010198f:	90                   	nop
f0101990:	89 c8                	mov    %ecx,%eax
f0101992:	89 fa                	mov    %edi,%edx
f0101994:	83 c4 14             	add    $0x14,%esp
f0101997:	5e                   	pop    %esi
f0101998:	5f                   	pop    %edi
f0101999:	5d                   	pop    %ebp
f010199a:	c3                   	ret    
f010199b:	90                   	nop
f010199c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019a0:	8b 04 24             	mov    (%esp),%eax
f01019a3:	be 20 00 00 00       	mov    $0x20,%esi
f01019a8:	89 e9                	mov    %ebp,%ecx
f01019aa:	29 ee                	sub    %ebp,%esi
f01019ac:	d3 e2                	shl    %cl,%edx
f01019ae:	89 f1                	mov    %esi,%ecx
f01019b0:	d3 e8                	shr    %cl,%eax
f01019b2:	89 e9                	mov    %ebp,%ecx
f01019b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019b8:	8b 04 24             	mov    (%esp),%eax
f01019bb:	09 54 24 04          	or     %edx,0x4(%esp)
f01019bf:	89 fa                	mov    %edi,%edx
f01019c1:	d3 e0                	shl    %cl,%eax
f01019c3:	89 f1                	mov    %esi,%ecx
f01019c5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019c9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01019cd:	d3 ea                	shr    %cl,%edx
f01019cf:	89 e9                	mov    %ebp,%ecx
f01019d1:	d3 e7                	shl    %cl,%edi
f01019d3:	89 f1                	mov    %esi,%ecx
f01019d5:	d3 e8                	shr    %cl,%eax
f01019d7:	89 e9                	mov    %ebp,%ecx
f01019d9:	09 f8                	or     %edi,%eax
f01019db:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01019df:	f7 74 24 04          	divl   0x4(%esp)
f01019e3:	d3 e7                	shl    %cl,%edi
f01019e5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019e9:	89 d7                	mov    %edx,%edi
f01019eb:	f7 64 24 08          	mull   0x8(%esp)
f01019ef:	39 d7                	cmp    %edx,%edi
f01019f1:	89 c1                	mov    %eax,%ecx
f01019f3:	89 14 24             	mov    %edx,(%esp)
f01019f6:	72 2c                	jb     f0101a24 <__umoddi3+0x134>
f01019f8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01019fc:	72 22                	jb     f0101a20 <__umoddi3+0x130>
f01019fe:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101a02:	29 c8                	sub    %ecx,%eax
f0101a04:	19 d7                	sbb    %edx,%edi
f0101a06:	89 e9                	mov    %ebp,%ecx
f0101a08:	89 fa                	mov    %edi,%edx
f0101a0a:	d3 e8                	shr    %cl,%eax
f0101a0c:	89 f1                	mov    %esi,%ecx
f0101a0e:	d3 e2                	shl    %cl,%edx
f0101a10:	89 e9                	mov    %ebp,%ecx
f0101a12:	d3 ef                	shr    %cl,%edi
f0101a14:	09 d0                	or     %edx,%eax
f0101a16:	89 fa                	mov    %edi,%edx
f0101a18:	83 c4 14             	add    $0x14,%esp
f0101a1b:	5e                   	pop    %esi
f0101a1c:	5f                   	pop    %edi
f0101a1d:	5d                   	pop    %ebp
f0101a1e:	c3                   	ret    
f0101a1f:	90                   	nop
f0101a20:	39 d7                	cmp    %edx,%edi
f0101a22:	75 da                	jne    f01019fe <__umoddi3+0x10e>
f0101a24:	8b 14 24             	mov    (%esp),%edx
f0101a27:	89 c1                	mov    %eax,%ecx
f0101a29:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101a2d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a31:	eb cb                	jmp    f01019fe <__umoddi3+0x10e>
f0101a33:	90                   	nop
f0101a34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a38:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a3c:	0f 82 0f ff ff ff    	jb     f0101951 <__umoddi3+0x61>
f0101a42:	e9 1a ff ff ff       	jmp    f0101961 <__umoddi3+0x71>
