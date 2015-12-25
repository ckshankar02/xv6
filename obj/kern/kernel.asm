
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
f010004e:	c7 04 24 80 1b 10 f0 	movl   $0xf0101b80,(%esp)
f0100055:	e8 a5 09 00 00       	call   f01009ff <cprintf>
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
f0100082:	e8 34 07 00 00       	call   f01007bb <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 9c 1b 10 f0 	movl   $0xf0101b9c,(%esp)
f0100092:	e8 68 09 00 00       	call   f01009ff <cprintf>
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
f01000c0:	e8 e4 15 00 00       	call   f01016a9 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 1b 10 f0 	movl   $0xf0101bb7,(%esp)
f01000d9:	e8 21 09 00 00       	call   f01009ff <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 87 07 00 00       	call   f010087d <monitor>
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
f0100125:	c7 04 24 d2 1b 10 f0 	movl   $0xf0101bd2,(%esp)
f010012c:	e8 ce 08 00 00       	call   f01009ff <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 8f 08 00 00       	call   f01009cc <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 0e 1c 10 f0 	movl   $0xf0101c0e,(%esp)
f0100144:	e8 b6 08 00 00       	call   f01009ff <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 28 07 00 00       	call   f010087d <monitor>
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
f010016f:	c7 04 24 ea 1b 10 f0 	movl   $0xf0101bea,(%esp)
f0100176:	e8 84 08 00 00       	call   f01009ff <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 42 08 00 00       	call   f01009cc <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 0e 1c 10 f0 	movl   $0xf0101c0e,(%esp)
f0100191:	e8 69 08 00 00       	call   f01009ff <cprintf>
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
f0100245:	0f b6 82 60 1d 10 f0 	movzbl -0xfefe2a0(%edx),%eax
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
f0100282:	0f b6 82 60 1d 10 f0 	movzbl -0xfefe2a0(%edx),%eax
f0100289:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 40 1c 10 f0 	mov    -0xfefe3c0(,%ecx,4),%ecx
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
f01002e2:	c7 04 24 04 1c 10 f0 	movl   $0xf0101c04,(%esp)
f01002e9:	e8 11 07 00 00       	call   f01009ff <cprintf>
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
f0100499:	e8 58 12 00 00       	call   f01016f6 <memmove>
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
f010064d:	c7 04 24 10 1c 10 f0 	movl   $0xf0101c10,(%esp)
f0100654:	e8 a6 03 00 00       	call   f01009ff <cprintf>
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
f0100696:	c7 44 24 08 60 1e 10 	movl   $0xf0101e60,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 7e 1e 10 	movl   $0xf0101e7e,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 83 1e 10 f0 	movl   $0xf0101e83,(%esp)
f01006ad:	e8 4d 03 00 00       	call   f01009ff <cprintf>
f01006b2:	c7 44 24 08 1c 1f 10 	movl   $0xf0101f1c,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 8c 1e 10 	movl   $0xf0101e8c,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 83 1e 10 f0 	movl   $0xf0101e83,(%esp)
f01006c9:	e8 31 03 00 00       	call   f01009ff <cprintf>
f01006ce:	c7 44 24 08 1c 1f 10 	movl   $0xf0101f1c,0x8(%esp)
f01006d5:	f0 
f01006d6:	c7 44 24 04 95 1e 10 	movl   $0xf0101e95,0x4(%esp)
f01006dd:	f0 
f01006de:	c7 04 24 83 1e 10 f0 	movl   $0xf0101e83,(%esp)
f01006e5:	e8 15 03 00 00       	call   f01009ff <cprintf>
	return 0;
}
f01006ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ef:	c9                   	leave  
f01006f0:	c3                   	ret    

f01006f1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006f1:	55                   	push   %ebp
f01006f2:	89 e5                	mov    %esp,%ebp
f01006f4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006f7:	c7 04 24 9f 1e 10 f0 	movl   $0xf0101e9f,(%esp)
f01006fe:	e8 fc 02 00 00       	call   f01009ff <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100703:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010070a:	00 
f010070b:	c7 04 24 44 1f 10 f0 	movl   $0xf0101f44,(%esp)
f0100712:	e8 e8 02 00 00       	call   f01009ff <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100717:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010071e:	00 
f010071f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100726:	f0 
f0100727:	c7 04 24 6c 1f 10 f0 	movl   $0xf0101f6c,(%esp)
f010072e:	e8 cc 02 00 00       	call   f01009ff <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100733:	c7 44 24 08 67 1b 10 	movl   $0x101b67,0x8(%esp)
f010073a:	00 
f010073b:	c7 44 24 04 67 1b 10 	movl   $0xf0101b67,0x4(%esp)
f0100742:	f0 
f0100743:	c7 04 24 90 1f 10 f0 	movl   $0xf0101f90,(%esp)
f010074a:	e8 b0 02 00 00       	call   f01009ff <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010074f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100756:	00 
f0100757:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010075e:	f0 
f010075f:	c7 04 24 b4 1f 10 f0 	movl   $0xf0101fb4,(%esp)
f0100766:	e8 94 02 00 00       	call   f01009ff <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010076b:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100772:	00 
f0100773:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010077a:	f0 
f010077b:	c7 04 24 d8 1f 10 f0 	movl   $0xf0101fd8,(%esp)
f0100782:	e8 78 02 00 00       	call   f01009ff <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100787:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010078c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100791:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100796:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010079c:	85 c0                	test   %eax,%eax
f010079e:	0f 48 c2             	cmovs  %edx,%eax
f01007a1:	c1 f8 0a             	sar    $0xa,%eax
f01007a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a8:	c7 04 24 fc 1f 10 f0 	movl   $0xf0101ffc,(%esp)
f01007af:	e8 4b 02 00 00       	call   f01009ff <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b9:	c9                   	leave  
f01007ba:	c3                   	ret    

f01007bb <mon_backtrace>:
}


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007bb:	55                   	push   %ebp
f01007bc:	89 e5                	mov    %esp,%ebp
f01007be:	57                   	push   %edi
f01007bf:	56                   	push   %esi
f01007c0:	53                   	push   %ebx
f01007c1:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007c4:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t curr_ebp, ret_eip;
	struct Eipdebuginfo info;

	curr_ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01007c6:	c7 04 24 b8 1e 10 f0 	movl   $0xf0101eb8,(%esp)
f01007cd:	e8 2d 02 00 00       	call   f01009ff <cprintf>
	do {
		ret_eip = addr_off(curr_ebp, 1, INC);
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",curr_ebp, ret_eip, addr_off(curr_ebp, 2, INC), addr_off(curr_ebp, 3, INC), addr_off(curr_ebp,3, INC), addr_off(curr_ebp, 4, INC), addr_off(curr_ebp, 5, INC));
		debuginfo_eip(ret_eip, &info);
f01007d2:	8d 7d d0             	lea    -0x30(%ebp),%edi
	int off_byte = offset*(sizeof(uint32_t));
	if(dir == INC)
		new_addr = (uint32_t *)(addr+off_byte);
	else 
		new_addr = (uint32_t *)(addr-off_byte);
	return *new_addr;
f01007d5:	8b 73 04             	mov    0x4(%ebx),%esi
f01007d8:	8b 43 0c             	mov    0xc(%ebx),%eax

	curr_ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	do {
		ret_eip = addr_off(curr_ebp, 1, INC);
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",curr_ebp, ret_eip, addr_off(curr_ebp, 2, INC), addr_off(curr_ebp, 3, INC), addr_off(curr_ebp,3, INC), addr_off(curr_ebp, 4, INC), addr_off(curr_ebp, 5, INC));
f01007db:	8b 53 14             	mov    0x14(%ebx),%edx
f01007de:	89 54 24 1c          	mov    %edx,0x1c(%esp)
f01007e2:	8b 53 10             	mov    0x10(%ebx),%edx
f01007e5:	89 54 24 18          	mov    %edx,0x18(%esp)
f01007e9:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007ed:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007f1:	8b 43 08             	mov    0x8(%ebx),%eax
f01007f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007f8:	89 74 24 08          	mov    %esi,0x8(%esp)
f01007fc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100800:	c7 04 24 28 20 10 f0 	movl   $0xf0102028,(%esp)
f0100807:	e8 f3 01 00 00       	call   f01009ff <cprintf>
		debuginfo_eip(ret_eip, &info);
f010080c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100810:	89 34 24             	mov    %esi,(%esp)
f0100813:	e8 e5 02 00 00       	call   f0100afd <debuginfo_eip>
		cprintf("      %s:%d: %.*s+%d\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name,(ret_eip-info.eip_fn_addr));
f0100818:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010081b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010081f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100822:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100826:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100829:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010082d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100830:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100834:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100837:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083b:	c7 04 24 ca 1e 10 f0 	movl   $0xf0101eca,(%esp)
f0100842:	e8 b8 01 00 00       	call   f01009ff <cprintf>
		curr_ebp = *(uint32_t *) curr_ebp;
f0100847:	8b 1b                	mov    (%ebx),%ebx
	} while(curr_ebp);
f0100849:	85 db                	test   %ebx,%ebx
f010084b:	75 88                	jne    f01007d5 <mon_backtrace+0x1a>
	return 0;
}
f010084d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100852:	83 c4 4c             	add    $0x4c,%esp
f0100855:	5b                   	pop    %ebx
f0100856:	5e                   	pop    %esi
f0100857:	5f                   	pop    %edi
f0100858:	5d                   	pop    %ebp
f0100859:	c3                   	ret    

f010085a <addr_off>:
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

uint32_t addr_off(uint32_t addr, int offset, char dir) {
f010085a:	55                   	push   %ebp
f010085b:	89 e5                	mov    %esp,%ebp
f010085d:	53                   	push   %ebx
f010085e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100861:	8b 45 10             	mov    0x10(%ebp),%eax
	uint32_t *new_addr;
	int off_byte = offset*(sizeof(uint32_t));
f0100864:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100867:	8d 14 9d 00 00 00 00 	lea    0x0(,%ebx,4),%edx
	if(dir == INC)
		new_addr = (uint32_t *)(addr+off_byte);
f010086e:	8d 1c 0a             	lea    (%edx,%ecx,1),%ebx
f0100871:	29 d1                	sub    %edx,%ecx
f0100873:	3c 75                	cmp    $0x75,%al
f0100875:	0f 44 cb             	cmove  %ebx,%ecx
	else 
		new_addr = (uint32_t *)(addr-off_byte);
	return *new_addr;
f0100878:	8b 01                	mov    (%ecx),%eax
}
f010087a:	5b                   	pop    %ebx
f010087b:	5d                   	pop    %ebp
f010087c:	c3                   	ret    

f010087d <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010087d:	55                   	push   %ebp
f010087e:	89 e5                	mov    %esp,%ebp
f0100880:	57                   	push   %edi
f0100881:	56                   	push   %esi
f0100882:	53                   	push   %ebx
f0100883:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100886:	c7 04 24 60 20 10 f0 	movl   $0xf0102060,(%esp)
f010088d:	e8 6d 01 00 00       	call   f01009ff <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100892:	c7 04 24 84 20 10 f0 	movl   $0xf0102084,(%esp)
f0100899:	e8 61 01 00 00       	call   f01009ff <cprintf>


	while (1) {
		buf = readline("K> ");
f010089e:	c7 04 24 e0 1e 10 f0 	movl   $0xf0101ee0,(%esp)
f01008a5:	e8 26 0b 00 00       	call   f01013d0 <readline>
f01008aa:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008ac:	85 c0                	test   %eax,%eax
f01008ae:	74 ee                	je     f010089e <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008b0:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008b7:	be 00 00 00 00       	mov    $0x0,%esi
f01008bc:	eb 0a                	jmp    f01008c8 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008be:	c6 03 00             	movb   $0x0,(%ebx)
f01008c1:	89 f7                	mov    %esi,%edi
f01008c3:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008c6:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008c8:	0f b6 03             	movzbl (%ebx),%eax
f01008cb:	84 c0                	test   %al,%al
f01008cd:	74 6c                	je     f010093b <monitor+0xbe>
f01008cf:	0f be c0             	movsbl %al,%eax
f01008d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d6:	c7 04 24 e4 1e 10 f0 	movl   $0xf0101ee4,(%esp)
f01008dd:	e8 67 0d 00 00       	call   f0101649 <strchr>
f01008e2:	85 c0                	test   %eax,%eax
f01008e4:	75 d8                	jne    f01008be <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008e6:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008e9:	74 50                	je     f010093b <monitor+0xbe>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008eb:	83 fe 0f             	cmp    $0xf,%esi
f01008ee:	66 90                	xchg   %ax,%ax
f01008f0:	75 16                	jne    f0100908 <monitor+0x8b>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008f2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008f9:	00 
f01008fa:	c7 04 24 e9 1e 10 f0 	movl   $0xf0101ee9,(%esp)
f0100901:	e8 f9 00 00 00       	call   f01009ff <cprintf>
f0100906:	eb 96                	jmp    f010089e <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100908:	8d 7e 01             	lea    0x1(%esi),%edi
f010090b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f010090f:	0f b6 03             	movzbl (%ebx),%eax
f0100912:	84 c0                	test   %al,%al
f0100914:	75 0c                	jne    f0100922 <monitor+0xa5>
f0100916:	eb ae                	jmp    f01008c6 <monitor+0x49>
			buf++;
f0100918:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010091b:	0f b6 03             	movzbl (%ebx),%eax
f010091e:	84 c0                	test   %al,%al
f0100920:	74 a4                	je     f01008c6 <monitor+0x49>
f0100922:	0f be c0             	movsbl %al,%eax
f0100925:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100929:	c7 04 24 e4 1e 10 f0 	movl   $0xf0101ee4,(%esp)
f0100930:	e8 14 0d 00 00       	call   f0101649 <strchr>
f0100935:	85 c0                	test   %eax,%eax
f0100937:	74 df                	je     f0100918 <monitor+0x9b>
f0100939:	eb 8b                	jmp    f01008c6 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010093b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100942:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100943:	85 f6                	test   %esi,%esi
f0100945:	0f 84 53 ff ff ff    	je     f010089e <monitor+0x21>
f010094b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100950:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100953:	8b 04 85 c0 20 10 f0 	mov    -0xfefdf40(,%eax,4),%eax
f010095a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010095e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100961:	89 04 24             	mov    %eax,(%esp)
f0100964:	e8 5c 0c 00 00       	call   f01015c5 <strcmp>
f0100969:	85 c0                	test   %eax,%eax
f010096b:	75 24                	jne    f0100991 <monitor+0x114>
			return commands[i].func(argc, argv, tf);
f010096d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100970:	8b 55 08             	mov    0x8(%ebp),%edx
f0100973:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100977:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010097a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010097e:	89 34 24             	mov    %esi,(%esp)
f0100981:	ff 14 85 c8 20 10 f0 	call   *-0xfefdf38(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100988:	85 c0                	test   %eax,%eax
f010098a:	78 25                	js     f01009b1 <monitor+0x134>
f010098c:	e9 0d ff ff ff       	jmp    f010089e <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100991:	83 c3 01             	add    $0x1,%ebx
f0100994:	83 fb 03             	cmp    $0x3,%ebx
f0100997:	75 b7                	jne    f0100950 <monitor+0xd3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100999:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010099c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009a0:	c7 04 24 06 1f 10 f0 	movl   $0xf0101f06,(%esp)
f01009a7:	e8 53 00 00 00       	call   f01009ff <cprintf>
f01009ac:	e9 ed fe ff ff       	jmp    f010089e <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009b1:	83 c4 5c             	add    $0x5c,%esp
f01009b4:	5b                   	pop    %ebx
f01009b5:	5e                   	pop    %esi
f01009b6:	5f                   	pop    %edi
f01009b7:	5d                   	pop    %ebp
f01009b8:	c3                   	ret    

f01009b9 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009b9:	55                   	push   %ebp
f01009ba:	89 e5                	mov    %esp,%ebp
f01009bc:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01009bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01009c2:	89 04 24             	mov    %eax,(%esp)
f01009c5:	e8 97 fc ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f01009ca:	c9                   	leave  
f01009cb:	c3                   	ret    

f01009cc <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009cc:	55                   	push   %ebp
f01009cd:	89 e5                	mov    %esp,%ebp
f01009cf:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009d2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009dc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009e0:	8b 45 08             	mov    0x8(%ebp),%eax
f01009e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009e7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ee:	c7 04 24 b9 09 10 f0 	movl   $0xf01009b9,(%esp)
f01009f5:	e8 b0 04 00 00       	call   f0100eaa <vprintfmt>
	return cnt;
}
f01009fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009fd:	c9                   	leave  
f01009fe:	c3                   	ret    

f01009ff <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009ff:	55                   	push   %ebp
f0100a00:	89 e5                	mov    %esp,%ebp
f0100a02:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a05:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a08:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a0f:	89 04 24             	mov    %eax,(%esp)
f0100a12:	e8 b5 ff ff ff       	call   f01009cc <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a17:	c9                   	leave  
f0100a18:	c3                   	ret    
f0100a19:	66 90                	xchg   %ax,%ax
f0100a1b:	66 90                	xchg   %ax,%ax
f0100a1d:	66 90                	xchg   %ax,%ax
f0100a1f:	90                   	nop

f0100a20 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a20:	55                   	push   %ebp
f0100a21:	89 e5                	mov    %esp,%ebp
f0100a23:	57                   	push   %edi
f0100a24:	56                   	push   %esi
f0100a25:	53                   	push   %ebx
f0100a26:	83 ec 10             	sub    $0x10,%esp
f0100a29:	89 c6                	mov    %eax,%esi
f0100a2b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a2e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a31:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a34:	8b 1a                	mov    (%edx),%ebx
f0100a36:	8b 01                	mov    (%ecx),%eax
f0100a38:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a3b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a42:	eb 77                	jmp    f0100abb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a44:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a47:	01 d8                	add    %ebx,%eax
f0100a49:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a4e:	99                   	cltd   
f0100a4f:	f7 f9                	idiv   %ecx
f0100a51:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a53:	eb 01                	jmp    f0100a56 <stab_binsearch+0x36>
			m--;
f0100a55:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a56:	39 d9                	cmp    %ebx,%ecx
f0100a58:	7c 1d                	jl     f0100a77 <stab_binsearch+0x57>
f0100a5a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a5d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a62:	39 fa                	cmp    %edi,%edx
f0100a64:	75 ef                	jne    f0100a55 <stab_binsearch+0x35>
f0100a66:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a69:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a6c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a70:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a73:	73 18                	jae    f0100a8d <stab_binsearch+0x6d>
f0100a75:	eb 05                	jmp    f0100a7c <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a77:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a7a:	eb 3f                	jmp    f0100abb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a7c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a7f:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a81:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a84:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a8b:	eb 2e                	jmp    f0100abb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a8d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a90:	73 15                	jae    f0100aa7 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a92:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a95:	48                   	dec    %eax
f0100a96:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a99:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a9c:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a9e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100aa5:	eb 14                	jmp    f0100abb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100aa7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100aaa:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100aad:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100aaf:	ff 45 0c             	incl   0xc(%ebp)
f0100ab2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ab4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100abb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100abe:	7e 84                	jle    f0100a44 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ac0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ac4:	75 0d                	jne    f0100ad3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100ac6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ac9:	8b 00                	mov    (%eax),%eax
f0100acb:	48                   	dec    %eax
f0100acc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100acf:	89 07                	mov    %eax,(%edi)
f0100ad1:	eb 22                	jmp    f0100af5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ad6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ad8:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100adb:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100add:	eb 01                	jmp    f0100ae0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100adf:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae0:	39 c1                	cmp    %eax,%ecx
f0100ae2:	7d 0c                	jge    f0100af0 <stab_binsearch+0xd0>
f0100ae4:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100ae7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100aec:	39 fa                	cmp    %edi,%edx
f0100aee:	75 ef                	jne    f0100adf <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100af0:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100af3:	89 07                	mov    %eax,(%edi)
	}
}
f0100af5:	83 c4 10             	add    $0x10,%esp
f0100af8:	5b                   	pop    %ebx
f0100af9:	5e                   	pop    %esi
f0100afa:	5f                   	pop    %edi
f0100afb:	5d                   	pop    %ebp
f0100afc:	c3                   	ret    

f0100afd <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100afd:	55                   	push   %ebp
f0100afe:	89 e5                	mov    %esp,%ebp
f0100b00:	57                   	push   %edi
f0100b01:	56                   	push   %esi
f0100b02:	53                   	push   %ebx
f0100b03:	83 ec 3c             	sub    $0x3c,%esp
f0100b06:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b09:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b0c:	c7 03 e4 20 10 f0    	movl   $0xf01020e4,(%ebx)
	info->eip_line = 0;
f0100b12:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b19:	c7 43 08 e4 20 10 f0 	movl   $0xf01020e4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b20:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b27:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b2a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b31:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b37:	76 12                	jbe    f0100b4b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b39:	b8 19 77 10 f0       	mov    $0xf0107719,%eax
f0100b3e:	3d e1 5d 10 f0       	cmp    $0xf0105de1,%eax
f0100b43:	0f 86 e2 01 00 00    	jbe    f0100d2b <debuginfo_eip+0x22e>
f0100b49:	eb 1c                	jmp    f0100b67 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b4b:	c7 44 24 08 ee 20 10 	movl   $0xf01020ee,0x8(%esp)
f0100b52:	f0 
f0100b53:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b5a:	00 
f0100b5b:	c7 04 24 fb 20 10 f0 	movl   $0xf01020fb,(%esp)
f0100b62:	e8 91 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b67:	80 3d 18 77 10 f0 00 	cmpb   $0x0,0xf0107718
f0100b6e:	0f 85 be 01 00 00    	jne    f0100d32 <debuginfo_eip+0x235>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b74:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b7b:	b8 e0 5d 10 f0       	mov    $0xf0105de0,%eax
f0100b80:	2d 30 23 10 f0       	sub    $0xf0102330,%eax
f0100b85:	c1 f8 02             	sar    $0x2,%eax
f0100b88:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b8e:	83 e8 01             	sub    $0x1,%eax
f0100b91:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b94:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b98:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b9f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ba2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ba5:	b8 30 23 10 f0       	mov    $0xf0102330,%eax
f0100baa:	e8 71 fe ff ff       	call   f0100a20 <stab_binsearch>
	if (lfile == 0)
f0100baf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bb2:	85 c0                	test   %eax,%eax
f0100bb4:	0f 84 7f 01 00 00    	je     f0100d39 <debuginfo_eip+0x23c>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bba:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bbd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bc0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bc3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bc7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bce:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bd1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bd4:	b8 30 23 10 f0       	mov    $0xf0102330,%eax
f0100bd9:	e8 42 fe ff ff       	call   f0100a20 <stab_binsearch>

	if (lfun <= rfun) {
f0100bde:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100be1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100be4:	39 d0                	cmp    %edx,%eax
f0100be6:	7f 3d                	jg     f0100c25 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100be8:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100beb:	8d b9 30 23 10 f0    	lea    -0xfefdcd0(%ecx),%edi
f0100bf1:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bf4:	8b 89 30 23 10 f0    	mov    -0xfefdcd0(%ecx),%ecx
f0100bfa:	bf 19 77 10 f0       	mov    $0xf0107719,%edi
f0100bff:	81 ef e1 5d 10 f0    	sub    $0xf0105de1,%edi
f0100c05:	39 f9                	cmp    %edi,%ecx
f0100c07:	73 09                	jae    f0100c12 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c09:	81 c1 e1 5d 10 f0    	add    $0xf0105de1,%ecx
f0100c0f:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c12:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c15:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c18:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c1b:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c1d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c20:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c23:	eb 0f                	jmp    f0100c34 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c25:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c28:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c2b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c2e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c31:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c34:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c3b:	00 
f0100c3c:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c3f:	89 04 24             	mov    %eax,(%esp)
f0100c42:	e8 38 0a 00 00       	call   f010167f <strfind>
f0100c47:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c4a:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c4d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c51:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c58:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c5b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c5e:	b8 30 23 10 f0       	mov    $0xf0102330,%eax
f0100c63:	e8 b8 fd ff ff       	call   f0100a20 <stab_binsearch>
        if(lline <= rline) {
f0100c68:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100c6b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0100c6e:	7f 0d                	jg     f0100c7d <debuginfo_eip+0x180>
		info->eip_line = stabs[rline].n_desc;
f0100c70:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c73:	0f b7 80 36 23 10 f0 	movzwl -0xfefdcca(%eax),%eax
f0100c7a:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c7d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100c80:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c83:	39 f2                	cmp    %esi,%edx
f0100c85:	7c 5c                	jl     f0100ce3 <debuginfo_eip+0x1e6>
	       && stabs[lline].n_type != N_SOL
f0100c87:	6b c2 0c             	imul   $0xc,%edx,%eax
f0100c8a:	8d b8 30 23 10 f0    	lea    -0xfefdcd0(%eax),%edi
f0100c90:	0f b6 4f 04          	movzbl 0x4(%edi),%ecx
f0100c94:	80 f9 84             	cmp    $0x84,%cl
f0100c97:	74 2b                	je     f0100cc4 <debuginfo_eip+0x1c7>
f0100c99:	05 24 23 10 f0       	add    $0xf0102324,%eax
f0100c9e:	eb 15                	jmp    f0100cb5 <debuginfo_eip+0x1b8>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100ca0:	83 ea 01             	sub    $0x1,%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ca3:	39 f2                	cmp    %esi,%edx
f0100ca5:	7c 3c                	jl     f0100ce3 <debuginfo_eip+0x1e6>
	       && stabs[lline].n_type != N_SOL
f0100ca7:	89 c7                	mov    %eax,%edi
f0100ca9:	83 e8 0c             	sub    $0xc,%eax
f0100cac:	0f b6 48 10          	movzbl 0x10(%eax),%ecx
f0100cb0:	80 f9 84             	cmp    $0x84,%cl
f0100cb3:	74 0f                	je     f0100cc4 <debuginfo_eip+0x1c7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cb5:	80 f9 64             	cmp    $0x64,%cl
f0100cb8:	75 e6                	jne    f0100ca0 <debuginfo_eip+0x1a3>
f0100cba:	83 7f 08 00          	cmpl   $0x0,0x8(%edi)
f0100cbe:	74 e0                	je     f0100ca0 <debuginfo_eip+0x1a3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cc0:	39 d6                	cmp    %edx,%esi
f0100cc2:	7f 1f                	jg     f0100ce3 <debuginfo_eip+0x1e6>
f0100cc4:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100cc7:	8b 82 30 23 10 f0    	mov    -0xfefdcd0(%edx),%eax
f0100ccd:	ba 19 77 10 f0       	mov    $0xf0107719,%edx
f0100cd2:	81 ea e1 5d 10 f0    	sub    $0xf0105de1,%edx
f0100cd8:	39 d0                	cmp    %edx,%eax
f0100cda:	73 07                	jae    f0100ce3 <debuginfo_eip+0x1e6>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cdc:	05 e1 5d 10 f0       	add    $0xf0105de1,%eax
f0100ce1:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ce3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ce6:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ce9:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cee:	39 ca                	cmp    %ecx,%edx
f0100cf0:	7d 68                	jge    f0100d5a <debuginfo_eip+0x25d>
		for (lline = lfun + 1;
f0100cf2:	8d 42 01             	lea    0x1(%edx),%eax
f0100cf5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100cf8:	39 c1                	cmp    %eax,%ecx
f0100cfa:	7e 44                	jle    f0100d40 <debuginfo_eip+0x243>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cfc:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cff:	80 b8 34 23 10 f0 a0 	cmpb   $0xa0,-0xfefdccc(%eax)
f0100d06:	75 3f                	jne    f0100d47 <debuginfo_eip+0x24a>
f0100d08:	83 c2 02             	add    $0x2,%edx
f0100d0b:	05 24 23 10 f0       	add    $0xf0102324,%eax
f0100d10:	89 ce                	mov    %ecx,%esi
		     lline++)
			info->eip_fn_narg++;
f0100d12:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d16:	39 f2                	cmp    %esi,%edx
f0100d18:	74 34                	je     f0100d4e <debuginfo_eip+0x251>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d1a:	0f b6 48 1c          	movzbl 0x1c(%eax),%ecx
f0100d1e:	83 c2 01             	add    $0x1,%edx
f0100d21:	83 c0 0c             	add    $0xc,%eax
f0100d24:	80 f9 a0             	cmp    $0xa0,%cl
f0100d27:	74 e9                	je     f0100d12 <debuginfo_eip+0x215>
f0100d29:	eb 2a                	jmp    f0100d55 <debuginfo_eip+0x258>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d2b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d30:	eb 28                	jmp    f0100d5a <debuginfo_eip+0x25d>
f0100d32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d37:	eb 21                	jmp    f0100d5a <debuginfo_eip+0x25d>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d39:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d3e:	eb 1a                	jmp    f0100d5a <debuginfo_eip+0x25d>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d40:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d45:	eb 13                	jmp    f0100d5a <debuginfo_eip+0x25d>
f0100d47:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d4c:	eb 0c                	jmp    f0100d5a <debuginfo_eip+0x25d>
f0100d4e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d53:	eb 05                	jmp    f0100d5a <debuginfo_eip+0x25d>
f0100d55:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d5a:	83 c4 3c             	add    $0x3c,%esp
f0100d5d:	5b                   	pop    %ebx
f0100d5e:	5e                   	pop    %esi
f0100d5f:	5f                   	pop    %edi
f0100d60:	5d                   	pop    %ebp
f0100d61:	c3                   	ret    
f0100d62:	66 90                	xchg   %ax,%ax
f0100d64:	66 90                	xchg   %ax,%ax
f0100d66:	66 90                	xchg   %ax,%ax
f0100d68:	66 90                	xchg   %ax,%ax
f0100d6a:	66 90                	xchg   %ax,%ax
f0100d6c:	66 90                	xchg   %ax,%ax
f0100d6e:	66 90                	xchg   %ax,%ax

f0100d70 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d70:	55                   	push   %ebp
f0100d71:	89 e5                	mov    %esp,%ebp
f0100d73:	57                   	push   %edi
f0100d74:	56                   	push   %esi
f0100d75:	53                   	push   %ebx
f0100d76:	83 ec 3c             	sub    $0x3c,%esp
f0100d79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d7c:	89 d7                	mov    %edx,%edi
f0100d7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d81:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d84:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100d87:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100d8a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d8d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d92:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d95:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d98:	39 f1                	cmp    %esi,%ecx
f0100d9a:	72 14                	jb     f0100db0 <printnum+0x40>
f0100d9c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d9f:	76 0f                	jbe    f0100db0 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100da1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100da4:	8d 70 ff             	lea    -0x1(%eax),%esi
f0100da7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100daa:	85 f6                	test   %esi,%esi
f0100dac:	7f 60                	jg     f0100e0e <printnum+0x9e>
f0100dae:	eb 72                	jmp    f0100e22 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100db0:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100db3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100db7:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0100dba:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100dbd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100dc1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dc5:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100dc9:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100dcd:	89 c3                	mov    %eax,%ebx
f0100dcf:	89 d6                	mov    %edx,%esi
f0100dd1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100dd4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100dd7:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100ddb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100ddf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100de2:	89 04 24             	mov    %eax,(%esp)
f0100de5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100de8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dec:	e8 ef 0a 00 00       	call   f01018e0 <__udivdi3>
f0100df1:	89 d9                	mov    %ebx,%ecx
f0100df3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100df7:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100dfb:	89 04 24             	mov    %eax,(%esp)
f0100dfe:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e02:	89 fa                	mov    %edi,%edx
f0100e04:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e07:	e8 64 ff ff ff       	call   f0100d70 <printnum>
f0100e0c:	eb 14                	jmp    f0100e22 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e0e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e12:	8b 45 18             	mov    0x18(%ebp),%eax
f0100e15:	89 04 24             	mov    %eax,(%esp)
f0100e18:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e1a:	83 ee 01             	sub    $0x1,%esi
f0100e1d:	75 ef                	jne    f0100e0e <printnum+0x9e>
f0100e1f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e22:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e26:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e2a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e2d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e30:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e34:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e38:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e3b:	89 04 24             	mov    %eax,(%esp)
f0100e3e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e41:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e45:	e8 c6 0b 00 00       	call   f0101a10 <__umoddi3>
f0100e4a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e4e:	0f be 80 09 21 10 f0 	movsbl -0xfefdef7(%eax),%eax
f0100e55:	89 04 24             	mov    %eax,(%esp)
f0100e58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e5b:	ff d0                	call   *%eax
}
f0100e5d:	83 c4 3c             	add    $0x3c,%esp
f0100e60:	5b                   	pop    %ebx
f0100e61:	5e                   	pop    %esi
f0100e62:	5f                   	pop    %edi
f0100e63:	5d                   	pop    %ebp
f0100e64:	c3                   	ret    

f0100e65 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e65:	55                   	push   %ebp
f0100e66:	89 e5                	mov    %esp,%ebp
f0100e68:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e6b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e6f:	8b 10                	mov    (%eax),%edx
f0100e71:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e74:	73 0a                	jae    f0100e80 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e76:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e79:	89 08                	mov    %ecx,(%eax)
f0100e7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e7e:	88 02                	mov    %al,(%edx)
}
f0100e80:	5d                   	pop    %ebp
f0100e81:	c3                   	ret    

f0100e82 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e82:	55                   	push   %ebp
f0100e83:	89 e5                	mov    %esp,%ebp
f0100e85:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e88:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e8f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e92:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e96:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e99:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ea0:	89 04 24             	mov    %eax,(%esp)
f0100ea3:	e8 02 00 00 00       	call   f0100eaa <vprintfmt>
	va_end(ap);
}
f0100ea8:	c9                   	leave  
f0100ea9:	c3                   	ret    

f0100eaa <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100eaa:	55                   	push   %ebp
f0100eab:	89 e5                	mov    %esp,%ebp
f0100ead:	57                   	push   %edi
f0100eae:	56                   	push   %esi
f0100eaf:	53                   	push   %ebx
f0100eb0:	83 ec 3c             	sub    $0x3c,%esp
f0100eb3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100eb6:	89 df                	mov    %ebx,%edi
f0100eb8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ebb:	eb 03                	jmp    f0100ec0 <vprintfmt+0x16>
			break;

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100ebd:	89 75 10             	mov    %esi,0x10(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ec0:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ec3:	8d 70 01             	lea    0x1(%eax),%esi
f0100ec6:	0f b6 00             	movzbl (%eax),%eax
f0100ec9:	83 f8 25             	cmp    $0x25,%eax
f0100ecc:	74 2d                	je     f0100efb <vprintfmt+0x51>
			if (ch == '\0')
f0100ece:	85 c0                	test   %eax,%eax
f0100ed0:	75 14                	jne    f0100ee6 <vprintfmt+0x3c>
f0100ed2:	e9 6b 04 00 00       	jmp    f0101342 <vprintfmt+0x498>
f0100ed7:	85 c0                	test   %eax,%eax
f0100ed9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0100ee0:	0f 84 5c 04 00 00    	je     f0101342 <vprintfmt+0x498>
				return;
			putch(ch, putdat);
f0100ee6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100eea:	89 04 24             	mov    %eax,(%esp)
f0100eed:	ff d7                	call   *%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100eef:	83 c6 01             	add    $0x1,%esi
f0100ef2:	0f b6 46 ff          	movzbl -0x1(%esi),%eax
f0100ef6:	83 f8 25             	cmp    $0x25,%eax
f0100ef9:	75 dc                	jne    f0100ed7 <vprintfmt+0x2d>
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100efb:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100eff:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f06:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100f0d:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100f14:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f19:	eb 1f                	jmp    f0100f3a <vprintfmt+0x90>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f1b:	8b 75 10             	mov    0x10(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f1e:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0100f22:	eb 16                	jmp    f0100f3a <vprintfmt+0x90>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f24:	8b 75 10             	mov    0x10(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f27:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100f2b:	eb 0d                	jmp    f0100f3a <vprintfmt+0x90>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f2d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f30:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f33:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3a:	8d 46 01             	lea    0x1(%esi),%eax
f0100f3d:	89 45 10             	mov    %eax,0x10(%ebp)
f0100f40:	0f b6 06             	movzbl (%esi),%eax
f0100f43:	0f b6 d0             	movzbl %al,%edx
f0100f46:	83 e8 23             	sub    $0x23,%eax
f0100f49:	3c 55                	cmp    $0x55,%al
f0100f4b:	0f 87 c4 03 00 00    	ja     f0101315 <vprintfmt+0x46b>
f0100f51:	0f b6 c0             	movzbl %al,%eax
f0100f54:	ff 24 85 a0 21 10 f0 	jmp    *-0xfefde60(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f5b:	8d 42 d0             	lea    -0x30(%edx),%eax
f0100f5e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100f61:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100f65:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100f68:	83 fa 09             	cmp    $0x9,%edx
f0100f6b:	77 63                	ja     f0100fd0 <vprintfmt+0x126>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f6d:	8b 75 10             	mov    0x10(%ebp),%esi
f0100f70:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100f73:	8b 55 d4             	mov    -0x2c(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f76:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100f79:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100f7c:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100f80:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f83:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f86:	83 f9 09             	cmp    $0x9,%ecx
f0100f89:	76 eb                	jbe    f0100f76 <vprintfmt+0xcc>
f0100f8b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100f8e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0100f91:	eb 40                	jmp    f0100fd3 <vprintfmt+0x129>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f93:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f96:	8b 00                	mov    (%eax),%eax
f0100f98:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100f9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f9e:	8d 40 04             	lea    0x4(%eax),%eax
f0100fa1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa4:	8b 75 10             	mov    0x10(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100fa7:	eb 2a                	jmp    f0100fd3 <vprintfmt+0x129>
f0100fa9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100fac:	85 d2                	test   %edx,%edx
f0100fae:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb3:	0f 49 c2             	cmovns %edx,%eax
f0100fb6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fb9:	8b 75 10             	mov    0x10(%ebp),%esi
f0100fbc:	e9 79 ff ff ff       	jmp    f0100f3a <vprintfmt+0x90>
f0100fc1:	8b 75 10             	mov    0x10(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fc4:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100fcb:	e9 6a ff ff ff       	jmp    f0100f3a <vprintfmt+0x90>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fd0:	8b 75 10             	mov    0x10(%ebp),%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100fd3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fd7:	0f 89 5d ff ff ff    	jns    f0100f3a <vprintfmt+0x90>
f0100fdd:	e9 4b ff ff ff       	jmp    f0100f2d <vprintfmt+0x83>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fe2:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fe5:	8b 75 10             	mov    0x10(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fe8:	e9 4d ff ff ff       	jmp    f0100f3a <vprintfmt+0x90>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fed:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff0:	8d 70 04             	lea    0x4(%eax),%esi
f0100ff3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ff7:	8b 00                	mov    (%eax),%eax
f0100ff9:	89 04 24             	mov    %eax,(%esp)
f0100ffc:	ff d7                	call   *%edi
f0100ffe:	89 75 14             	mov    %esi,0x14(%ebp)
			break;
f0101001:	e9 ba fe ff ff       	jmp    f0100ec0 <vprintfmt+0x16>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101006:	8b 45 14             	mov    0x14(%ebp),%eax
f0101009:	8d 70 04             	lea    0x4(%eax),%esi
f010100c:	8b 00                	mov    (%eax),%eax
f010100e:	99                   	cltd   
f010100f:	31 d0                	xor    %edx,%eax
f0101011:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101013:	83 f8 07             	cmp    $0x7,%eax
f0101016:	7f 0b                	jg     f0101023 <vprintfmt+0x179>
f0101018:	8b 14 85 00 23 10 f0 	mov    -0xfefdd00(,%eax,4),%edx
f010101f:	85 d2                	test   %edx,%edx
f0101021:	75 20                	jne    f0101043 <vprintfmt+0x199>
				printfmt(putch, putdat, "error %d", err);
f0101023:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101027:	c7 44 24 08 21 21 10 	movl   $0xf0102121,0x8(%esp)
f010102e:	f0 
f010102f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101033:	89 3c 24             	mov    %edi,(%esp)
f0101036:	e8 47 fe ff ff       	call   f0100e82 <printfmt>
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010103b:	89 75 14             	mov    %esi,0x14(%ebp)
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010103e:	e9 7d fe ff ff       	jmp    f0100ec0 <vprintfmt+0x16>
			else
				printfmt(putch, putdat, "%s", p);
f0101043:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101047:	c7 44 24 08 2a 21 10 	movl   $0xf010212a,0x8(%esp)
f010104e:	f0 
f010104f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101053:	89 3c 24             	mov    %edi,(%esp)
f0101056:	e8 27 fe ff ff       	call   f0100e82 <printfmt>
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010105b:	89 75 14             	mov    %esi,0x14(%ebp)
f010105e:	e9 5d fe ff ff       	jmp    f0100ec0 <vprintfmt+0x16>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101063:	8b 45 14             	mov    0x14(%ebp),%eax
f0101066:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101069:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010106c:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0101070:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f0101072:	85 c0                	test   %eax,%eax
f0101074:	b9 1a 21 10 f0       	mov    $0xf010211a,%ecx
f0101079:	0f 45 c8             	cmovne %eax,%ecx
f010107c:	89 4d d0             	mov    %ecx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f010107f:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f0101083:	74 04                	je     f0101089 <vprintfmt+0x1df>
f0101085:	85 f6                	test   %esi,%esi
f0101087:	7f 19                	jg     f01010a2 <vprintfmt+0x1f8>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101089:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010108c:	8d 70 01             	lea    0x1(%eax),%esi
f010108f:	0f b6 10             	movzbl (%eax),%edx
f0101092:	0f be c2             	movsbl %dl,%eax
f0101095:	85 c0                	test   %eax,%eax
f0101097:	0f 85 9a 00 00 00    	jne    f0101137 <vprintfmt+0x28d>
f010109d:	e9 87 00 00 00       	jmp    f0101129 <vprintfmt+0x27f>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010a2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010a6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010a9:	89 04 24             	mov    %eax,(%esp)
f01010ac:	e8 11 04 00 00       	call   f01014c2 <strnlen>
f01010b1:	29 c6                	sub    %eax,%esi
f01010b3:	89 f0                	mov    %esi,%eax
f01010b5:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01010b8:	85 f6                	test   %esi,%esi
f01010ba:	7e cd                	jle    f0101089 <vprintfmt+0x1df>
					putch(padc, putdat);
f01010bc:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f01010c0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010c3:	89 c3                	mov    %eax,%ebx
f01010c5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010cc:	89 34 24             	mov    %esi,(%esp)
f01010cf:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010d1:	83 eb 01             	sub    $0x1,%ebx
f01010d4:	75 ef                	jne    f01010c5 <vprintfmt+0x21b>
f01010d6:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01010d9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010dc:	eb ab                	jmp    f0101089 <vprintfmt+0x1df>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010de:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010e2:	74 1e                	je     f0101102 <vprintfmt+0x258>
f01010e4:	0f be d2             	movsbl %dl,%edx
f01010e7:	83 ea 20             	sub    $0x20,%edx
f01010ea:	83 fa 5e             	cmp    $0x5e,%edx
f01010ed:	76 13                	jbe    f0101102 <vprintfmt+0x258>
					putch('?', putdat);
f01010ef:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010f2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010f6:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010fd:	ff 55 08             	call   *0x8(%ebp)
f0101100:	eb 0d                	jmp    f010110f <vprintfmt+0x265>
				else
					putch(ch, putdat);
f0101102:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101105:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101109:	89 04 24             	mov    %eax,(%esp)
f010110c:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010110f:	83 eb 01             	sub    $0x1,%ebx
f0101112:	83 c6 01             	add    $0x1,%esi
f0101115:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0101119:	0f be c2             	movsbl %dl,%eax
f010111c:	85 c0                	test   %eax,%eax
f010111e:	75 23                	jne    f0101143 <vprintfmt+0x299>
f0101120:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101123:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101126:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101129:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010112c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101130:	7f 25                	jg     f0101157 <vprintfmt+0x2ad>
f0101132:	e9 89 fd ff ff       	jmp    f0100ec0 <vprintfmt+0x16>
f0101137:	89 7d 08             	mov    %edi,0x8(%ebp)
f010113a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010113d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101140:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101143:	85 ff                	test   %edi,%edi
f0101145:	78 97                	js     f01010de <vprintfmt+0x234>
f0101147:	83 ef 01             	sub    $0x1,%edi
f010114a:	79 92                	jns    f01010de <vprintfmt+0x234>
f010114c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010114f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101152:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101155:	eb d2                	jmp    f0101129 <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101157:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010115b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101162:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101164:	83 ee 01             	sub    $0x1,%esi
f0101167:	75 ee                	jne    f0101157 <vprintfmt+0x2ad>
f0101169:	e9 52 fd ff ff       	jmp    f0100ec0 <vprintfmt+0x16>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010116e:	83 f9 01             	cmp    $0x1,%ecx
f0101171:	7e 19                	jle    f010118c <vprintfmt+0x2e2>
		return va_arg(*ap, long long);
f0101173:	8b 45 14             	mov    0x14(%ebp),%eax
f0101176:	8b 50 04             	mov    0x4(%eax),%edx
f0101179:	8b 00                	mov    (%eax),%eax
f010117b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010117e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101181:	8b 45 14             	mov    0x14(%ebp),%eax
f0101184:	8d 40 08             	lea    0x8(%eax),%eax
f0101187:	89 45 14             	mov    %eax,0x14(%ebp)
f010118a:	eb 38                	jmp    f01011c4 <vprintfmt+0x31a>
	else if (lflag)
f010118c:	85 c9                	test   %ecx,%ecx
f010118e:	74 1b                	je     f01011ab <vprintfmt+0x301>
		return va_arg(*ap, long);
f0101190:	8b 45 14             	mov    0x14(%ebp),%eax
f0101193:	8b 30                	mov    (%eax),%esi
f0101195:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101198:	89 f0                	mov    %esi,%eax
f010119a:	c1 f8 1f             	sar    $0x1f,%eax
f010119d:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01011a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a3:	8d 40 04             	lea    0x4(%eax),%eax
f01011a6:	89 45 14             	mov    %eax,0x14(%ebp)
f01011a9:	eb 19                	jmp    f01011c4 <vprintfmt+0x31a>
	else
		return va_arg(*ap, int);
f01011ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ae:	8b 30                	mov    (%eax),%esi
f01011b0:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01011b3:	89 f0                	mov    %esi,%eax
f01011b5:	c1 f8 1f             	sar    $0x1f,%eax
f01011b8:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01011bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01011be:	8d 40 04             	lea    0x4(%eax),%eax
f01011c1:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011c4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011c7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011ca:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011cf:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011d3:	0f 89 06 01 00 00    	jns    f01012df <vprintfmt+0x435>
				putch('-', putdat);
f01011d9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011dd:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01011e4:	ff d7                	call   *%edi
				num = -(long long) num;
f01011e6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011e9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01011ec:	f7 da                	neg    %edx
f01011ee:	83 d1 00             	adc    $0x0,%ecx
f01011f1:	f7 d9                	neg    %ecx
			}
			base = 10;
f01011f3:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011f8:	e9 e2 00 00 00       	jmp    f01012df <vprintfmt+0x435>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011fd:	83 f9 01             	cmp    $0x1,%ecx
f0101200:	7e 10                	jle    f0101212 <vprintfmt+0x368>
		return va_arg(*ap, unsigned long long);
f0101202:	8b 45 14             	mov    0x14(%ebp),%eax
f0101205:	8b 10                	mov    (%eax),%edx
f0101207:	8b 48 04             	mov    0x4(%eax),%ecx
f010120a:	8d 40 08             	lea    0x8(%eax),%eax
f010120d:	89 45 14             	mov    %eax,0x14(%ebp)
f0101210:	eb 26                	jmp    f0101238 <vprintfmt+0x38e>
	else if (lflag)
f0101212:	85 c9                	test   %ecx,%ecx
f0101214:	74 12                	je     f0101228 <vprintfmt+0x37e>
		return va_arg(*ap, unsigned long);
f0101216:	8b 45 14             	mov    0x14(%ebp),%eax
f0101219:	8b 10                	mov    (%eax),%edx
f010121b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101220:	8d 40 04             	lea    0x4(%eax),%eax
f0101223:	89 45 14             	mov    %eax,0x14(%ebp)
f0101226:	eb 10                	jmp    f0101238 <vprintfmt+0x38e>
	else
		return va_arg(*ap, unsigned int);
f0101228:	8b 45 14             	mov    0x14(%ebp),%eax
f010122b:	8b 10                	mov    (%eax),%edx
f010122d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101232:	8d 40 04             	lea    0x4(%eax),%eax
f0101235:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101238:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010123d:	e9 9d 00 00 00       	jmp    f01012df <vprintfmt+0x435>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101242:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101246:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010124d:	ff d7                	call   *%edi
			putch('X', putdat);
f010124f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101253:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010125a:	ff d7                	call   *%edi
			putch('X', putdat);
f010125c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101260:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101267:	ff d7                	call   *%edi
			break;
f0101269:	e9 52 fc ff ff       	jmp    f0100ec0 <vprintfmt+0x16>

		// pointer
		case 'p':
			putch('0', putdat);
f010126e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101272:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101279:	ff d7                	call   *%edi
			putch('x', putdat);
f010127b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010127f:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101286:	ff d7                	call   *%edi
			num = (unsigned long long)
f0101288:	8b 45 14             	mov    0x14(%ebp),%eax
f010128b:	8b 10                	mov    (%eax),%edx
f010128d:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
f0101292:	8d 40 04             	lea    0x4(%eax),%eax
f0101295:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101298:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010129d:	eb 40                	jmp    f01012df <vprintfmt+0x435>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010129f:	83 f9 01             	cmp    $0x1,%ecx
f01012a2:	7e 10                	jle    f01012b4 <vprintfmt+0x40a>
		return va_arg(*ap, unsigned long long);
f01012a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01012a7:	8b 10                	mov    (%eax),%edx
f01012a9:	8b 48 04             	mov    0x4(%eax),%ecx
f01012ac:	8d 40 08             	lea    0x8(%eax),%eax
f01012af:	89 45 14             	mov    %eax,0x14(%ebp)
f01012b2:	eb 26                	jmp    f01012da <vprintfmt+0x430>
	else if (lflag)
f01012b4:	85 c9                	test   %ecx,%ecx
f01012b6:	74 12                	je     f01012ca <vprintfmt+0x420>
		return va_arg(*ap, unsigned long);
f01012b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01012bb:	8b 10                	mov    (%eax),%edx
f01012bd:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012c2:	8d 40 04             	lea    0x4(%eax),%eax
f01012c5:	89 45 14             	mov    %eax,0x14(%ebp)
f01012c8:	eb 10                	jmp    f01012da <vprintfmt+0x430>
	else
		return va_arg(*ap, unsigned int);
f01012ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01012cd:	8b 10                	mov    (%eax),%edx
f01012cf:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012d4:	8d 40 04             	lea    0x4(%eax),%eax
f01012d7:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012da:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01012df:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f01012e3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01012e7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01012ea:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01012ee:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012f2:	89 14 24             	mov    %edx,(%esp)
f01012f5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01012f9:	89 da                	mov    %ebx,%edx
f01012fb:	89 f8                	mov    %edi,%eax
f01012fd:	e8 6e fa ff ff       	call   f0100d70 <printnum>
			break;
f0101302:	e9 b9 fb ff ff       	jmp    f0100ec0 <vprintfmt+0x16>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101307:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010130b:	89 14 24             	mov    %edx,(%esp)
f010130e:	ff d7                	call   *%edi
			break;
f0101310:	e9 ab fb ff ff       	jmp    f0100ec0 <vprintfmt+0x16>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101315:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101319:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101320:	ff d7                	call   *%edi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101322:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101326:	0f 84 91 fb ff ff    	je     f0100ebd <vprintfmt+0x13>
f010132c:	89 75 10             	mov    %esi,0x10(%ebp)
f010132f:	89 f0                	mov    %esi,%eax
f0101331:	83 e8 01             	sub    $0x1,%eax
f0101334:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101338:	75 f7                	jne    f0101331 <vprintfmt+0x487>
f010133a:	89 45 10             	mov    %eax,0x10(%ebp)
f010133d:	e9 7e fb ff ff       	jmp    f0100ec0 <vprintfmt+0x16>
				/* do nothing */;
			break;
		}
	}
}
f0101342:	83 c4 3c             	add    $0x3c,%esp
f0101345:	5b                   	pop    %ebx
f0101346:	5e                   	pop    %esi
f0101347:	5f                   	pop    %edi
f0101348:	5d                   	pop    %ebp
f0101349:	c3                   	ret    

f010134a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010134a:	55                   	push   %ebp
f010134b:	89 e5                	mov    %esp,%ebp
f010134d:	83 ec 28             	sub    $0x28,%esp
f0101350:	8b 45 08             	mov    0x8(%ebp),%eax
f0101353:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101356:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101359:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010135d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101360:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101367:	85 c0                	test   %eax,%eax
f0101369:	74 30                	je     f010139b <vsnprintf+0x51>
f010136b:	85 d2                	test   %edx,%edx
f010136d:	7e 2c                	jle    f010139b <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010136f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101372:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101376:	8b 45 10             	mov    0x10(%ebp),%eax
f0101379:	89 44 24 08          	mov    %eax,0x8(%esp)
f010137d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101380:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101384:	c7 04 24 65 0e 10 f0 	movl   $0xf0100e65,(%esp)
f010138b:	e8 1a fb ff ff       	call   f0100eaa <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101390:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101393:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101396:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101399:	eb 05                	jmp    f01013a0 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010139b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01013a0:	c9                   	leave  
f01013a1:	c3                   	ret    

f01013a2 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01013a2:	55                   	push   %ebp
f01013a3:	89 e5                	mov    %esp,%ebp
f01013a5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01013a8:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01013ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013af:	8b 45 10             	mov    0x10(%ebp),%eax
f01013b2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013b6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01013c0:	89 04 24             	mov    %eax,(%esp)
f01013c3:	e8 82 ff ff ff       	call   f010134a <vsnprintf>
	va_end(ap);

	return rc;
}
f01013c8:	c9                   	leave  
f01013c9:	c3                   	ret    
f01013ca:	66 90                	xchg   %ax,%ax
f01013cc:	66 90                	xchg   %ax,%ax
f01013ce:	66 90                	xchg   %ax,%ax

f01013d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013d0:	55                   	push   %ebp
f01013d1:	89 e5                	mov    %esp,%ebp
f01013d3:	57                   	push   %edi
f01013d4:	56                   	push   %esi
f01013d5:	53                   	push   %ebx
f01013d6:	83 ec 1c             	sub    $0x1c,%esp
f01013d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013dc:	85 c0                	test   %eax,%eax
f01013de:	74 10                	je     f01013f0 <readline+0x20>
		cprintf("%s", prompt);
f01013e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013e4:	c7 04 24 2a 21 10 f0 	movl   $0xf010212a,(%esp)
f01013eb:	e8 0f f6 ff ff       	call   f01009ff <cprintf>

	i = 0;
	echoing = iscons(0);
f01013f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013f7:	e8 86 f2 ff ff       	call   f0100682 <iscons>
f01013fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01013fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101403:	e8 69 f2 ff ff       	call   f0100671 <getchar>
f0101408:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010140a:	85 c0                	test   %eax,%eax
f010140c:	79 17                	jns    f0101425 <readline+0x55>
			cprintf("read error: %e\n", c);
f010140e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101412:	c7 04 24 20 23 10 f0 	movl   $0xf0102320,(%esp)
f0101419:	e8 e1 f5 ff ff       	call   f01009ff <cprintf>
			return NULL;
f010141e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101423:	eb 6d                	jmp    f0101492 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101425:	83 f8 7f             	cmp    $0x7f,%eax
f0101428:	74 05                	je     f010142f <readline+0x5f>
f010142a:	83 f8 08             	cmp    $0x8,%eax
f010142d:	75 19                	jne    f0101448 <readline+0x78>
f010142f:	85 f6                	test   %esi,%esi
f0101431:	7e 15                	jle    f0101448 <readline+0x78>
			if (echoing)
f0101433:	85 ff                	test   %edi,%edi
f0101435:	74 0c                	je     f0101443 <readline+0x73>
				cputchar('\b');
f0101437:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010143e:	e8 1e f2 ff ff       	call   f0100661 <cputchar>
			i--;
f0101443:	83 ee 01             	sub    $0x1,%esi
f0101446:	eb bb                	jmp    f0101403 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101448:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010144e:	7f 1c                	jg     f010146c <readline+0x9c>
f0101450:	83 fb 1f             	cmp    $0x1f,%ebx
f0101453:	7e 17                	jle    f010146c <readline+0x9c>
			if (echoing)
f0101455:	85 ff                	test   %edi,%edi
f0101457:	74 08                	je     f0101461 <readline+0x91>
				cputchar(c);
f0101459:	89 1c 24             	mov    %ebx,(%esp)
f010145c:	e8 00 f2 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101461:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101467:	8d 76 01             	lea    0x1(%esi),%esi
f010146a:	eb 97                	jmp    f0101403 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010146c:	83 fb 0d             	cmp    $0xd,%ebx
f010146f:	74 05                	je     f0101476 <readline+0xa6>
f0101471:	83 fb 0a             	cmp    $0xa,%ebx
f0101474:	75 8d                	jne    f0101403 <readline+0x33>
			if (echoing)
f0101476:	85 ff                	test   %edi,%edi
f0101478:	74 0c                	je     f0101486 <readline+0xb6>
				cputchar('\n');
f010147a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101481:	e8 db f1 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f0101486:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010148d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101492:	83 c4 1c             	add    $0x1c,%esp
f0101495:	5b                   	pop    %ebx
f0101496:	5e                   	pop    %esi
f0101497:	5f                   	pop    %edi
f0101498:	5d                   	pop    %ebp
f0101499:	c3                   	ret    
f010149a:	66 90                	xchg   %ax,%ax
f010149c:	66 90                	xchg   %ax,%ax
f010149e:	66 90                	xchg   %ax,%ax

f01014a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014a0:	55                   	push   %ebp
f01014a1:	89 e5                	mov    %esp,%ebp
f01014a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014a6:	80 3a 00             	cmpb   $0x0,(%edx)
f01014a9:	74 10                	je     f01014bb <strlen+0x1b>
f01014ab:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01014b0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01014b3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014b7:	75 f7                	jne    f01014b0 <strlen+0x10>
f01014b9:	eb 05                	jmp    f01014c0 <strlen+0x20>
f01014bb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01014c0:	5d                   	pop    %ebp
f01014c1:	c3                   	ret    

f01014c2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014c2:	55                   	push   %ebp
f01014c3:	89 e5                	mov    %esp,%ebp
f01014c5:	53                   	push   %ebx
f01014c6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014c9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014cc:	85 c9                	test   %ecx,%ecx
f01014ce:	74 1c                	je     f01014ec <strnlen+0x2a>
f01014d0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01014d3:	74 1e                	je     f01014f3 <strnlen+0x31>
f01014d5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01014da:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014dc:	39 ca                	cmp    %ecx,%edx
f01014de:	74 18                	je     f01014f8 <strnlen+0x36>
f01014e0:	83 c2 01             	add    $0x1,%edx
f01014e3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01014e8:	75 f0                	jne    f01014da <strnlen+0x18>
f01014ea:	eb 0c                	jmp    f01014f8 <strnlen+0x36>
f01014ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01014f1:	eb 05                	jmp    f01014f8 <strnlen+0x36>
f01014f3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01014f8:	5b                   	pop    %ebx
f01014f9:	5d                   	pop    %ebp
f01014fa:	c3                   	ret    

f01014fb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014fb:	55                   	push   %ebp
f01014fc:	89 e5                	mov    %esp,%ebp
f01014fe:	53                   	push   %ebx
f01014ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101502:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101505:	89 c2                	mov    %eax,%edx
f0101507:	83 c2 01             	add    $0x1,%edx
f010150a:	83 c1 01             	add    $0x1,%ecx
f010150d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101511:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101514:	84 db                	test   %bl,%bl
f0101516:	75 ef                	jne    f0101507 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101518:	5b                   	pop    %ebx
f0101519:	5d                   	pop    %ebp
f010151a:	c3                   	ret    

f010151b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010151b:	55                   	push   %ebp
f010151c:	89 e5                	mov    %esp,%ebp
f010151e:	53                   	push   %ebx
f010151f:	83 ec 08             	sub    $0x8,%esp
f0101522:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101525:	89 1c 24             	mov    %ebx,(%esp)
f0101528:	e8 73 ff ff ff       	call   f01014a0 <strlen>
	strcpy(dst + len, src);
f010152d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101530:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101534:	01 d8                	add    %ebx,%eax
f0101536:	89 04 24             	mov    %eax,(%esp)
f0101539:	e8 bd ff ff ff       	call   f01014fb <strcpy>
	return dst;
}
f010153e:	89 d8                	mov    %ebx,%eax
f0101540:	83 c4 08             	add    $0x8,%esp
f0101543:	5b                   	pop    %ebx
f0101544:	5d                   	pop    %ebp
f0101545:	c3                   	ret    

f0101546 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101546:	55                   	push   %ebp
f0101547:	89 e5                	mov    %esp,%ebp
f0101549:	56                   	push   %esi
f010154a:	53                   	push   %ebx
f010154b:	8b 75 08             	mov    0x8(%ebp),%esi
f010154e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101551:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101554:	85 db                	test   %ebx,%ebx
f0101556:	74 17                	je     f010156f <strncpy+0x29>
f0101558:	01 f3                	add    %esi,%ebx
f010155a:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f010155c:	83 c1 01             	add    $0x1,%ecx
f010155f:	0f b6 02             	movzbl (%edx),%eax
f0101562:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101565:	80 3a 01             	cmpb   $0x1,(%edx)
f0101568:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010156b:	39 d9                	cmp    %ebx,%ecx
f010156d:	75 ed                	jne    f010155c <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010156f:	89 f0                	mov    %esi,%eax
f0101571:	5b                   	pop    %ebx
f0101572:	5e                   	pop    %esi
f0101573:	5d                   	pop    %ebp
f0101574:	c3                   	ret    

f0101575 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101575:	55                   	push   %ebp
f0101576:	89 e5                	mov    %esp,%ebp
f0101578:	57                   	push   %edi
f0101579:	56                   	push   %esi
f010157a:	53                   	push   %ebx
f010157b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010157e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101581:	8b 75 10             	mov    0x10(%ebp),%esi
f0101584:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101586:	85 f6                	test   %esi,%esi
f0101588:	74 34                	je     f01015be <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010158a:	83 fe 01             	cmp    $0x1,%esi
f010158d:	74 26                	je     f01015b5 <strlcpy+0x40>
f010158f:	0f b6 0b             	movzbl (%ebx),%ecx
f0101592:	84 c9                	test   %cl,%cl
f0101594:	74 23                	je     f01015b9 <strlcpy+0x44>
f0101596:	83 ee 02             	sub    $0x2,%esi
f0101599:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f010159e:	83 c0 01             	add    $0x1,%eax
f01015a1:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01015a4:	39 f2                	cmp    %esi,%edx
f01015a6:	74 13                	je     f01015bb <strlcpy+0x46>
f01015a8:	83 c2 01             	add    $0x1,%edx
f01015ab:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01015af:	84 c9                	test   %cl,%cl
f01015b1:	75 eb                	jne    f010159e <strlcpy+0x29>
f01015b3:	eb 06                	jmp    f01015bb <strlcpy+0x46>
f01015b5:	89 f8                	mov    %edi,%eax
f01015b7:	eb 02                	jmp    f01015bb <strlcpy+0x46>
f01015b9:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01015bb:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01015be:	29 f8                	sub    %edi,%eax
}
f01015c0:	5b                   	pop    %ebx
f01015c1:	5e                   	pop    %esi
f01015c2:	5f                   	pop    %edi
f01015c3:	5d                   	pop    %ebp
f01015c4:	c3                   	ret    

f01015c5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01015c5:	55                   	push   %ebp
f01015c6:	89 e5                	mov    %esp,%ebp
f01015c8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015cb:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01015ce:	0f b6 01             	movzbl (%ecx),%eax
f01015d1:	84 c0                	test   %al,%al
f01015d3:	74 15                	je     f01015ea <strcmp+0x25>
f01015d5:	3a 02                	cmp    (%edx),%al
f01015d7:	75 11                	jne    f01015ea <strcmp+0x25>
		p++, q++;
f01015d9:	83 c1 01             	add    $0x1,%ecx
f01015dc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01015df:	0f b6 01             	movzbl (%ecx),%eax
f01015e2:	84 c0                	test   %al,%al
f01015e4:	74 04                	je     f01015ea <strcmp+0x25>
f01015e6:	3a 02                	cmp    (%edx),%al
f01015e8:	74 ef                	je     f01015d9 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015ea:	0f b6 c0             	movzbl %al,%eax
f01015ed:	0f b6 12             	movzbl (%edx),%edx
f01015f0:	29 d0                	sub    %edx,%eax
}
f01015f2:	5d                   	pop    %ebp
f01015f3:	c3                   	ret    

f01015f4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015f4:	55                   	push   %ebp
f01015f5:	89 e5                	mov    %esp,%ebp
f01015f7:	56                   	push   %esi
f01015f8:	53                   	push   %ebx
f01015f9:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01015fc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015ff:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0101602:	85 f6                	test   %esi,%esi
f0101604:	74 29                	je     f010162f <strncmp+0x3b>
f0101606:	0f b6 03             	movzbl (%ebx),%eax
f0101609:	84 c0                	test   %al,%al
f010160b:	74 30                	je     f010163d <strncmp+0x49>
f010160d:	3a 02                	cmp    (%edx),%al
f010160f:	75 2c                	jne    f010163d <strncmp+0x49>
f0101611:	8d 43 01             	lea    0x1(%ebx),%eax
f0101614:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f0101616:	89 c3                	mov    %eax,%ebx
f0101618:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010161b:	39 f0                	cmp    %esi,%eax
f010161d:	74 17                	je     f0101636 <strncmp+0x42>
f010161f:	0f b6 08             	movzbl (%eax),%ecx
f0101622:	84 c9                	test   %cl,%cl
f0101624:	74 17                	je     f010163d <strncmp+0x49>
f0101626:	83 c0 01             	add    $0x1,%eax
f0101629:	3a 0a                	cmp    (%edx),%cl
f010162b:	74 e9                	je     f0101616 <strncmp+0x22>
f010162d:	eb 0e                	jmp    f010163d <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f010162f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101634:	eb 0f                	jmp    f0101645 <strncmp+0x51>
f0101636:	b8 00 00 00 00       	mov    $0x0,%eax
f010163b:	eb 08                	jmp    f0101645 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010163d:	0f b6 03             	movzbl (%ebx),%eax
f0101640:	0f b6 12             	movzbl (%edx),%edx
f0101643:	29 d0                	sub    %edx,%eax
}
f0101645:	5b                   	pop    %ebx
f0101646:	5e                   	pop    %esi
f0101647:	5d                   	pop    %ebp
f0101648:	c3                   	ret    

f0101649 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101649:	55                   	push   %ebp
f010164a:	89 e5                	mov    %esp,%ebp
f010164c:	53                   	push   %ebx
f010164d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101650:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101653:	0f b6 18             	movzbl (%eax),%ebx
f0101656:	84 db                	test   %bl,%bl
f0101658:	74 1d                	je     f0101677 <strchr+0x2e>
f010165a:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f010165c:	38 d3                	cmp    %dl,%bl
f010165e:	75 06                	jne    f0101666 <strchr+0x1d>
f0101660:	eb 1a                	jmp    f010167c <strchr+0x33>
f0101662:	38 ca                	cmp    %cl,%dl
f0101664:	74 16                	je     f010167c <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101666:	83 c0 01             	add    $0x1,%eax
f0101669:	0f b6 10             	movzbl (%eax),%edx
f010166c:	84 d2                	test   %dl,%dl
f010166e:	75 f2                	jne    f0101662 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101670:	b8 00 00 00 00       	mov    $0x0,%eax
f0101675:	eb 05                	jmp    f010167c <strchr+0x33>
f0101677:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010167c:	5b                   	pop    %ebx
f010167d:	5d                   	pop    %ebp
f010167e:	c3                   	ret    

f010167f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010167f:	55                   	push   %ebp
f0101680:	89 e5                	mov    %esp,%ebp
f0101682:	53                   	push   %ebx
f0101683:	8b 45 08             	mov    0x8(%ebp),%eax
f0101686:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101689:	0f b6 18             	movzbl (%eax),%ebx
f010168c:	84 db                	test   %bl,%bl
f010168e:	74 16                	je     f01016a6 <strfind+0x27>
f0101690:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101692:	38 d3                	cmp    %dl,%bl
f0101694:	75 06                	jne    f010169c <strfind+0x1d>
f0101696:	eb 0e                	jmp    f01016a6 <strfind+0x27>
f0101698:	38 ca                	cmp    %cl,%dl
f010169a:	74 0a                	je     f01016a6 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010169c:	83 c0 01             	add    $0x1,%eax
f010169f:	0f b6 10             	movzbl (%eax),%edx
f01016a2:	84 d2                	test   %dl,%dl
f01016a4:	75 f2                	jne    f0101698 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f01016a6:	5b                   	pop    %ebx
f01016a7:	5d                   	pop    %ebp
f01016a8:	c3                   	ret    

f01016a9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01016a9:	55                   	push   %ebp
f01016aa:	89 e5                	mov    %esp,%ebp
f01016ac:	57                   	push   %edi
f01016ad:	56                   	push   %esi
f01016ae:	53                   	push   %ebx
f01016af:	8b 7d 08             	mov    0x8(%ebp),%edi
f01016b2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01016b5:	85 c9                	test   %ecx,%ecx
f01016b7:	74 36                	je     f01016ef <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01016b9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016bf:	75 28                	jne    f01016e9 <memset+0x40>
f01016c1:	f6 c1 03             	test   $0x3,%cl
f01016c4:	75 23                	jne    f01016e9 <memset+0x40>
		c &= 0xFF;
f01016c6:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01016ca:	89 d3                	mov    %edx,%ebx
f01016cc:	c1 e3 08             	shl    $0x8,%ebx
f01016cf:	89 d6                	mov    %edx,%esi
f01016d1:	c1 e6 18             	shl    $0x18,%esi
f01016d4:	89 d0                	mov    %edx,%eax
f01016d6:	c1 e0 10             	shl    $0x10,%eax
f01016d9:	09 f0                	or     %esi,%eax
f01016db:	09 c2                	or     %eax,%edx
f01016dd:	89 d0                	mov    %edx,%eax
f01016df:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01016e1:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01016e4:	fc                   	cld    
f01016e5:	f3 ab                	rep stos %eax,%es:(%edi)
f01016e7:	eb 06                	jmp    f01016ef <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01016e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016ec:	fc                   	cld    
f01016ed:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01016ef:	89 f8                	mov    %edi,%eax
f01016f1:	5b                   	pop    %ebx
f01016f2:	5e                   	pop    %esi
f01016f3:	5f                   	pop    %edi
f01016f4:	5d                   	pop    %ebp
f01016f5:	c3                   	ret    

f01016f6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016f6:	55                   	push   %ebp
f01016f7:	89 e5                	mov    %esp,%ebp
f01016f9:	57                   	push   %edi
f01016fa:	56                   	push   %esi
f01016fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01016fe:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101701:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101704:	39 c6                	cmp    %eax,%esi
f0101706:	73 35                	jae    f010173d <memmove+0x47>
f0101708:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010170b:	39 d0                	cmp    %edx,%eax
f010170d:	73 2e                	jae    f010173d <memmove+0x47>
		s += n;
		d += n;
f010170f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101712:	89 d6                	mov    %edx,%esi
f0101714:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101716:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010171c:	75 13                	jne    f0101731 <memmove+0x3b>
f010171e:	f6 c1 03             	test   $0x3,%cl
f0101721:	75 0e                	jne    f0101731 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101723:	83 ef 04             	sub    $0x4,%edi
f0101726:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101729:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010172c:	fd                   	std    
f010172d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010172f:	eb 09                	jmp    f010173a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101731:	83 ef 01             	sub    $0x1,%edi
f0101734:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101737:	fd                   	std    
f0101738:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010173a:	fc                   	cld    
f010173b:	eb 1d                	jmp    f010175a <memmove+0x64>
f010173d:	89 f2                	mov    %esi,%edx
f010173f:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101741:	f6 c2 03             	test   $0x3,%dl
f0101744:	75 0f                	jne    f0101755 <memmove+0x5f>
f0101746:	f6 c1 03             	test   $0x3,%cl
f0101749:	75 0a                	jne    f0101755 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010174b:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010174e:	89 c7                	mov    %eax,%edi
f0101750:	fc                   	cld    
f0101751:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101753:	eb 05                	jmp    f010175a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101755:	89 c7                	mov    %eax,%edi
f0101757:	fc                   	cld    
f0101758:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010175a:	5e                   	pop    %esi
f010175b:	5f                   	pop    %edi
f010175c:	5d                   	pop    %ebp
f010175d:	c3                   	ret    

f010175e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010175e:	55                   	push   %ebp
f010175f:	89 e5                	mov    %esp,%ebp
f0101761:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101764:	8b 45 10             	mov    0x10(%ebp),%eax
f0101767:	89 44 24 08          	mov    %eax,0x8(%esp)
f010176b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010176e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101772:	8b 45 08             	mov    0x8(%ebp),%eax
f0101775:	89 04 24             	mov    %eax,(%esp)
f0101778:	e8 79 ff ff ff       	call   f01016f6 <memmove>
}
f010177d:	c9                   	leave  
f010177e:	c3                   	ret    

f010177f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010177f:	55                   	push   %ebp
f0101780:	89 e5                	mov    %esp,%ebp
f0101782:	57                   	push   %edi
f0101783:	56                   	push   %esi
f0101784:	53                   	push   %ebx
f0101785:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101788:	8b 75 0c             	mov    0xc(%ebp),%esi
f010178b:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010178e:	8d 78 ff             	lea    -0x1(%eax),%edi
f0101791:	85 c0                	test   %eax,%eax
f0101793:	74 36                	je     f01017cb <memcmp+0x4c>
		if (*s1 != *s2)
f0101795:	0f b6 03             	movzbl (%ebx),%eax
f0101798:	0f b6 0e             	movzbl (%esi),%ecx
f010179b:	ba 00 00 00 00       	mov    $0x0,%edx
f01017a0:	38 c8                	cmp    %cl,%al
f01017a2:	74 1c                	je     f01017c0 <memcmp+0x41>
f01017a4:	eb 10                	jmp    f01017b6 <memcmp+0x37>
f01017a6:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01017ab:	83 c2 01             	add    $0x1,%edx
f01017ae:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01017b2:	38 c8                	cmp    %cl,%al
f01017b4:	74 0a                	je     f01017c0 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01017b6:	0f b6 c0             	movzbl %al,%eax
f01017b9:	0f b6 c9             	movzbl %cl,%ecx
f01017bc:	29 c8                	sub    %ecx,%eax
f01017be:	eb 10                	jmp    f01017d0 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017c0:	39 fa                	cmp    %edi,%edx
f01017c2:	75 e2                	jne    f01017a6 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01017c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01017c9:	eb 05                	jmp    f01017d0 <memcmp+0x51>
f01017cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017d0:	5b                   	pop    %ebx
f01017d1:	5e                   	pop    %esi
f01017d2:	5f                   	pop    %edi
f01017d3:	5d                   	pop    %ebp
f01017d4:	c3                   	ret    

f01017d5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01017d5:	55                   	push   %ebp
f01017d6:	89 e5                	mov    %esp,%ebp
f01017d8:	53                   	push   %ebx
f01017d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01017dc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01017df:	89 c2                	mov    %eax,%edx
f01017e1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017e4:	39 d0                	cmp    %edx,%eax
f01017e6:	73 13                	jae    f01017fb <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017e8:	89 d9                	mov    %ebx,%ecx
f01017ea:	38 18                	cmp    %bl,(%eax)
f01017ec:	75 06                	jne    f01017f4 <memfind+0x1f>
f01017ee:	eb 0b                	jmp    f01017fb <memfind+0x26>
f01017f0:	38 08                	cmp    %cl,(%eax)
f01017f2:	74 07                	je     f01017fb <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01017f4:	83 c0 01             	add    $0x1,%eax
f01017f7:	39 d0                	cmp    %edx,%eax
f01017f9:	75 f5                	jne    f01017f0 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01017fb:	5b                   	pop    %ebx
f01017fc:	5d                   	pop    %ebp
f01017fd:	c3                   	ret    

f01017fe <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01017fe:	55                   	push   %ebp
f01017ff:	89 e5                	mov    %esp,%ebp
f0101801:	57                   	push   %edi
f0101802:	56                   	push   %esi
f0101803:	53                   	push   %ebx
f0101804:	8b 55 08             	mov    0x8(%ebp),%edx
f0101807:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010180a:	0f b6 0a             	movzbl (%edx),%ecx
f010180d:	80 f9 09             	cmp    $0x9,%cl
f0101810:	74 05                	je     f0101817 <strtol+0x19>
f0101812:	80 f9 20             	cmp    $0x20,%cl
f0101815:	75 10                	jne    f0101827 <strtol+0x29>
		s++;
f0101817:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010181a:	0f b6 0a             	movzbl (%edx),%ecx
f010181d:	80 f9 09             	cmp    $0x9,%cl
f0101820:	74 f5                	je     f0101817 <strtol+0x19>
f0101822:	80 f9 20             	cmp    $0x20,%cl
f0101825:	74 f0                	je     f0101817 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101827:	80 f9 2b             	cmp    $0x2b,%cl
f010182a:	75 0a                	jne    f0101836 <strtol+0x38>
		s++;
f010182c:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010182f:	bf 00 00 00 00       	mov    $0x0,%edi
f0101834:	eb 11                	jmp    f0101847 <strtol+0x49>
f0101836:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010183b:	80 f9 2d             	cmp    $0x2d,%cl
f010183e:	75 07                	jne    f0101847 <strtol+0x49>
		s++, neg = 1;
f0101840:	83 c2 01             	add    $0x1,%edx
f0101843:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101847:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f010184c:	75 15                	jne    f0101863 <strtol+0x65>
f010184e:	80 3a 30             	cmpb   $0x30,(%edx)
f0101851:	75 10                	jne    f0101863 <strtol+0x65>
f0101853:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101857:	75 0a                	jne    f0101863 <strtol+0x65>
		s += 2, base = 16;
f0101859:	83 c2 02             	add    $0x2,%edx
f010185c:	b8 10 00 00 00       	mov    $0x10,%eax
f0101861:	eb 10                	jmp    f0101873 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f0101863:	85 c0                	test   %eax,%eax
f0101865:	75 0c                	jne    f0101873 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101867:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101869:	80 3a 30             	cmpb   $0x30,(%edx)
f010186c:	75 05                	jne    f0101873 <strtol+0x75>
		s++, base = 8;
f010186e:	83 c2 01             	add    $0x1,%edx
f0101871:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0101873:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101878:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010187b:	0f b6 0a             	movzbl (%edx),%ecx
f010187e:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101881:	89 f0                	mov    %esi,%eax
f0101883:	3c 09                	cmp    $0x9,%al
f0101885:	77 08                	ja     f010188f <strtol+0x91>
			dig = *s - '0';
f0101887:	0f be c9             	movsbl %cl,%ecx
f010188a:	83 e9 30             	sub    $0x30,%ecx
f010188d:	eb 20                	jmp    f01018af <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f010188f:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101892:	89 f0                	mov    %esi,%eax
f0101894:	3c 19                	cmp    $0x19,%al
f0101896:	77 08                	ja     f01018a0 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0101898:	0f be c9             	movsbl %cl,%ecx
f010189b:	83 e9 57             	sub    $0x57,%ecx
f010189e:	eb 0f                	jmp    f01018af <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f01018a0:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01018a3:	89 f0                	mov    %esi,%eax
f01018a5:	3c 19                	cmp    $0x19,%al
f01018a7:	77 16                	ja     f01018bf <strtol+0xc1>
			dig = *s - 'A' + 10;
f01018a9:	0f be c9             	movsbl %cl,%ecx
f01018ac:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01018af:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01018b2:	7d 0f                	jge    f01018c3 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01018b4:	83 c2 01             	add    $0x1,%edx
f01018b7:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01018bb:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01018bd:	eb bc                	jmp    f010187b <strtol+0x7d>
f01018bf:	89 d8                	mov    %ebx,%eax
f01018c1:	eb 02                	jmp    f01018c5 <strtol+0xc7>
f01018c3:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01018c5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018c9:	74 05                	je     f01018d0 <strtol+0xd2>
		*endptr = (char *) s;
f01018cb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018ce:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01018d0:	f7 d8                	neg    %eax
f01018d2:	85 ff                	test   %edi,%edi
f01018d4:	0f 44 c3             	cmove  %ebx,%eax
}
f01018d7:	5b                   	pop    %ebx
f01018d8:	5e                   	pop    %esi
f01018d9:	5f                   	pop    %edi
f01018da:	5d                   	pop    %ebp
f01018db:	c3                   	ret    
f01018dc:	66 90                	xchg   %ax,%ax
f01018de:	66 90                	xchg   %ax,%ax

f01018e0 <__udivdi3>:
f01018e0:	55                   	push   %ebp
f01018e1:	57                   	push   %edi
f01018e2:	56                   	push   %esi
f01018e3:	83 ec 0c             	sub    $0xc,%esp
f01018e6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01018ea:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01018ee:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01018f2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01018f6:	85 c0                	test   %eax,%eax
f01018f8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01018fc:	89 ea                	mov    %ebp,%edx
f01018fe:	89 0c 24             	mov    %ecx,(%esp)
f0101901:	75 2d                	jne    f0101930 <__udivdi3+0x50>
f0101903:	39 e9                	cmp    %ebp,%ecx
f0101905:	77 61                	ja     f0101968 <__udivdi3+0x88>
f0101907:	85 c9                	test   %ecx,%ecx
f0101909:	89 ce                	mov    %ecx,%esi
f010190b:	75 0b                	jne    f0101918 <__udivdi3+0x38>
f010190d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101912:	31 d2                	xor    %edx,%edx
f0101914:	f7 f1                	div    %ecx
f0101916:	89 c6                	mov    %eax,%esi
f0101918:	31 d2                	xor    %edx,%edx
f010191a:	89 e8                	mov    %ebp,%eax
f010191c:	f7 f6                	div    %esi
f010191e:	89 c5                	mov    %eax,%ebp
f0101920:	89 f8                	mov    %edi,%eax
f0101922:	f7 f6                	div    %esi
f0101924:	89 ea                	mov    %ebp,%edx
f0101926:	83 c4 0c             	add    $0xc,%esp
f0101929:	5e                   	pop    %esi
f010192a:	5f                   	pop    %edi
f010192b:	5d                   	pop    %ebp
f010192c:	c3                   	ret    
f010192d:	8d 76 00             	lea    0x0(%esi),%esi
f0101930:	39 e8                	cmp    %ebp,%eax
f0101932:	77 24                	ja     f0101958 <__udivdi3+0x78>
f0101934:	0f bd e8             	bsr    %eax,%ebp
f0101937:	83 f5 1f             	xor    $0x1f,%ebp
f010193a:	75 3c                	jne    f0101978 <__udivdi3+0x98>
f010193c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101940:	39 34 24             	cmp    %esi,(%esp)
f0101943:	0f 86 9f 00 00 00    	jbe    f01019e8 <__udivdi3+0x108>
f0101949:	39 d0                	cmp    %edx,%eax
f010194b:	0f 82 97 00 00 00    	jb     f01019e8 <__udivdi3+0x108>
f0101951:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101958:	31 d2                	xor    %edx,%edx
f010195a:	31 c0                	xor    %eax,%eax
f010195c:	83 c4 0c             	add    $0xc,%esp
f010195f:	5e                   	pop    %esi
f0101960:	5f                   	pop    %edi
f0101961:	5d                   	pop    %ebp
f0101962:	c3                   	ret    
f0101963:	90                   	nop
f0101964:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101968:	89 f8                	mov    %edi,%eax
f010196a:	f7 f1                	div    %ecx
f010196c:	31 d2                	xor    %edx,%edx
f010196e:	83 c4 0c             	add    $0xc,%esp
f0101971:	5e                   	pop    %esi
f0101972:	5f                   	pop    %edi
f0101973:	5d                   	pop    %ebp
f0101974:	c3                   	ret    
f0101975:	8d 76 00             	lea    0x0(%esi),%esi
f0101978:	89 e9                	mov    %ebp,%ecx
f010197a:	8b 3c 24             	mov    (%esp),%edi
f010197d:	d3 e0                	shl    %cl,%eax
f010197f:	89 c6                	mov    %eax,%esi
f0101981:	b8 20 00 00 00       	mov    $0x20,%eax
f0101986:	29 e8                	sub    %ebp,%eax
f0101988:	89 c1                	mov    %eax,%ecx
f010198a:	d3 ef                	shr    %cl,%edi
f010198c:	89 e9                	mov    %ebp,%ecx
f010198e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101992:	8b 3c 24             	mov    (%esp),%edi
f0101995:	09 74 24 08          	or     %esi,0x8(%esp)
f0101999:	89 d6                	mov    %edx,%esi
f010199b:	d3 e7                	shl    %cl,%edi
f010199d:	89 c1                	mov    %eax,%ecx
f010199f:	89 3c 24             	mov    %edi,(%esp)
f01019a2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01019a6:	d3 ee                	shr    %cl,%esi
f01019a8:	89 e9                	mov    %ebp,%ecx
f01019aa:	d3 e2                	shl    %cl,%edx
f01019ac:	89 c1                	mov    %eax,%ecx
f01019ae:	d3 ef                	shr    %cl,%edi
f01019b0:	09 d7                	or     %edx,%edi
f01019b2:	89 f2                	mov    %esi,%edx
f01019b4:	89 f8                	mov    %edi,%eax
f01019b6:	f7 74 24 08          	divl   0x8(%esp)
f01019ba:	89 d6                	mov    %edx,%esi
f01019bc:	89 c7                	mov    %eax,%edi
f01019be:	f7 24 24             	mull   (%esp)
f01019c1:	39 d6                	cmp    %edx,%esi
f01019c3:	89 14 24             	mov    %edx,(%esp)
f01019c6:	72 30                	jb     f01019f8 <__udivdi3+0x118>
f01019c8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01019cc:	89 e9                	mov    %ebp,%ecx
f01019ce:	d3 e2                	shl    %cl,%edx
f01019d0:	39 c2                	cmp    %eax,%edx
f01019d2:	73 05                	jae    f01019d9 <__udivdi3+0xf9>
f01019d4:	3b 34 24             	cmp    (%esp),%esi
f01019d7:	74 1f                	je     f01019f8 <__udivdi3+0x118>
f01019d9:	89 f8                	mov    %edi,%eax
f01019db:	31 d2                	xor    %edx,%edx
f01019dd:	e9 7a ff ff ff       	jmp    f010195c <__udivdi3+0x7c>
f01019e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019e8:	31 d2                	xor    %edx,%edx
f01019ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01019ef:	e9 68 ff ff ff       	jmp    f010195c <__udivdi3+0x7c>
f01019f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019f8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01019fb:	31 d2                	xor    %edx,%edx
f01019fd:	83 c4 0c             	add    $0xc,%esp
f0101a00:	5e                   	pop    %esi
f0101a01:	5f                   	pop    %edi
f0101a02:	5d                   	pop    %ebp
f0101a03:	c3                   	ret    
f0101a04:	66 90                	xchg   %ax,%ax
f0101a06:	66 90                	xchg   %ax,%ax
f0101a08:	66 90                	xchg   %ax,%ax
f0101a0a:	66 90                	xchg   %ax,%ax
f0101a0c:	66 90                	xchg   %ax,%ax
f0101a0e:	66 90                	xchg   %ax,%ax

f0101a10 <__umoddi3>:
f0101a10:	55                   	push   %ebp
f0101a11:	57                   	push   %edi
f0101a12:	56                   	push   %esi
f0101a13:	83 ec 14             	sub    $0x14,%esp
f0101a16:	8b 44 24 28          	mov    0x28(%esp),%eax
f0101a1a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101a1e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101a22:	89 c7                	mov    %eax,%edi
f0101a24:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a28:	8b 44 24 30          	mov    0x30(%esp),%eax
f0101a2c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101a30:	89 34 24             	mov    %esi,(%esp)
f0101a33:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101a37:	85 c0                	test   %eax,%eax
f0101a39:	89 c2                	mov    %eax,%edx
f0101a3b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a3f:	75 17                	jne    f0101a58 <__umoddi3+0x48>
f0101a41:	39 fe                	cmp    %edi,%esi
f0101a43:	76 4b                	jbe    f0101a90 <__umoddi3+0x80>
f0101a45:	89 c8                	mov    %ecx,%eax
f0101a47:	89 fa                	mov    %edi,%edx
f0101a49:	f7 f6                	div    %esi
f0101a4b:	89 d0                	mov    %edx,%eax
f0101a4d:	31 d2                	xor    %edx,%edx
f0101a4f:	83 c4 14             	add    $0x14,%esp
f0101a52:	5e                   	pop    %esi
f0101a53:	5f                   	pop    %edi
f0101a54:	5d                   	pop    %ebp
f0101a55:	c3                   	ret    
f0101a56:	66 90                	xchg   %ax,%ax
f0101a58:	39 f8                	cmp    %edi,%eax
f0101a5a:	77 54                	ja     f0101ab0 <__umoddi3+0xa0>
f0101a5c:	0f bd e8             	bsr    %eax,%ebp
f0101a5f:	83 f5 1f             	xor    $0x1f,%ebp
f0101a62:	75 5c                	jne    f0101ac0 <__umoddi3+0xb0>
f0101a64:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101a68:	39 3c 24             	cmp    %edi,(%esp)
f0101a6b:	0f 87 e7 00 00 00    	ja     f0101b58 <__umoddi3+0x148>
f0101a71:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101a75:	29 f1                	sub    %esi,%ecx
f0101a77:	19 c7                	sbb    %eax,%edi
f0101a79:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101a7d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a81:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101a85:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101a89:	83 c4 14             	add    $0x14,%esp
f0101a8c:	5e                   	pop    %esi
f0101a8d:	5f                   	pop    %edi
f0101a8e:	5d                   	pop    %ebp
f0101a8f:	c3                   	ret    
f0101a90:	85 f6                	test   %esi,%esi
f0101a92:	89 f5                	mov    %esi,%ebp
f0101a94:	75 0b                	jne    f0101aa1 <__umoddi3+0x91>
f0101a96:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a9b:	31 d2                	xor    %edx,%edx
f0101a9d:	f7 f6                	div    %esi
f0101a9f:	89 c5                	mov    %eax,%ebp
f0101aa1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101aa5:	31 d2                	xor    %edx,%edx
f0101aa7:	f7 f5                	div    %ebp
f0101aa9:	89 c8                	mov    %ecx,%eax
f0101aab:	f7 f5                	div    %ebp
f0101aad:	eb 9c                	jmp    f0101a4b <__umoddi3+0x3b>
f0101aaf:	90                   	nop
f0101ab0:	89 c8                	mov    %ecx,%eax
f0101ab2:	89 fa                	mov    %edi,%edx
f0101ab4:	83 c4 14             	add    $0x14,%esp
f0101ab7:	5e                   	pop    %esi
f0101ab8:	5f                   	pop    %edi
f0101ab9:	5d                   	pop    %ebp
f0101aba:	c3                   	ret    
f0101abb:	90                   	nop
f0101abc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ac0:	8b 04 24             	mov    (%esp),%eax
f0101ac3:	be 20 00 00 00       	mov    $0x20,%esi
f0101ac8:	89 e9                	mov    %ebp,%ecx
f0101aca:	29 ee                	sub    %ebp,%esi
f0101acc:	d3 e2                	shl    %cl,%edx
f0101ace:	89 f1                	mov    %esi,%ecx
f0101ad0:	d3 e8                	shr    %cl,%eax
f0101ad2:	89 e9                	mov    %ebp,%ecx
f0101ad4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ad8:	8b 04 24             	mov    (%esp),%eax
f0101adb:	09 54 24 04          	or     %edx,0x4(%esp)
f0101adf:	89 fa                	mov    %edi,%edx
f0101ae1:	d3 e0                	shl    %cl,%eax
f0101ae3:	89 f1                	mov    %esi,%ecx
f0101ae5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101ae9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101aed:	d3 ea                	shr    %cl,%edx
f0101aef:	89 e9                	mov    %ebp,%ecx
f0101af1:	d3 e7                	shl    %cl,%edi
f0101af3:	89 f1                	mov    %esi,%ecx
f0101af5:	d3 e8                	shr    %cl,%eax
f0101af7:	89 e9                	mov    %ebp,%ecx
f0101af9:	09 f8                	or     %edi,%eax
f0101afb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0101aff:	f7 74 24 04          	divl   0x4(%esp)
f0101b03:	d3 e7                	shl    %cl,%edi
f0101b05:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101b09:	89 d7                	mov    %edx,%edi
f0101b0b:	f7 64 24 08          	mull   0x8(%esp)
f0101b0f:	39 d7                	cmp    %edx,%edi
f0101b11:	89 c1                	mov    %eax,%ecx
f0101b13:	89 14 24             	mov    %edx,(%esp)
f0101b16:	72 2c                	jb     f0101b44 <__umoddi3+0x134>
f0101b18:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0101b1c:	72 22                	jb     f0101b40 <__umoddi3+0x130>
f0101b1e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101b22:	29 c8                	sub    %ecx,%eax
f0101b24:	19 d7                	sbb    %edx,%edi
f0101b26:	89 e9                	mov    %ebp,%ecx
f0101b28:	89 fa                	mov    %edi,%edx
f0101b2a:	d3 e8                	shr    %cl,%eax
f0101b2c:	89 f1                	mov    %esi,%ecx
f0101b2e:	d3 e2                	shl    %cl,%edx
f0101b30:	89 e9                	mov    %ebp,%ecx
f0101b32:	d3 ef                	shr    %cl,%edi
f0101b34:	09 d0                	or     %edx,%eax
f0101b36:	89 fa                	mov    %edi,%edx
f0101b38:	83 c4 14             	add    $0x14,%esp
f0101b3b:	5e                   	pop    %esi
f0101b3c:	5f                   	pop    %edi
f0101b3d:	5d                   	pop    %ebp
f0101b3e:	c3                   	ret    
f0101b3f:	90                   	nop
f0101b40:	39 d7                	cmp    %edx,%edi
f0101b42:	75 da                	jne    f0101b1e <__umoddi3+0x10e>
f0101b44:	8b 14 24             	mov    (%esp),%edx
f0101b47:	89 c1                	mov    %eax,%ecx
f0101b49:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101b4d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101b51:	eb cb                	jmp    f0101b1e <__umoddi3+0x10e>
f0101b53:	90                   	nop
f0101b54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b58:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101b5c:	0f 82 0f ff ff ff    	jb     f0101a71 <__umoddi3+0x61>
f0101b62:	e9 1a ff ff ff       	jmp    f0101a81 <__umoddi3+0x71>
