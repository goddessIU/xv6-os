
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	ea478793          	addi	a5,a5,-348 # 80005f00 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd37ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e7c78793          	addi	a5,a5,-388 # 80000f22 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b68080e7          	jalr	-1176(ra) # 80000c74 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3f2080e7          	jalr	1010(ra) # 80002518 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00001097          	auipc	ra,0x1
    8000013a:	80e080e7          	jalr	-2034(ra) # 80000944 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bda080e7          	jalr	-1062(ra) # 80000d28 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	ad6080e7          	jalr	-1322(ra) # 80000c74 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	874080e7          	jalr	-1932(ra) # 80001a42 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	082080e7          	jalr	130(ra) # 80002260 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	2a8080e7          	jalr	680(ra) # 800024c2 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	af2080e7          	jalr	-1294(ra) # 80000d28 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	adc080e7          	jalr	-1316(ra) # 80000d28 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	5c8080e7          	jalr	1480(ra) # 8000085e <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	5b6080e7          	jalr	1462(ra) # 8000085e <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5aa080e7          	jalr	1450(ra) # 8000085e <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	5a0080e7          	jalr	1440(ra) # 8000085e <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	996080e7          	jalr	-1642(ra) # 80000c74 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	272080e7          	jalr	626(ra) # 8000256e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a1c080e7          	jalr	-1508(ra) # 80000d28 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	f96080e7          	jalr	-106(ra) # 800023e6 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	772080e7          	jalr	1906(ra) # 80000be4 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	394080e7          	jalr	916(ra) # 8000080e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00026797          	auipc	a5,0x26
    80000486:	b2e78793          	addi	a5,a5,-1234 # 80025fb0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b8460613          	addi	a2,a2,-1148 # 80008048 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000552:	00011497          	auipc	s1,0x11
    80000556:	38648493          	addi	s1,s1,902 # 800118d8 <pr>
    8000055a:	00008597          	auipc	a1,0x8
    8000055e:	abe58593          	addi	a1,a1,-1346 # 80008018 <etext+0x18>
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	680080e7          	jalr	1664(ra) # 80000be4 <initlock>
  pr.locking = 1;
    8000056c:	4785                	li	a5,1
    8000056e:	cc9c                	sw	a5,24(s1)
}
    80000570:	60e2                	ld	ra,24(sp)
    80000572:	6442                	ld	s0,16(sp)
    80000574:	64a2                	ld	s1,8(sp)
    80000576:	6105                	addi	sp,sp,32
    80000578:	8082                	ret

000000008000057a <backtrace>:

void 
backtrace(void) 
{
    8000057a:	7179                	addi	sp,sp,-48
    8000057c:	f406                	sd	ra,40(sp)
    8000057e:	f022                	sd	s0,32(sp)
    80000580:	ec26                	sd	s1,24(sp)
    80000582:	e84a                	sd	s2,16(sp)
    80000584:	e44e                	sd	s3,8(sp)
    80000586:	e052                	sd	s4,0(sp)
    80000588:	1800                	addi	s0,sp,48

static inline uint64
r_fp()
{
  uint64 x;
  asm volatile("mv %0, s0" : "=r" (x) );
    8000058a:	84a2                	mv	s1,s0
  uint64 fp = r_fp();
  uint64 up_page = PGROUNDUP(fp);
    8000058c:	6905                	lui	s2,0x1
    8000058e:	197d                	addi	s2,s2,-1
    80000590:	9926                	add	s2,s2,s1
    80000592:	79fd                	lui	s3,0xfffff
    80000594:	01397933          	and	s2,s2,s3
  uint64 down_page = PGROUNDDOWN(fp);
    80000598:	0134f9b3          	and	s3,s1,s3
  while (1) {
    if (fp >= up_page || fp < down_page) {
    8000059c:	0324f563          	bgeu	s1,s2,800005c6 <backtrace+0x4c>
    800005a0:	0334e363          	bltu	s1,s3,800005c6 <backtrace+0x4c>
      break;
    }
    printf("%p\n", *((uint64 *)(fp - 8)));
    800005a4:	00008a17          	auipc	s4,0x8
    800005a8:	a7ca0a13          	addi	s4,s4,-1412 # 80008020 <etext+0x20>
    800005ac:	ff84b583          	ld	a1,-8(s1)
    800005b0:	8552                	mv	a0,s4
    800005b2:	00000097          	auipc	ra,0x0
    800005b6:	076080e7          	jalr	118(ra) # 80000628 <printf>
    fp = *(uint64*)(fp - 16);
    800005ba:	ff04b483          	ld	s1,-16(s1)
    if (fp >= up_page || fp < down_page) {
    800005be:	0124f463          	bgeu	s1,s2,800005c6 <backtrace+0x4c>
    800005c2:	ff34f5e3          	bgeu	s1,s3,800005ac <backtrace+0x32>
  }
}
    800005c6:	70a2                	ld	ra,40(sp)
    800005c8:	7402                	ld	s0,32(sp)
    800005ca:	64e2                	ld	s1,24(sp)
    800005cc:	6942                	ld	s2,16(sp)
    800005ce:	69a2                	ld	s3,8(sp)
    800005d0:	6a02                	ld	s4,0(sp)
    800005d2:	6145                	addi	sp,sp,48
    800005d4:	8082                	ret

00000000800005d6 <panic>:
{
    800005d6:	1101                	addi	sp,sp,-32
    800005d8:	ec06                	sd	ra,24(sp)
    800005da:	e822                	sd	s0,16(sp)
    800005dc:	e426                	sd	s1,8(sp)
    800005de:	1000                	addi	s0,sp,32
    800005e0:	84aa                	mv	s1,a0
  pr.locking = 0;
    800005e2:	00011797          	auipc	a5,0x11
    800005e6:	3007a723          	sw	zero,782(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    800005ea:	00008517          	auipc	a0,0x8
    800005ee:	a3e50513          	addi	a0,a0,-1474 # 80008028 <etext+0x28>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	036080e7          	jalr	54(ra) # 80000628 <printf>
  printf(s);
    800005fa:	8526                	mv	a0,s1
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	02c080e7          	jalr	44(ra) # 80000628 <printf>
  printf("\n");
    80000604:	00008517          	auipc	a0,0x8
    80000608:	acc50513          	addi	a0,a0,-1332 # 800080d0 <digits+0x88>
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	01c080e7          	jalr	28(ra) # 80000628 <printf>
  backtrace();
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f66080e7          	jalr	-154(ra) # 8000057a <backtrace>
  panicked = 1; // freeze uart output from other CPUs
    8000061c:	4785                	li	a5,1
    8000061e:	00009717          	auipc	a4,0x9
    80000622:	9ef72123          	sw	a5,-1566(a4) # 80009000 <panicked>
  for(;;)
    80000626:	a001                	j	80000626 <panic+0x50>

0000000080000628 <printf>:
{
    80000628:	7131                	addi	sp,sp,-192
    8000062a:	fc86                	sd	ra,120(sp)
    8000062c:	f8a2                	sd	s0,112(sp)
    8000062e:	f4a6                	sd	s1,104(sp)
    80000630:	f0ca                	sd	s2,96(sp)
    80000632:	ecce                	sd	s3,88(sp)
    80000634:	e8d2                	sd	s4,80(sp)
    80000636:	e4d6                	sd	s5,72(sp)
    80000638:	e0da                	sd	s6,64(sp)
    8000063a:	fc5e                	sd	s7,56(sp)
    8000063c:	f862                	sd	s8,48(sp)
    8000063e:	f466                	sd	s9,40(sp)
    80000640:	f06a                	sd	s10,32(sp)
    80000642:	ec6e                	sd	s11,24(sp)
    80000644:	0100                	addi	s0,sp,128
    80000646:	8a2a                	mv	s4,a0
    80000648:	e40c                	sd	a1,8(s0)
    8000064a:	e810                	sd	a2,16(s0)
    8000064c:	ec14                	sd	a3,24(s0)
    8000064e:	f018                	sd	a4,32(s0)
    80000650:	f41c                	sd	a5,40(s0)
    80000652:	03043823          	sd	a6,48(s0)
    80000656:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    8000065a:	00011d97          	auipc	s11,0x11
    8000065e:	296dad83          	lw	s11,662(s11) # 800118f0 <pr+0x18>
  if(locking)
    80000662:	020d9b63          	bnez	s11,80000698 <printf+0x70>
  if (fmt == 0)
    80000666:	040a0263          	beqz	s4,800006aa <printf+0x82>
  va_start(ap, fmt);
    8000066a:	00840793          	addi	a5,s0,8
    8000066e:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000672:	000a4503          	lbu	a0,0(s4)
    80000676:	16050263          	beqz	a0,800007da <printf+0x1b2>
    8000067a:	4481                	li	s1,0
    if(c != '%'){
    8000067c:	02500a93          	li	s5,37
    switch(c){
    80000680:	07000b13          	li	s6,112
  consputc('x');
    80000684:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000686:	00008b97          	auipc	s7,0x8
    8000068a:	9c2b8b93          	addi	s7,s7,-1598 # 80008048 <digits>
    switch(c){
    8000068e:	07300c93          	li	s9,115
    80000692:	06400c13          	li	s8,100
    80000696:	a82d                	j	800006d0 <printf+0xa8>
    acquire(&pr.lock);
    80000698:	00011517          	auipc	a0,0x11
    8000069c:	24050513          	addi	a0,a0,576 # 800118d8 <pr>
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	5d4080e7          	jalr	1492(ra) # 80000c74 <acquire>
    800006a8:	bf7d                	j	80000666 <printf+0x3e>
    panic("null fmt");
    800006aa:	00008517          	auipc	a0,0x8
    800006ae:	98e50513          	addi	a0,a0,-1650 # 80008038 <etext+0x38>
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	f24080e7          	jalr	-220(ra) # 800005d6 <panic>
      consputc(c);
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bcc080e7          	jalr	-1076(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006c2:	2485                	addiw	s1,s1,1
    800006c4:	009a07b3          	add	a5,s4,s1
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	10050763          	beqz	a0,800007da <printf+0x1b2>
    if(c != '%'){
    800006d0:	ff5515e3          	bne	a0,s5,800006ba <printf+0x92>
    c = fmt[++i] & 0xff;
    800006d4:	2485                	addiw	s1,s1,1
    800006d6:	009a07b3          	add	a5,s4,s1
    800006da:	0007c783          	lbu	a5,0(a5)
    800006de:	0007891b          	sext.w	s2,a5
    if(c == 0)
    800006e2:	cfe5                	beqz	a5,800007da <printf+0x1b2>
    switch(c){
    800006e4:	05678a63          	beq	a5,s6,80000738 <printf+0x110>
    800006e8:	02fb7663          	bgeu	s6,a5,80000714 <printf+0xec>
    800006ec:	09978963          	beq	a5,s9,8000077e <printf+0x156>
    800006f0:	07800713          	li	a4,120
    800006f4:	0ce79863          	bne	a5,a4,800007c4 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    800006f8:	f8843783          	ld	a5,-120(s0)
    800006fc:	00878713          	addi	a4,a5,8
    80000700:	f8e43423          	sd	a4,-120(s0)
    80000704:	4605                	li	a2,1
    80000706:	85ea                	mv	a1,s10
    80000708:	4388                	lw	a0,0(a5)
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	d9c080e7          	jalr	-612(ra) # 800004a6 <printint>
      break;
    80000712:	bf45                	j	800006c2 <printf+0x9a>
    switch(c){
    80000714:	0b578263          	beq	a5,s5,800007b8 <printf+0x190>
    80000718:	0b879663          	bne	a5,s8,800007c4 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000071c:	f8843783          	ld	a5,-120(s0)
    80000720:	00878713          	addi	a4,a5,8
    80000724:	f8e43423          	sd	a4,-120(s0)
    80000728:	4605                	li	a2,1
    8000072a:	45a9                	li	a1,10
    8000072c:	4388                	lw	a0,0(a5)
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	d78080e7          	jalr	-648(ra) # 800004a6 <printint>
      break;
    80000736:	b771                	j	800006c2 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000738:	f8843783          	ld	a5,-120(s0)
    8000073c:	00878713          	addi	a4,a5,8
    80000740:	f8e43423          	sd	a4,-120(s0)
    80000744:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000748:	03000513          	li	a0,48
    8000074c:	00000097          	auipc	ra,0x0
    80000750:	b3a080e7          	jalr	-1222(ra) # 80000286 <consputc>
  consputc('x');
    80000754:	07800513          	li	a0,120
    80000758:	00000097          	auipc	ra,0x0
    8000075c:	b2e080e7          	jalr	-1234(ra) # 80000286 <consputc>
    80000760:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000762:	03c9d793          	srli	a5,s3,0x3c
    80000766:	97de                	add	a5,a5,s7
    80000768:	0007c503          	lbu	a0,0(a5)
    8000076c:	00000097          	auipc	ra,0x0
    80000770:	b1a080e7          	jalr	-1254(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000774:	0992                	slli	s3,s3,0x4
    80000776:	397d                	addiw	s2,s2,-1
    80000778:	fe0915e3          	bnez	s2,80000762 <printf+0x13a>
    8000077c:	b799                	j	800006c2 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    8000077e:	f8843783          	ld	a5,-120(s0)
    80000782:	00878713          	addi	a4,a5,8
    80000786:	f8e43423          	sd	a4,-120(s0)
    8000078a:	0007b903          	ld	s2,0(a5)
    8000078e:	00090e63          	beqz	s2,800007aa <printf+0x182>
      for(; *s; s++)
    80000792:	00094503          	lbu	a0,0(s2) # 1000 <_entry-0x7ffff000>
    80000796:	d515                	beqz	a0,800006c2 <printf+0x9a>
        consputc(*s);
    80000798:	00000097          	auipc	ra,0x0
    8000079c:	aee080e7          	jalr	-1298(ra) # 80000286 <consputc>
      for(; *s; s++)
    800007a0:	0905                	addi	s2,s2,1
    800007a2:	00094503          	lbu	a0,0(s2)
    800007a6:	f96d                	bnez	a0,80000798 <printf+0x170>
    800007a8:	bf29                	j	800006c2 <printf+0x9a>
        s = "(null)";
    800007aa:	00008917          	auipc	s2,0x8
    800007ae:	88690913          	addi	s2,s2,-1914 # 80008030 <etext+0x30>
      for(; *s; s++)
    800007b2:	02800513          	li	a0,40
    800007b6:	b7cd                	j	80000798 <printf+0x170>
      consputc('%');
    800007b8:	8556                	mv	a0,s5
    800007ba:	00000097          	auipc	ra,0x0
    800007be:	acc080e7          	jalr	-1332(ra) # 80000286 <consputc>
      break;
    800007c2:	b701                	j	800006c2 <printf+0x9a>
      consputc('%');
    800007c4:	8556                	mv	a0,s5
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	ac0080e7          	jalr	-1344(ra) # 80000286 <consputc>
      consputc(c);
    800007ce:	854a                	mv	a0,s2
    800007d0:	00000097          	auipc	ra,0x0
    800007d4:	ab6080e7          	jalr	-1354(ra) # 80000286 <consputc>
      break;
    800007d8:	b5ed                	j	800006c2 <printf+0x9a>
  if(locking)
    800007da:	020d9163          	bnez	s11,800007fc <printf+0x1d4>
}
    800007de:	70e6                	ld	ra,120(sp)
    800007e0:	7446                	ld	s0,112(sp)
    800007e2:	74a6                	ld	s1,104(sp)
    800007e4:	7906                	ld	s2,96(sp)
    800007e6:	69e6                	ld	s3,88(sp)
    800007e8:	6a46                	ld	s4,80(sp)
    800007ea:	6aa6                	ld	s5,72(sp)
    800007ec:	6b06                	ld	s6,64(sp)
    800007ee:	7be2                	ld	s7,56(sp)
    800007f0:	7c42                	ld	s8,48(sp)
    800007f2:	7ca2                	ld	s9,40(sp)
    800007f4:	7d02                	ld	s10,32(sp)
    800007f6:	6de2                	ld	s11,24(sp)
    800007f8:	6129                	addi	sp,sp,192
    800007fa:	8082                	ret
    release(&pr.lock);
    800007fc:	00011517          	auipc	a0,0x11
    80000800:	0dc50513          	addi	a0,a0,220 # 800118d8 <pr>
    80000804:	00000097          	auipc	ra,0x0
    80000808:	524080e7          	jalr	1316(ra) # 80000d28 <release>
}
    8000080c:	bfc9                	j	800007de <printf+0x1b6>

000000008000080e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000080e:	1141                	addi	sp,sp,-16
    80000810:	e406                	sd	ra,8(sp)
    80000812:	e022                	sd	s0,0(sp)
    80000814:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000816:	100007b7          	lui	a5,0x10000
    8000081a:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000081e:	f8000713          	li	a4,-128
    80000822:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000826:	470d                	li	a4,3
    80000828:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000082c:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000830:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000834:	469d                	li	a3,7
    80000836:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000083a:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000083e:	00008597          	auipc	a1,0x8
    80000842:	82258593          	addi	a1,a1,-2014 # 80008060 <digits+0x18>
    80000846:	00011517          	auipc	a0,0x11
    8000084a:	0b250513          	addi	a0,a0,178 # 800118f8 <uart_tx_lock>
    8000084e:	00000097          	auipc	ra,0x0
    80000852:	396080e7          	jalr	918(ra) # 80000be4 <initlock>
}
    80000856:	60a2                	ld	ra,8(sp)
    80000858:	6402                	ld	s0,0(sp)
    8000085a:	0141                	addi	sp,sp,16
    8000085c:	8082                	ret

000000008000085e <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000085e:	1101                	addi	sp,sp,-32
    80000860:	ec06                	sd	ra,24(sp)
    80000862:	e822                	sd	s0,16(sp)
    80000864:	e426                	sd	s1,8(sp)
    80000866:	1000                	addi	s0,sp,32
    80000868:	84aa                	mv	s1,a0
  push_off();
    8000086a:	00000097          	auipc	ra,0x0
    8000086e:	3be080e7          	jalr	958(ra) # 80000c28 <push_off>

  if(panicked){
    80000872:	00008797          	auipc	a5,0x8
    80000876:	78e7a783          	lw	a5,1934(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000087e:	c391                	beqz	a5,80000882 <uartputc_sync+0x24>
    for(;;)
    80000880:	a001                	j	80000880 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000882:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	dbf5                	beqz	a5,80000882 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000890:	0ff4f793          	andi	a5,s1,255
    80000894:	10000737          	lui	a4,0x10000
    80000898:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000089c:	00000097          	auipc	ra,0x0
    800008a0:	42c080e7          	jalr	1068(ra) # 80000cc8 <pop_off>
}
    800008a4:	60e2                	ld	ra,24(sp)
    800008a6:	6442                	ld	s0,16(sp)
    800008a8:	64a2                	ld	s1,8(sp)
    800008aa:	6105                	addi	sp,sp,32
    800008ac:	8082                	ret

00000000800008ae <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008ae:	00008797          	auipc	a5,0x8
    800008b2:	7567a783          	lw	a5,1878(a5) # 80009004 <uart_tx_r>
    800008b6:	00008717          	auipc	a4,0x8
    800008ba:	75272703          	lw	a4,1874(a4) # 80009008 <uart_tx_w>
    800008be:	08f70263          	beq	a4,a5,80000942 <uartstart+0x94>
{
    800008c2:	7139                	addi	sp,sp,-64
    800008c4:	fc06                	sd	ra,56(sp)
    800008c6:	f822                	sd	s0,48(sp)
    800008c8:	f426                	sd	s1,40(sp)
    800008ca:	f04a                	sd	s2,32(sp)
    800008cc:	ec4e                	sd	s3,24(sp)
    800008ce:	e852                	sd	s4,16(sp)
    800008d0:	e456                	sd	s5,8(sp)
    800008d2:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d4:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008d8:	00011a17          	auipc	s4,0x11
    800008dc:	020a0a13          	addi	s4,s4,32 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008e0:	00008497          	auipc	s1,0x8
    800008e4:	72448493          	addi	s1,s1,1828 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e8:	00008997          	auipc	s3,0x8
    800008ec:	72098993          	addi	s3,s3,1824 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008f0:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008f4:	0ff77713          	andi	a4,a4,255
    800008f8:	02077713          	andi	a4,a4,32
    800008fc:	cb15                	beqz	a4,80000930 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008fe:	00fa0733          	add	a4,s4,a5
    80000902:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000906:	2785                	addiw	a5,a5,1
    80000908:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090c:	01b7571b          	srliw	a4,a4,0x1b
    80000910:	9fb9                	addw	a5,a5,a4
    80000912:	8bfd                	andi	a5,a5,31
    80000914:	9f99                	subw	a5,a5,a4
    80000916:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	acc080e7          	jalr	-1332(ra) # 800023e6 <wakeup>
    
    WriteReg(THR, c);
    80000922:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000926:	409c                	lw	a5,0(s1)
    80000928:	0009a703          	lw	a4,0(s3)
    8000092c:	fcf712e3          	bne	a4,a5,800008f0 <uartstart+0x42>
  }
}
    80000930:	70e2                	ld	ra,56(sp)
    80000932:	7442                	ld	s0,48(sp)
    80000934:	74a2                	ld	s1,40(sp)
    80000936:	7902                	ld	s2,32(sp)
    80000938:	69e2                	ld	s3,24(sp)
    8000093a:	6a42                	ld	s4,16(sp)
    8000093c:	6aa2                	ld	s5,8(sp)
    8000093e:	6121                	addi	sp,sp,64
    80000940:	8082                	ret
    80000942:	8082                	ret

0000000080000944 <uartputc>:
{
    80000944:	7179                	addi	sp,sp,-48
    80000946:	f406                	sd	ra,40(sp)
    80000948:	f022                	sd	s0,32(sp)
    8000094a:	ec26                	sd	s1,24(sp)
    8000094c:	e84a                	sd	s2,16(sp)
    8000094e:	e44e                	sd	s3,8(sp)
    80000950:	e052                	sd	s4,0(sp)
    80000952:	1800                	addi	s0,sp,48
    80000954:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000956:	00011517          	auipc	a0,0x11
    8000095a:	fa250513          	addi	a0,a0,-94 # 800118f8 <uart_tx_lock>
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	316080e7          	jalr	790(ra) # 80000c74 <acquire>
  if(panicked){
    80000966:	00008797          	auipc	a5,0x8
    8000096a:	69a7a783          	lw	a5,1690(a5) # 80009000 <panicked>
    8000096e:	c391                	beqz	a5,80000972 <uartputc+0x2e>
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000972:	00008717          	auipc	a4,0x8
    80000976:	69672703          	lw	a4,1686(a4) # 80009008 <uart_tx_w>
    8000097a:	0017079b          	addiw	a5,a4,1
    8000097e:	41f7d69b          	sraiw	a3,a5,0x1f
    80000982:	01b6d69b          	srliw	a3,a3,0x1b
    80000986:	9fb5                	addw	a5,a5,a3
    80000988:	8bfd                	andi	a5,a5,31
    8000098a:	9f95                	subw	a5,a5,a3
    8000098c:	00008697          	auipc	a3,0x8
    80000990:	6786a683          	lw	a3,1656(a3) # 80009004 <uart_tx_r>
    80000994:	04f69263          	bne	a3,a5,800009d8 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000998:	00011a17          	auipc	s4,0x11
    8000099c:	f60a0a13          	addi	s4,s4,-160 # 800118f8 <uart_tx_lock>
    800009a0:	00008497          	auipc	s1,0x8
    800009a4:	66448493          	addi	s1,s1,1636 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009a8:	00008917          	auipc	s2,0x8
    800009ac:	66090913          	addi	s2,s2,1632 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009b0:	85d2                	mv	a1,s4
    800009b2:	8526                	mv	a0,s1
    800009b4:	00002097          	auipc	ra,0x2
    800009b8:	8ac080e7          	jalr	-1876(ra) # 80002260 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009bc:	00092703          	lw	a4,0(s2)
    800009c0:	0017079b          	addiw	a5,a4,1
    800009c4:	41f7d69b          	sraiw	a3,a5,0x1f
    800009c8:	01b6d69b          	srliw	a3,a3,0x1b
    800009cc:	9fb5                	addw	a5,a5,a3
    800009ce:	8bfd                	andi	a5,a5,31
    800009d0:	9f95                	subw	a5,a5,a3
    800009d2:	4094                	lw	a3,0(s1)
    800009d4:	fcf68ee3          	beq	a3,a5,800009b0 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009d8:	00011497          	auipc	s1,0x11
    800009dc:	f2048493          	addi	s1,s1,-224 # 800118f8 <uart_tx_lock>
    800009e0:	9726                	add	a4,a4,s1
    800009e2:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009e6:	00008717          	auipc	a4,0x8
    800009ea:	62f72123          	sw	a5,1570(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	ec0080e7          	jalr	-320(ra) # 800008ae <uartstart>
      release(&uart_tx_lock);
    800009f6:	8526                	mv	a0,s1
    800009f8:	00000097          	auipc	ra,0x0
    800009fc:	330080e7          	jalr	816(ra) # 80000d28 <release>
}
    80000a00:	70a2                	ld	ra,40(sp)
    80000a02:	7402                	ld	s0,32(sp)
    80000a04:	64e2                	ld	s1,24(sp)
    80000a06:	6942                	ld	s2,16(sp)
    80000a08:	69a2                	ld	s3,8(sp)
    80000a0a:	6a02                	ld	s4,0(sp)
    80000a0c:	6145                	addi	sp,sp,48
    80000a0e:	8082                	ret

0000000080000a10 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a10:	1141                	addi	sp,sp,-16
    80000a12:	e422                	sd	s0,8(sp)
    80000a14:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a16:	100007b7          	lui	a5,0x10000
    80000a1a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a1e:	8b85                	andi	a5,a5,1
    80000a20:	cb91                	beqz	a5,80000a34 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a22:	100007b7          	lui	a5,0x10000
    80000a26:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a2a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a2e:	6422                	ld	s0,8(sp)
    80000a30:	0141                	addi	sp,sp,16
    80000a32:	8082                	ret
    return -1;
    80000a34:	557d                	li	a0,-1
    80000a36:	bfe5                	j	80000a2e <uartgetc+0x1e>

0000000080000a38 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a38:	1101                	addi	sp,sp,-32
    80000a3a:	ec06                	sd	ra,24(sp)
    80000a3c:	e822                	sd	s0,16(sp)
    80000a3e:	e426                	sd	s1,8(sp)
    80000a40:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a42:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	fcc080e7          	jalr	-52(ra) # 80000a10 <uartgetc>
    if(c == -1)
    80000a4c:	00950763          	beq	a0,s1,80000a5a <uartintr+0x22>
      break;
    consoleintr(c);
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	878080e7          	jalr	-1928(ra) # 800002c8 <consoleintr>
  while(1){
    80000a58:	b7f5                	j	80000a44 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a5a:	00011497          	auipc	s1,0x11
    80000a5e:	e9e48493          	addi	s1,s1,-354 # 800118f8 <uart_tx_lock>
    80000a62:	8526                	mv	a0,s1
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	210080e7          	jalr	528(ra) # 80000c74 <acquire>
  uartstart();
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	e42080e7          	jalr	-446(ra) # 800008ae <uartstart>
  release(&uart_tx_lock);
    80000a74:	8526                	mv	a0,s1
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	2b2080e7          	jalr	690(ra) # 80000d28 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6105                	addi	sp,sp,32
    80000a86:	8082                	ret

0000000080000a88 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a88:	1101                	addi	sp,sp,-32
    80000a8a:	ec06                	sd	ra,24(sp)
    80000a8c:	e822                	sd	s0,16(sp)
    80000a8e:	e426                	sd	s1,8(sp)
    80000a90:	e04a                	sd	s2,0(sp)
    80000a92:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a94:	03451793          	slli	a5,a0,0x34
    80000a98:	ebb9                	bnez	a5,80000aee <kfree+0x66>
    80000a9a:	84aa                	mv	s1,a0
    80000a9c:	0002a797          	auipc	a5,0x2a
    80000aa0:	56478793          	addi	a5,a5,1380 # 8002b000 <end>
    80000aa4:	04f56563          	bltu	a0,a5,80000aee <kfree+0x66>
    80000aa8:	47c5                	li	a5,17
    80000aaa:	07ee                	slli	a5,a5,0x1b
    80000aac:	04f57163          	bgeu	a0,a5,80000aee <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000ab0:	6605                	lui	a2,0x1
    80000ab2:	4585                	li	a1,1
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	2bc080e7          	jalr	700(ra) # 80000d70 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000abc:	00011917          	auipc	s2,0x11
    80000ac0:	e7490913          	addi	s2,s2,-396 # 80011930 <kmem>
    80000ac4:	854a                	mv	a0,s2
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	1ae080e7          	jalr	430(ra) # 80000c74 <acquire>
  r->next = kmem.freelist;
    80000ace:	01893783          	ld	a5,24(s2)
    80000ad2:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ad4:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ad8:	854a                	mv	a0,s2
    80000ada:	00000097          	auipc	ra,0x0
    80000ade:	24e080e7          	jalr	590(ra) # 80000d28 <release>
}
    80000ae2:	60e2                	ld	ra,24(sp)
    80000ae4:	6442                	ld	s0,16(sp)
    80000ae6:	64a2                	ld	s1,8(sp)
    80000ae8:	6902                	ld	s2,0(sp)
    80000aea:	6105                	addi	sp,sp,32
    80000aec:	8082                	ret
    panic("kfree");
    80000aee:	00007517          	auipc	a0,0x7
    80000af2:	57a50513          	addi	a0,a0,1402 # 80008068 <digits+0x20>
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	ae0080e7          	jalr	-1312(ra) # 800005d6 <panic>

0000000080000afe <freerange>:
{
    80000afe:	7179                	addi	sp,sp,-48
    80000b00:	f406                	sd	ra,40(sp)
    80000b02:	f022                	sd	s0,32(sp)
    80000b04:	ec26                	sd	s1,24(sp)
    80000b06:	e84a                	sd	s2,16(sp)
    80000b08:	e44e                	sd	s3,8(sp)
    80000b0a:	e052                	sd	s4,0(sp)
    80000b0c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b0e:	6785                	lui	a5,0x1
    80000b10:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b14:	94aa                	add	s1,s1,a0
    80000b16:	757d                	lui	a0,0xfffff
    80000b18:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b1a:	94be                	add	s1,s1,a5
    80000b1c:	0095ee63          	bltu	a1,s1,80000b38 <freerange+0x3a>
    80000b20:	892e                	mv	s2,a1
    kfree(p);
    80000b22:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b24:	6985                	lui	s3,0x1
    kfree(p);
    80000b26:	01448533          	add	a0,s1,s4
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	f5e080e7          	jalr	-162(ra) # 80000a88 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b32:	94ce                	add	s1,s1,s3
    80000b34:	fe9979e3          	bgeu	s2,s1,80000b26 <freerange+0x28>
}
    80000b38:	70a2                	ld	ra,40(sp)
    80000b3a:	7402                	ld	s0,32(sp)
    80000b3c:	64e2                	ld	s1,24(sp)
    80000b3e:	6942                	ld	s2,16(sp)
    80000b40:	69a2                	ld	s3,8(sp)
    80000b42:	6a02                	ld	s4,0(sp)
    80000b44:	6145                	addi	sp,sp,48
    80000b46:	8082                	ret

0000000080000b48 <kinit>:
{
    80000b48:	1141                	addi	sp,sp,-16
    80000b4a:	e406                	sd	ra,8(sp)
    80000b4c:	e022                	sd	s0,0(sp)
    80000b4e:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b50:	00007597          	auipc	a1,0x7
    80000b54:	52058593          	addi	a1,a1,1312 # 80008070 <digits+0x28>
    80000b58:	00011517          	auipc	a0,0x11
    80000b5c:	dd850513          	addi	a0,a0,-552 # 80011930 <kmem>
    80000b60:	00000097          	auipc	ra,0x0
    80000b64:	084080e7          	jalr	132(ra) # 80000be4 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b68:	45c5                	li	a1,17
    80000b6a:	05ee                	slli	a1,a1,0x1b
    80000b6c:	0002a517          	auipc	a0,0x2a
    80000b70:	49450513          	addi	a0,a0,1172 # 8002b000 <end>
    80000b74:	00000097          	auipc	ra,0x0
    80000b78:	f8a080e7          	jalr	-118(ra) # 80000afe <freerange>
}
    80000b7c:	60a2                	ld	ra,8(sp)
    80000b7e:	6402                	ld	s0,0(sp)
    80000b80:	0141                	addi	sp,sp,16
    80000b82:	8082                	ret

0000000080000b84 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b84:	1101                	addi	sp,sp,-32
    80000b86:	ec06                	sd	ra,24(sp)
    80000b88:	e822                	sd	s0,16(sp)
    80000b8a:	e426                	sd	s1,8(sp)
    80000b8c:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b8e:	00011497          	auipc	s1,0x11
    80000b92:	da248493          	addi	s1,s1,-606 # 80011930 <kmem>
    80000b96:	8526                	mv	a0,s1
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	0dc080e7          	jalr	220(ra) # 80000c74 <acquire>
  r = kmem.freelist;
    80000ba0:	6c84                	ld	s1,24(s1)
  if(r)
    80000ba2:	c885                	beqz	s1,80000bd2 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000ba4:	609c                	ld	a5,0(s1)
    80000ba6:	00011517          	auipc	a0,0x11
    80000baa:	d8a50513          	addi	a0,a0,-630 # 80011930 <kmem>
    80000bae:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000bb0:	00000097          	auipc	ra,0x0
    80000bb4:	178080e7          	jalr	376(ra) # 80000d28 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bb8:	6605                	lui	a2,0x1
    80000bba:	4595                	li	a1,5
    80000bbc:	8526                	mv	a0,s1
    80000bbe:	00000097          	auipc	ra,0x0
    80000bc2:	1b2080e7          	jalr	434(ra) # 80000d70 <memset>
  return (void*)r;
}
    80000bc6:	8526                	mv	a0,s1
    80000bc8:	60e2                	ld	ra,24(sp)
    80000bca:	6442                	ld	s0,16(sp)
    80000bcc:	64a2                	ld	s1,8(sp)
    80000bce:	6105                	addi	sp,sp,32
    80000bd0:	8082                	ret
  release(&kmem.lock);
    80000bd2:	00011517          	auipc	a0,0x11
    80000bd6:	d5e50513          	addi	a0,a0,-674 # 80011930 <kmem>
    80000bda:	00000097          	auipc	ra,0x0
    80000bde:	14e080e7          	jalr	334(ra) # 80000d28 <release>
  if(r)
    80000be2:	b7d5                	j	80000bc6 <kalloc+0x42>

0000000080000be4 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000be4:	1141                	addi	sp,sp,-16
    80000be6:	e422                	sd	s0,8(sp)
    80000be8:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bea:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bec:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bf0:	00053823          	sd	zero,16(a0)
}
    80000bf4:	6422                	ld	s0,8(sp)
    80000bf6:	0141                	addi	sp,sp,16
    80000bf8:	8082                	ret

0000000080000bfa <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bfa:	411c                	lw	a5,0(a0)
    80000bfc:	e399                	bnez	a5,80000c02 <holding+0x8>
    80000bfe:	4501                	li	a0,0
  return r;
}
    80000c00:	8082                	ret
{
    80000c02:	1101                	addi	sp,sp,-32
    80000c04:	ec06                	sd	ra,24(sp)
    80000c06:	e822                	sd	s0,16(sp)
    80000c08:	e426                	sd	s1,8(sp)
    80000c0a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c0c:	6904                	ld	s1,16(a0)
    80000c0e:	00001097          	auipc	ra,0x1
    80000c12:	e18080e7          	jalr	-488(ra) # 80001a26 <mycpu>
    80000c16:	40a48533          	sub	a0,s1,a0
    80000c1a:	00153513          	seqz	a0,a0
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret

0000000080000c28 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c28:	1101                	addi	sp,sp,-32
    80000c2a:	ec06                	sd	ra,24(sp)
    80000c2c:	e822                	sd	s0,16(sp)
    80000c2e:	e426                	sd	s1,8(sp)
    80000c30:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c32:	100024f3          	csrr	s1,sstatus
    80000c36:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c3a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c3c:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	de6080e7          	jalr	-538(ra) # 80001a26 <mycpu>
    80000c48:	5d3c                	lw	a5,120(a0)
    80000c4a:	cf89                	beqz	a5,80000c64 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c4c:	00001097          	auipc	ra,0x1
    80000c50:	dda080e7          	jalr	-550(ra) # 80001a26 <mycpu>
    80000c54:	5d3c                	lw	a5,120(a0)
    80000c56:	2785                	addiw	a5,a5,1
    80000c58:	dd3c                	sw	a5,120(a0)
}
    80000c5a:	60e2                	ld	ra,24(sp)
    80000c5c:	6442                	ld	s0,16(sp)
    80000c5e:	64a2                	ld	s1,8(sp)
    80000c60:	6105                	addi	sp,sp,32
    80000c62:	8082                	ret
    mycpu()->intena = old;
    80000c64:	00001097          	auipc	ra,0x1
    80000c68:	dc2080e7          	jalr	-574(ra) # 80001a26 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c6c:	8085                	srli	s1,s1,0x1
    80000c6e:	8885                	andi	s1,s1,1
    80000c70:	dd64                	sw	s1,124(a0)
    80000c72:	bfe9                	j	80000c4c <push_off+0x24>

0000000080000c74 <acquire>:
{
    80000c74:	1101                	addi	sp,sp,-32
    80000c76:	ec06                	sd	ra,24(sp)
    80000c78:	e822                	sd	s0,16(sp)
    80000c7a:	e426                	sd	s1,8(sp)
    80000c7c:	1000                	addi	s0,sp,32
    80000c7e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	fa8080e7          	jalr	-88(ra) # 80000c28 <push_off>
  if(holding(lk))
    80000c88:	8526                	mv	a0,s1
    80000c8a:	00000097          	auipc	ra,0x0
    80000c8e:	f70080e7          	jalr	-144(ra) # 80000bfa <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c92:	4705                	li	a4,1
  if(holding(lk))
    80000c94:	e115                	bnez	a0,80000cb8 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c96:	87ba                	mv	a5,a4
    80000c98:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c9c:	2781                	sext.w	a5,a5
    80000c9e:	ffe5                	bnez	a5,80000c96 <acquire+0x22>
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	d82080e7          	jalr	-638(ra) # 80001a26 <mycpu>
    80000cac:	e888                	sd	a0,16(s1)
}
    80000cae:	60e2                	ld	ra,24(sp)
    80000cb0:	6442                	ld	s0,16(sp)
    80000cb2:	64a2                	ld	s1,8(sp)
    80000cb4:	6105                	addi	sp,sp,32
    80000cb6:	8082                	ret
    panic("acquire");
    80000cb8:	00007517          	auipc	a0,0x7
    80000cbc:	3c050513          	addi	a0,a0,960 # 80008078 <digits+0x30>
    80000cc0:	00000097          	auipc	ra,0x0
    80000cc4:	916080e7          	jalr	-1770(ra) # 800005d6 <panic>

0000000080000cc8 <pop_off>:

void
pop_off(void)
{
    80000cc8:	1141                	addi	sp,sp,-16
    80000cca:	e406                	sd	ra,8(sp)
    80000ccc:	e022                	sd	s0,0(sp)
    80000cce:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cd0:	00001097          	auipc	ra,0x1
    80000cd4:	d56080e7          	jalr	-682(ra) # 80001a26 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cdc:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cde:	e78d                	bnez	a5,80000d08 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ce0:	5d3c                	lw	a5,120(a0)
    80000ce2:	02f05b63          	blez	a5,80000d18 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ce6:	37fd                	addiw	a5,a5,-1
    80000ce8:	0007871b          	sext.w	a4,a5
    80000cec:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cee:	eb09                	bnez	a4,80000d00 <pop_off+0x38>
    80000cf0:	5d7c                	lw	a5,124(a0)
    80000cf2:	c799                	beqz	a5,80000d00 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cf4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cf8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cfc:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d00:	60a2                	ld	ra,8(sp)
    80000d02:	6402                	ld	s0,0(sp)
    80000d04:	0141                	addi	sp,sp,16
    80000d06:	8082                	ret
    panic("pop_off - interruptible");
    80000d08:	00007517          	auipc	a0,0x7
    80000d0c:	37850513          	addi	a0,a0,888 # 80008080 <digits+0x38>
    80000d10:	00000097          	auipc	ra,0x0
    80000d14:	8c6080e7          	jalr	-1850(ra) # 800005d6 <panic>
    panic("pop_off");
    80000d18:	00007517          	auipc	a0,0x7
    80000d1c:	38050513          	addi	a0,a0,896 # 80008098 <digits+0x50>
    80000d20:	00000097          	auipc	ra,0x0
    80000d24:	8b6080e7          	jalr	-1866(ra) # 800005d6 <panic>

0000000080000d28 <release>:
{
    80000d28:	1101                	addi	sp,sp,-32
    80000d2a:	ec06                	sd	ra,24(sp)
    80000d2c:	e822                	sd	s0,16(sp)
    80000d2e:	e426                	sd	s1,8(sp)
    80000d30:	1000                	addi	s0,sp,32
    80000d32:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d34:	00000097          	auipc	ra,0x0
    80000d38:	ec6080e7          	jalr	-314(ra) # 80000bfa <holding>
    80000d3c:	c115                	beqz	a0,80000d60 <release+0x38>
  lk->cpu = 0;
    80000d3e:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d42:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d46:	0f50000f          	fence	iorw,ow
    80000d4a:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d4e:	00000097          	auipc	ra,0x0
    80000d52:	f7a080e7          	jalr	-134(ra) # 80000cc8 <pop_off>
}
    80000d56:	60e2                	ld	ra,24(sp)
    80000d58:	6442                	ld	s0,16(sp)
    80000d5a:	64a2                	ld	s1,8(sp)
    80000d5c:	6105                	addi	sp,sp,32
    80000d5e:	8082                	ret
    panic("release");
    80000d60:	00007517          	auipc	a0,0x7
    80000d64:	34050513          	addi	a0,a0,832 # 800080a0 <digits+0x58>
    80000d68:	00000097          	auipc	ra,0x0
    80000d6c:	86e080e7          	jalr	-1938(ra) # 800005d6 <panic>

0000000080000d70 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d70:	1141                	addi	sp,sp,-16
    80000d72:	e422                	sd	s0,8(sp)
    80000d74:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d76:	ce09                	beqz	a2,80000d90 <memset+0x20>
    80000d78:	87aa                	mv	a5,a0
    80000d7a:	fff6071b          	addiw	a4,a2,-1
    80000d7e:	1702                	slli	a4,a4,0x20
    80000d80:	9301                	srli	a4,a4,0x20
    80000d82:	0705                	addi	a4,a4,1
    80000d84:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d86:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d8a:	0785                	addi	a5,a5,1
    80000d8c:	fee79de3          	bne	a5,a4,80000d86 <memset+0x16>
  }
  return dst;
}
    80000d90:	6422                	ld	s0,8(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d9c:	ca05                	beqz	a2,80000dcc <memcmp+0x36>
    80000d9e:	fff6069b          	addiw	a3,a2,-1
    80000da2:	1682                	slli	a3,a3,0x20
    80000da4:	9281                	srli	a3,a3,0x20
    80000da6:	0685                	addi	a3,a3,1
    80000da8:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	0005c703          	lbu	a4,0(a1)
    80000db2:	00e79863          	bne	a5,a4,80000dc2 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000db6:	0505                	addi	a0,a0,1
    80000db8:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dba:	fed518e3          	bne	a0,a3,80000daa <memcmp+0x14>
  }

  return 0;
    80000dbe:	4501                	li	a0,0
    80000dc0:	a019                	j	80000dc6 <memcmp+0x30>
      return *s1 - *s2;
    80000dc2:	40e7853b          	subw	a0,a5,a4
}
    80000dc6:	6422                	ld	s0,8(sp)
    80000dc8:	0141                	addi	sp,sp,16
    80000dca:	8082                	ret
  return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	bfe5                	j	80000dc6 <memcmp+0x30>

0000000080000dd0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e422                	sd	s0,8(sp)
    80000dd4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dd6:	00a5f963          	bgeu	a1,a0,80000de8 <memmove+0x18>
    80000dda:	02061713          	slli	a4,a2,0x20
    80000dde:	9301                	srli	a4,a4,0x20
    80000de0:	00e587b3          	add	a5,a1,a4
    80000de4:	02f56563          	bltu	a0,a5,80000e0e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000de8:	fff6069b          	addiw	a3,a2,-1
    80000dec:	ce11                	beqz	a2,80000e08 <memmove+0x38>
    80000dee:	1682                	slli	a3,a3,0x20
    80000df0:	9281                	srli	a3,a3,0x20
    80000df2:	0685                	addi	a3,a3,1
    80000df4:	96ae                	add	a3,a3,a1
    80000df6:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	0785                	addi	a5,a5,1
    80000dfc:	fff5c703          	lbu	a4,-1(a1)
    80000e00:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e04:	fed59ae3          	bne	a1,a3,80000df8 <memmove+0x28>

  return dst;
}
    80000e08:	6422                	ld	s0,8(sp)
    80000e0a:	0141                	addi	sp,sp,16
    80000e0c:	8082                	ret
    d += n;
    80000e0e:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e10:	fff6069b          	addiw	a3,a2,-1
    80000e14:	da75                	beqz	a2,80000e08 <memmove+0x38>
    80000e16:	02069613          	slli	a2,a3,0x20
    80000e1a:	9201                	srli	a2,a2,0x20
    80000e1c:	fff64613          	not	a2,a2
    80000e20:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e22:	17fd                	addi	a5,a5,-1
    80000e24:	177d                	addi	a4,a4,-1
    80000e26:	0007c683          	lbu	a3,0(a5)
    80000e2a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e2e:	fec79ae3          	bne	a5,a2,80000e22 <memmove+0x52>
    80000e32:	bfd9                	j	80000e08 <memmove+0x38>

0000000080000e34 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e34:	1141                	addi	sp,sp,-16
    80000e36:	e406                	sd	ra,8(sp)
    80000e38:	e022                	sd	s0,0(sp)
    80000e3a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e3c:	00000097          	auipc	ra,0x0
    80000e40:	f94080e7          	jalr	-108(ra) # 80000dd0 <memmove>
}
    80000e44:	60a2                	ld	ra,8(sp)
    80000e46:	6402                	ld	s0,0(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e52:	ce11                	beqz	a2,80000e6e <strncmp+0x22>
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf89                	beqz	a5,80000e72 <strncmp+0x26>
    80000e5a:	0005c703          	lbu	a4,0(a1)
    80000e5e:	00f71a63          	bne	a4,a5,80000e72 <strncmp+0x26>
    n--, p++, q++;
    80000e62:	367d                	addiw	a2,a2,-1
    80000e64:	0505                	addi	a0,a0,1
    80000e66:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e68:	f675                	bnez	a2,80000e54 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e6a:	4501                	li	a0,0
    80000e6c:	a809                	j	80000e7e <strncmp+0x32>
    80000e6e:	4501                	li	a0,0
    80000e70:	a039                	j	80000e7e <strncmp+0x32>
  if(n == 0)
    80000e72:	ca09                	beqz	a2,80000e84 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e74:	00054503          	lbu	a0,0(a0)
    80000e78:	0005c783          	lbu	a5,0(a1)
    80000e7c:	9d1d                	subw	a0,a0,a5
}
    80000e7e:	6422                	ld	s0,8(sp)
    80000e80:	0141                	addi	sp,sp,16
    80000e82:	8082                	ret
    return 0;
    80000e84:	4501                	li	a0,0
    80000e86:	bfe5                	j	80000e7e <strncmp+0x32>

0000000080000e88 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e88:	1141                	addi	sp,sp,-16
    80000e8a:	e422                	sd	s0,8(sp)
    80000e8c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e8e:	872a                	mv	a4,a0
    80000e90:	8832                	mv	a6,a2
    80000e92:	367d                	addiw	a2,a2,-1
    80000e94:	01005963          	blez	a6,80000ea6 <strncpy+0x1e>
    80000e98:	0705                	addi	a4,a4,1
    80000e9a:	0005c783          	lbu	a5,0(a1)
    80000e9e:	fef70fa3          	sb	a5,-1(a4)
    80000ea2:	0585                	addi	a1,a1,1
    80000ea4:	f7f5                	bnez	a5,80000e90 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ea6:	00c05d63          	blez	a2,80000ec0 <strncpy+0x38>
    80000eaa:	86ba                	mv	a3,a4
    *s++ = 0;
    80000eac:	0685                	addi	a3,a3,1
    80000eae:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000eb2:	fff6c793          	not	a5,a3
    80000eb6:	9fb9                	addw	a5,a5,a4
    80000eb8:	010787bb          	addw	a5,a5,a6
    80000ebc:	fef048e3          	bgtz	a5,80000eac <strncpy+0x24>
  return os;
}
    80000ec0:	6422                	ld	s0,8(sp)
    80000ec2:	0141                	addi	sp,sp,16
    80000ec4:	8082                	ret

0000000080000ec6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ec6:	1141                	addi	sp,sp,-16
    80000ec8:	e422                	sd	s0,8(sp)
    80000eca:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ecc:	02c05363          	blez	a2,80000ef2 <safestrcpy+0x2c>
    80000ed0:	fff6069b          	addiw	a3,a2,-1
    80000ed4:	1682                	slli	a3,a3,0x20
    80000ed6:	9281                	srli	a3,a3,0x20
    80000ed8:	96ae                	add	a3,a3,a1
    80000eda:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000edc:	00d58963          	beq	a1,a3,80000eee <safestrcpy+0x28>
    80000ee0:	0585                	addi	a1,a1,1
    80000ee2:	0785                	addi	a5,a5,1
    80000ee4:	fff5c703          	lbu	a4,-1(a1)
    80000ee8:	fee78fa3          	sb	a4,-1(a5)
    80000eec:	fb65                	bnez	a4,80000edc <safestrcpy+0x16>
    ;
  *s = 0;
    80000eee:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ef2:	6422                	ld	s0,8(sp)
    80000ef4:	0141                	addi	sp,sp,16
    80000ef6:	8082                	ret

0000000080000ef8 <strlen>:

int
strlen(const char *s)
{
    80000ef8:	1141                	addi	sp,sp,-16
    80000efa:	e422                	sd	s0,8(sp)
    80000efc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000efe:	00054783          	lbu	a5,0(a0)
    80000f02:	cf91                	beqz	a5,80000f1e <strlen+0x26>
    80000f04:	0505                	addi	a0,a0,1
    80000f06:	87aa                	mv	a5,a0
    80000f08:	4685                	li	a3,1
    80000f0a:	9e89                	subw	a3,a3,a0
    80000f0c:	00f6853b          	addw	a0,a3,a5
    80000f10:	0785                	addi	a5,a5,1
    80000f12:	fff7c703          	lbu	a4,-1(a5)
    80000f16:	fb7d                	bnez	a4,80000f0c <strlen+0x14>
    ;
  return n;
}
    80000f18:	6422                	ld	s0,8(sp)
    80000f1a:	0141                	addi	sp,sp,16
    80000f1c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f1e:	4501                	li	a0,0
    80000f20:	bfe5                	j	80000f18 <strlen+0x20>

0000000080000f22 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f22:	1141                	addi	sp,sp,-16
    80000f24:	e406                	sd	ra,8(sp)
    80000f26:	e022                	sd	s0,0(sp)
    80000f28:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f2a:	00001097          	auipc	ra,0x1
    80000f2e:	aec080e7          	jalr	-1300(ra) # 80001a16 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f32:	00008717          	auipc	a4,0x8
    80000f36:	0da70713          	addi	a4,a4,218 # 8000900c <started>
  if(cpuid() == 0){
    80000f3a:	c139                	beqz	a0,80000f80 <main+0x5e>
    while(started == 0)
    80000f3c:	431c                	lw	a5,0(a4)
    80000f3e:	2781                	sext.w	a5,a5
    80000f40:	dff5                	beqz	a5,80000f3c <main+0x1a>
      ;
    __sync_synchronize();
    80000f42:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f46:	00001097          	auipc	ra,0x1
    80000f4a:	ad0080e7          	jalr	-1328(ra) # 80001a16 <cpuid>
    80000f4e:	85aa                	mv	a1,a0
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	17050513          	addi	a0,a0,368 # 800080c0 <digits+0x78>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	6d0080e7          	jalr	1744(ra) # 80000628 <printf>
    kvminithart();    // turn on paging
    80000f60:	00000097          	auipc	ra,0x0
    80000f64:	0d8080e7          	jalr	216(ra) # 80001038 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f68:	00001097          	auipc	ra,0x1
    80000f6c:	746080e7          	jalr	1862(ra) # 800026ae <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f70:	00005097          	auipc	ra,0x5
    80000f74:	fd0080e7          	jalr	-48(ra) # 80005f40 <plicinithart>
  }

  scheduler();        
    80000f78:	00001097          	auipc	ra,0x1
    80000f7c:	00c080e7          	jalr	12(ra) # 80001f84 <scheduler>
    consoleinit();
    80000f80:	fffff097          	auipc	ra,0xfffff
    80000f84:	4da080e7          	jalr	1242(ra) # 8000045a <consoleinit>
    printfinit();
    80000f88:	fffff097          	auipc	ra,0xfffff
    80000f8c:	5c0080e7          	jalr	1472(ra) # 80000548 <printfinit>
    printf("\n");
    80000f90:	00007517          	auipc	a0,0x7
    80000f94:	14050513          	addi	a0,a0,320 # 800080d0 <digits+0x88>
    80000f98:	fffff097          	auipc	ra,0xfffff
    80000f9c:	690080e7          	jalr	1680(ra) # 80000628 <printf>
    printf("xv6 kernel is booting\n");
    80000fa0:	00007517          	auipc	a0,0x7
    80000fa4:	10850513          	addi	a0,a0,264 # 800080a8 <digits+0x60>
    80000fa8:	fffff097          	auipc	ra,0xfffff
    80000fac:	680080e7          	jalr	1664(ra) # 80000628 <printf>
    printf("\n");
    80000fb0:	00007517          	auipc	a0,0x7
    80000fb4:	12050513          	addi	a0,a0,288 # 800080d0 <digits+0x88>
    80000fb8:	fffff097          	auipc	ra,0xfffff
    80000fbc:	670080e7          	jalr	1648(ra) # 80000628 <printf>
    kinit();         // physical page allocator
    80000fc0:	00000097          	auipc	ra,0x0
    80000fc4:	b88080e7          	jalr	-1144(ra) # 80000b48 <kinit>
    kvminit();       // create kernel page table
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	2a0080e7          	jalr	672(ra) # 80001268 <kvminit>
    kvminithart();   // turn on paging
    80000fd0:	00000097          	auipc	ra,0x0
    80000fd4:	068080e7          	jalr	104(ra) # 80001038 <kvminithart>
    procinit();      // process table
    80000fd8:	00001097          	auipc	ra,0x1
    80000fdc:	96e080e7          	jalr	-1682(ra) # 80001946 <procinit>
    trapinit();      // trap vectors
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	6a6080e7          	jalr	1702(ra) # 80002686 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fe8:	00001097          	auipc	ra,0x1
    80000fec:	6c6080e7          	jalr	1734(ra) # 800026ae <trapinithart>
    plicinit();      // set up interrupt controller
    80000ff0:	00005097          	auipc	ra,0x5
    80000ff4:	f3a080e7          	jalr	-198(ra) # 80005f2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ff8:	00005097          	auipc	ra,0x5
    80000ffc:	f48080e7          	jalr	-184(ra) # 80005f40 <plicinithart>
    binit();         // buffer cache
    80001000:	00002097          	auipc	ra,0x2
    80001004:	f14080e7          	jalr	-236(ra) # 80002f14 <binit>
    iinit();         // inode cache
    80001008:	00002097          	auipc	ra,0x2
    8000100c:	5a4080e7          	jalr	1444(ra) # 800035ac <iinit>
    fileinit();      // file table
    80001010:	00003097          	auipc	ra,0x3
    80001014:	53e080e7          	jalr	1342(ra) # 8000454e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001018:	00005097          	auipc	ra,0x5
    8000101c:	030080e7          	jalr	48(ra) # 80006048 <virtio_disk_init>
    userinit();      // first user process
    80001020:	00001097          	auipc	ra,0x1
    80001024:	cfe080e7          	jalr	-770(ra) # 80001d1e <userinit>
    __sync_synchronize();
    80001028:	0ff0000f          	fence
    started = 1;
    8000102c:	4785                	li	a5,1
    8000102e:	00008717          	auipc	a4,0x8
    80001032:	fcf72f23          	sw	a5,-34(a4) # 8000900c <started>
    80001036:	b789                	j	80000f78 <main+0x56>

0000000080001038 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001038:	1141                	addi	sp,sp,-16
    8000103a:	e422                	sd	s0,8(sp)
    8000103c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000103e:	00008797          	auipc	a5,0x8
    80001042:	fd27b783          	ld	a5,-46(a5) # 80009010 <kernel_pagetable>
    80001046:	83b1                	srli	a5,a5,0xc
    80001048:	577d                	li	a4,-1
    8000104a:	177e                	slli	a4,a4,0x3f
    8000104c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000104e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001052:	12000073          	sfence.vma
  sfence_vma();
}
    80001056:	6422                	ld	s0,8(sp)
    80001058:	0141                	addi	sp,sp,16
    8000105a:	8082                	ret

000000008000105c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000105c:	7139                	addi	sp,sp,-64
    8000105e:	fc06                	sd	ra,56(sp)
    80001060:	f822                	sd	s0,48(sp)
    80001062:	f426                	sd	s1,40(sp)
    80001064:	f04a                	sd	s2,32(sp)
    80001066:	ec4e                	sd	s3,24(sp)
    80001068:	e852                	sd	s4,16(sp)
    8000106a:	e456                	sd	s5,8(sp)
    8000106c:	e05a                	sd	s6,0(sp)
    8000106e:	0080                	addi	s0,sp,64
    80001070:	84aa                	mv	s1,a0
    80001072:	89ae                	mv	s3,a1
    80001074:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000107c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000107e:	04b7f263          	bgeu	a5,a1,800010c2 <walk+0x66>
    panic("walk");
    80001082:	00007517          	auipc	a0,0x7
    80001086:	05650513          	addi	a0,a0,86 # 800080d8 <digits+0x90>
    8000108a:	fffff097          	auipc	ra,0xfffff
    8000108e:	54c080e7          	jalr	1356(ra) # 800005d6 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001092:	060a8663          	beqz	s5,800010fe <walk+0xa2>
    80001096:	00000097          	auipc	ra,0x0
    8000109a:	aee080e7          	jalr	-1298(ra) # 80000b84 <kalloc>
    8000109e:	84aa                	mv	s1,a0
    800010a0:	c529                	beqz	a0,800010ea <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010a2:	6605                	lui	a2,0x1
    800010a4:	4581                	li	a1,0
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	cca080e7          	jalr	-822(ra) # 80000d70 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010ae:	00c4d793          	srli	a5,s1,0xc
    800010b2:	07aa                	slli	a5,a5,0xa
    800010b4:	0017e793          	ori	a5,a5,1
    800010b8:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010bc:	3a5d                	addiw	s4,s4,-9
    800010be:	036a0063          	beq	s4,s6,800010de <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010c2:	0149d933          	srl	s2,s3,s4
    800010c6:	1ff97913          	andi	s2,s2,511
    800010ca:	090e                	slli	s2,s2,0x3
    800010cc:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010ce:	00093483          	ld	s1,0(s2)
    800010d2:	0014f793          	andi	a5,s1,1
    800010d6:	dfd5                	beqz	a5,80001092 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010d8:	80a9                	srli	s1,s1,0xa
    800010da:	04b2                	slli	s1,s1,0xc
    800010dc:	b7c5                	j	800010bc <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010de:	00c9d513          	srli	a0,s3,0xc
    800010e2:	1ff57513          	andi	a0,a0,511
    800010e6:	050e                	slli	a0,a0,0x3
    800010e8:	9526                	add	a0,a0,s1
}
    800010ea:	70e2                	ld	ra,56(sp)
    800010ec:	7442                	ld	s0,48(sp)
    800010ee:	74a2                	ld	s1,40(sp)
    800010f0:	7902                	ld	s2,32(sp)
    800010f2:	69e2                	ld	s3,24(sp)
    800010f4:	6a42                	ld	s4,16(sp)
    800010f6:	6aa2                	ld	s5,8(sp)
    800010f8:	6b02                	ld	s6,0(sp)
    800010fa:	6121                	addi	sp,sp,64
    800010fc:	8082                	ret
        return 0;
    800010fe:	4501                	li	a0,0
    80001100:	b7ed                	j	800010ea <walk+0x8e>

0000000080001102 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001102:	57fd                	li	a5,-1
    80001104:	83e9                	srli	a5,a5,0x1a
    80001106:	00b7f463          	bgeu	a5,a1,8000110e <walkaddr+0xc>
    return 0;
    8000110a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000110c:	8082                	ret
{
    8000110e:	1141                	addi	sp,sp,-16
    80001110:	e406                	sd	ra,8(sp)
    80001112:	e022                	sd	s0,0(sp)
    80001114:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001116:	4601                	li	a2,0
    80001118:	00000097          	auipc	ra,0x0
    8000111c:	f44080e7          	jalr	-188(ra) # 8000105c <walk>
  if(pte == 0)
    80001120:	c105                	beqz	a0,80001140 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001122:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001124:	0117f693          	andi	a3,a5,17
    80001128:	4745                	li	a4,17
    return 0;
    8000112a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000112c:	00e68663          	beq	a3,a4,80001138 <walkaddr+0x36>
}
    80001130:	60a2                	ld	ra,8(sp)
    80001132:	6402                	ld	s0,0(sp)
    80001134:	0141                	addi	sp,sp,16
    80001136:	8082                	ret
  pa = PTE2PA(*pte);
    80001138:	00a7d513          	srli	a0,a5,0xa
    8000113c:	0532                	slli	a0,a0,0xc
  return pa;
    8000113e:	bfcd                	j	80001130 <walkaddr+0x2e>
    return 0;
    80001140:	4501                	li	a0,0
    80001142:	b7fd                	j	80001130 <walkaddr+0x2e>

0000000080001144 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001144:	1101                	addi	sp,sp,-32
    80001146:	ec06                	sd	ra,24(sp)
    80001148:	e822                	sd	s0,16(sp)
    8000114a:	e426                	sd	s1,8(sp)
    8000114c:	1000                	addi	s0,sp,32
    8000114e:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001150:	1552                	slli	a0,a0,0x34
    80001152:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001156:	4601                	li	a2,0
    80001158:	00008517          	auipc	a0,0x8
    8000115c:	eb853503          	ld	a0,-328(a0) # 80009010 <kernel_pagetable>
    80001160:	00000097          	auipc	ra,0x0
    80001164:	efc080e7          	jalr	-260(ra) # 8000105c <walk>
  if(pte == 0)
    80001168:	cd09                	beqz	a0,80001182 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000116a:	6108                	ld	a0,0(a0)
    8000116c:	00157793          	andi	a5,a0,1
    80001170:	c38d                	beqz	a5,80001192 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001172:	8129                	srli	a0,a0,0xa
    80001174:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001176:	9526                	add	a0,a0,s1
    80001178:	60e2                	ld	ra,24(sp)
    8000117a:	6442                	ld	s0,16(sp)
    8000117c:	64a2                	ld	s1,8(sp)
    8000117e:	6105                	addi	sp,sp,32
    80001180:	8082                	ret
    panic("kvmpa");
    80001182:	00007517          	auipc	a0,0x7
    80001186:	f5e50513          	addi	a0,a0,-162 # 800080e0 <digits+0x98>
    8000118a:	fffff097          	auipc	ra,0xfffff
    8000118e:	44c080e7          	jalr	1100(ra) # 800005d6 <panic>
    panic("kvmpa");
    80001192:	00007517          	auipc	a0,0x7
    80001196:	f4e50513          	addi	a0,a0,-178 # 800080e0 <digits+0x98>
    8000119a:	fffff097          	auipc	ra,0xfffff
    8000119e:	43c080e7          	jalr	1084(ra) # 800005d6 <panic>

00000000800011a2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011a2:	715d                	addi	sp,sp,-80
    800011a4:	e486                	sd	ra,72(sp)
    800011a6:	e0a2                	sd	s0,64(sp)
    800011a8:	fc26                	sd	s1,56(sp)
    800011aa:	f84a                	sd	s2,48(sp)
    800011ac:	f44e                	sd	s3,40(sp)
    800011ae:	f052                	sd	s4,32(sp)
    800011b0:	ec56                	sd	s5,24(sp)
    800011b2:	e85a                	sd	s6,16(sp)
    800011b4:	e45e                	sd	s7,8(sp)
    800011b6:	0880                	addi	s0,sp,80
    800011b8:	8aaa                	mv	s5,a0
    800011ba:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011bc:	777d                	lui	a4,0xfffff
    800011be:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011c2:	167d                	addi	a2,a2,-1
    800011c4:	00b609b3          	add	s3,a2,a1
    800011c8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011cc:	893e                	mv	s2,a5
    800011ce:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011d2:	6b85                	lui	s7,0x1
    800011d4:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011d8:	4605                	li	a2,1
    800011da:	85ca                	mv	a1,s2
    800011dc:	8556                	mv	a0,s5
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	e7e080e7          	jalr	-386(ra) # 8000105c <walk>
    800011e6:	c51d                	beqz	a0,80001214 <mappages+0x72>
    if(*pte & PTE_V)
    800011e8:	611c                	ld	a5,0(a0)
    800011ea:	8b85                	andi	a5,a5,1
    800011ec:	ef81                	bnez	a5,80001204 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011ee:	80b1                	srli	s1,s1,0xc
    800011f0:	04aa                	slli	s1,s1,0xa
    800011f2:	0164e4b3          	or	s1,s1,s6
    800011f6:	0014e493          	ori	s1,s1,1
    800011fa:	e104                	sd	s1,0(a0)
    if(a == last)
    800011fc:	03390863          	beq	s2,s3,8000122c <mappages+0x8a>
    a += PGSIZE;
    80001200:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001202:	bfc9                	j	800011d4 <mappages+0x32>
      panic("remap");
    80001204:	00007517          	auipc	a0,0x7
    80001208:	ee450513          	addi	a0,a0,-284 # 800080e8 <digits+0xa0>
    8000120c:	fffff097          	auipc	ra,0xfffff
    80001210:	3ca080e7          	jalr	970(ra) # 800005d6 <panic>
      return -1;
    80001214:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001216:	60a6                	ld	ra,72(sp)
    80001218:	6406                	ld	s0,64(sp)
    8000121a:	74e2                	ld	s1,56(sp)
    8000121c:	7942                	ld	s2,48(sp)
    8000121e:	79a2                	ld	s3,40(sp)
    80001220:	7a02                	ld	s4,32(sp)
    80001222:	6ae2                	ld	s5,24(sp)
    80001224:	6b42                	ld	s6,16(sp)
    80001226:	6ba2                	ld	s7,8(sp)
    80001228:	6161                	addi	sp,sp,80
    8000122a:	8082                	ret
  return 0;
    8000122c:	4501                	li	a0,0
    8000122e:	b7e5                	j	80001216 <mappages+0x74>

0000000080001230 <kvmmap>:
{
    80001230:	1141                	addi	sp,sp,-16
    80001232:	e406                	sd	ra,8(sp)
    80001234:	e022                	sd	s0,0(sp)
    80001236:	0800                	addi	s0,sp,16
    80001238:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000123a:	86ae                	mv	a3,a1
    8000123c:	85aa                	mv	a1,a0
    8000123e:	00008517          	auipc	a0,0x8
    80001242:	dd253503          	ld	a0,-558(a0) # 80009010 <kernel_pagetable>
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f5c080e7          	jalr	-164(ra) # 800011a2 <mappages>
    8000124e:	e509                	bnez	a0,80001258 <kvmmap+0x28>
}
    80001250:	60a2                	ld	ra,8(sp)
    80001252:	6402                	ld	s0,0(sp)
    80001254:	0141                	addi	sp,sp,16
    80001256:	8082                	ret
    panic("kvmmap");
    80001258:	00007517          	auipc	a0,0x7
    8000125c:	e9850513          	addi	a0,a0,-360 # 800080f0 <digits+0xa8>
    80001260:	fffff097          	auipc	ra,0xfffff
    80001264:	376080e7          	jalr	886(ra) # 800005d6 <panic>

0000000080001268 <kvminit>:
{
    80001268:	1101                	addi	sp,sp,-32
    8000126a:	ec06                	sd	ra,24(sp)
    8000126c:	e822                	sd	s0,16(sp)
    8000126e:	e426                	sd	s1,8(sp)
    80001270:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001272:	00000097          	auipc	ra,0x0
    80001276:	912080e7          	jalr	-1774(ra) # 80000b84 <kalloc>
    8000127a:	00008797          	auipc	a5,0x8
    8000127e:	d8a7bb23          	sd	a0,-618(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001282:	6605                	lui	a2,0x1
    80001284:	4581                	li	a1,0
    80001286:	00000097          	auipc	ra,0x0
    8000128a:	aea080e7          	jalr	-1302(ra) # 80000d70 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000128e:	4699                	li	a3,6
    80001290:	6605                	lui	a2,0x1
    80001292:	100005b7          	lui	a1,0x10000
    80001296:	10000537          	lui	a0,0x10000
    8000129a:	00000097          	auipc	ra,0x0
    8000129e:	f96080e7          	jalr	-106(ra) # 80001230 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012a2:	4699                	li	a3,6
    800012a4:	6605                	lui	a2,0x1
    800012a6:	100015b7          	lui	a1,0x10001
    800012aa:	10001537          	lui	a0,0x10001
    800012ae:	00000097          	auipc	ra,0x0
    800012b2:	f82080e7          	jalr	-126(ra) # 80001230 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012b6:	4699                	li	a3,6
    800012b8:	6641                	lui	a2,0x10
    800012ba:	020005b7          	lui	a1,0x2000
    800012be:	02000537          	lui	a0,0x2000
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	f6e080e7          	jalr	-146(ra) # 80001230 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ca:	4699                	li	a3,6
    800012cc:	00400637          	lui	a2,0x400
    800012d0:	0c0005b7          	lui	a1,0xc000
    800012d4:	0c000537          	lui	a0,0xc000
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	f58080e7          	jalr	-168(ra) # 80001230 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012e0:	00007497          	auipc	s1,0x7
    800012e4:	d2048493          	addi	s1,s1,-736 # 80008000 <etext>
    800012e8:	46a9                	li	a3,10
    800012ea:	80007617          	auipc	a2,0x80007
    800012ee:	d1660613          	addi	a2,a2,-746 # 8000 <_entry-0x7fff8000>
    800012f2:	4585                	li	a1,1
    800012f4:	05fe                	slli	a1,a1,0x1f
    800012f6:	852e                	mv	a0,a1
    800012f8:	00000097          	auipc	ra,0x0
    800012fc:	f38080e7          	jalr	-200(ra) # 80001230 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001300:	4699                	li	a3,6
    80001302:	4645                	li	a2,17
    80001304:	066e                	slli	a2,a2,0x1b
    80001306:	8e05                	sub	a2,a2,s1
    80001308:	85a6                	mv	a1,s1
    8000130a:	8526                	mv	a0,s1
    8000130c:	00000097          	auipc	ra,0x0
    80001310:	f24080e7          	jalr	-220(ra) # 80001230 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001314:	46a9                	li	a3,10
    80001316:	6605                	lui	a2,0x1
    80001318:	00006597          	auipc	a1,0x6
    8000131c:	ce858593          	addi	a1,a1,-792 # 80007000 <_trampoline>
    80001320:	04000537          	lui	a0,0x4000
    80001324:	157d                	addi	a0,a0,-1
    80001326:	0532                	slli	a0,a0,0xc
    80001328:	00000097          	auipc	ra,0x0
    8000132c:	f08080e7          	jalr	-248(ra) # 80001230 <kvmmap>
}
    80001330:	60e2                	ld	ra,24(sp)
    80001332:	6442                	ld	s0,16(sp)
    80001334:	64a2                	ld	s1,8(sp)
    80001336:	6105                	addi	sp,sp,32
    80001338:	8082                	ret

000000008000133a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000133a:	715d                	addi	sp,sp,-80
    8000133c:	e486                	sd	ra,72(sp)
    8000133e:	e0a2                	sd	s0,64(sp)
    80001340:	fc26                	sd	s1,56(sp)
    80001342:	f84a                	sd	s2,48(sp)
    80001344:	f44e                	sd	s3,40(sp)
    80001346:	f052                	sd	s4,32(sp)
    80001348:	ec56                	sd	s5,24(sp)
    8000134a:	e85a                	sd	s6,16(sp)
    8000134c:	e45e                	sd	s7,8(sp)
    8000134e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001350:	03459793          	slli	a5,a1,0x34
    80001354:	e795                	bnez	a5,80001380 <uvmunmap+0x46>
    80001356:	8a2a                	mv	s4,a0
    80001358:	892e                	mv	s2,a1
    8000135a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000135c:	0632                	slli	a2,a2,0xc
    8000135e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001362:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001364:	6b05                	lui	s6,0x1
    80001366:	0735e863          	bltu	a1,s3,800013d6 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000136a:	60a6                	ld	ra,72(sp)
    8000136c:	6406                	ld	s0,64(sp)
    8000136e:	74e2                	ld	s1,56(sp)
    80001370:	7942                	ld	s2,48(sp)
    80001372:	79a2                	ld	s3,40(sp)
    80001374:	7a02                	ld	s4,32(sp)
    80001376:	6ae2                	ld	s5,24(sp)
    80001378:	6b42                	ld	s6,16(sp)
    8000137a:	6ba2                	ld	s7,8(sp)
    8000137c:	6161                	addi	sp,sp,80
    8000137e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001380:	00007517          	auipc	a0,0x7
    80001384:	d7850513          	addi	a0,a0,-648 # 800080f8 <digits+0xb0>
    80001388:	fffff097          	auipc	ra,0xfffff
    8000138c:	24e080e7          	jalr	590(ra) # 800005d6 <panic>
      panic("uvmunmap: walk");
    80001390:	00007517          	auipc	a0,0x7
    80001394:	d8050513          	addi	a0,a0,-640 # 80008110 <digits+0xc8>
    80001398:	fffff097          	auipc	ra,0xfffff
    8000139c:	23e080e7          	jalr	574(ra) # 800005d6 <panic>
      panic("uvmunmap: not mapped");
    800013a0:	00007517          	auipc	a0,0x7
    800013a4:	d8050513          	addi	a0,a0,-640 # 80008120 <digits+0xd8>
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	22e080e7          	jalr	558(ra) # 800005d6 <panic>
      panic("uvmunmap: not a leaf");
    800013b0:	00007517          	auipc	a0,0x7
    800013b4:	d8850513          	addi	a0,a0,-632 # 80008138 <digits+0xf0>
    800013b8:	fffff097          	auipc	ra,0xfffff
    800013bc:	21e080e7          	jalr	542(ra) # 800005d6 <panic>
      uint64 pa = PTE2PA(*pte);
    800013c0:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013c2:	0532                	slli	a0,a0,0xc
    800013c4:	fffff097          	auipc	ra,0xfffff
    800013c8:	6c4080e7          	jalr	1732(ra) # 80000a88 <kfree>
    *pte = 0;
    800013cc:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d0:	995a                	add	s2,s2,s6
    800013d2:	f9397ce3          	bgeu	s2,s3,8000136a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013d6:	4601                	li	a2,0
    800013d8:	85ca                	mv	a1,s2
    800013da:	8552                	mv	a0,s4
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	c80080e7          	jalr	-896(ra) # 8000105c <walk>
    800013e4:	84aa                	mv	s1,a0
    800013e6:	d54d                	beqz	a0,80001390 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013e8:	6108                	ld	a0,0(a0)
    800013ea:	00157793          	andi	a5,a0,1
    800013ee:	dbcd                	beqz	a5,800013a0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013f0:	3ff57793          	andi	a5,a0,1023
    800013f4:	fb778ee3          	beq	a5,s7,800013b0 <uvmunmap+0x76>
    if(do_free){
    800013f8:	fc0a8ae3          	beqz	s5,800013cc <uvmunmap+0x92>
    800013fc:	b7d1                	j	800013c0 <uvmunmap+0x86>

00000000800013fe <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013fe:	1101                	addi	sp,sp,-32
    80001400:	ec06                	sd	ra,24(sp)
    80001402:	e822                	sd	s0,16(sp)
    80001404:	e426                	sd	s1,8(sp)
    80001406:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001408:	fffff097          	auipc	ra,0xfffff
    8000140c:	77c080e7          	jalr	1916(ra) # 80000b84 <kalloc>
    80001410:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001412:	c519                	beqz	a0,80001420 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001414:	6605                	lui	a2,0x1
    80001416:	4581                	li	a1,0
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	958080e7          	jalr	-1704(ra) # 80000d70 <memset>
  return pagetable;
}
    80001420:	8526                	mv	a0,s1
    80001422:	60e2                	ld	ra,24(sp)
    80001424:	6442                	ld	s0,16(sp)
    80001426:	64a2                	ld	s1,8(sp)
    80001428:	6105                	addi	sp,sp,32
    8000142a:	8082                	ret

000000008000142c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000142c:	7179                	addi	sp,sp,-48
    8000142e:	f406                	sd	ra,40(sp)
    80001430:	f022                	sd	s0,32(sp)
    80001432:	ec26                	sd	s1,24(sp)
    80001434:	e84a                	sd	s2,16(sp)
    80001436:	e44e                	sd	s3,8(sp)
    80001438:	e052                	sd	s4,0(sp)
    8000143a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000143c:	6785                	lui	a5,0x1
    8000143e:	04f67863          	bgeu	a2,a5,8000148e <uvminit+0x62>
    80001442:	8a2a                	mv	s4,a0
    80001444:	89ae                	mv	s3,a1
    80001446:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001448:	fffff097          	auipc	ra,0xfffff
    8000144c:	73c080e7          	jalr	1852(ra) # 80000b84 <kalloc>
    80001450:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001452:	6605                	lui	a2,0x1
    80001454:	4581                	li	a1,0
    80001456:	00000097          	auipc	ra,0x0
    8000145a:	91a080e7          	jalr	-1766(ra) # 80000d70 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000145e:	4779                	li	a4,30
    80001460:	86ca                	mv	a3,s2
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	8552                	mv	a0,s4
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	d3a080e7          	jalr	-710(ra) # 800011a2 <mappages>
  memmove(mem, src, sz);
    80001470:	8626                	mv	a2,s1
    80001472:	85ce                	mv	a1,s3
    80001474:	854a                	mv	a0,s2
    80001476:	00000097          	auipc	ra,0x0
    8000147a:	95a080e7          	jalr	-1702(ra) # 80000dd0 <memmove>
}
    8000147e:	70a2                	ld	ra,40(sp)
    80001480:	7402                	ld	s0,32(sp)
    80001482:	64e2                	ld	s1,24(sp)
    80001484:	6942                	ld	s2,16(sp)
    80001486:	69a2                	ld	s3,8(sp)
    80001488:	6a02                	ld	s4,0(sp)
    8000148a:	6145                	addi	sp,sp,48
    8000148c:	8082                	ret
    panic("inituvm: more than a page");
    8000148e:	00007517          	auipc	a0,0x7
    80001492:	cc250513          	addi	a0,a0,-830 # 80008150 <digits+0x108>
    80001496:	fffff097          	auipc	ra,0xfffff
    8000149a:	140080e7          	jalr	320(ra) # 800005d6 <panic>

000000008000149e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000149e:	1101                	addi	sp,sp,-32
    800014a0:	ec06                	sd	ra,24(sp)
    800014a2:	e822                	sd	s0,16(sp)
    800014a4:	e426                	sd	s1,8(sp)
    800014a6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014a8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014aa:	00b67d63          	bgeu	a2,a1,800014c4 <uvmdealloc+0x26>
    800014ae:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014b0:	6785                	lui	a5,0x1
    800014b2:	17fd                	addi	a5,a5,-1
    800014b4:	00f60733          	add	a4,a2,a5
    800014b8:	767d                	lui	a2,0xfffff
    800014ba:	8f71                	and	a4,a4,a2
    800014bc:	97ae                	add	a5,a5,a1
    800014be:	8ff1                	and	a5,a5,a2
    800014c0:	00f76863          	bltu	a4,a5,800014d0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014c4:	8526                	mv	a0,s1
    800014c6:	60e2                	ld	ra,24(sp)
    800014c8:	6442                	ld	s0,16(sp)
    800014ca:	64a2                	ld	s1,8(sp)
    800014cc:	6105                	addi	sp,sp,32
    800014ce:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014d0:	8f99                	sub	a5,a5,a4
    800014d2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014d4:	4685                	li	a3,1
    800014d6:	0007861b          	sext.w	a2,a5
    800014da:	85ba                	mv	a1,a4
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	e5e080e7          	jalr	-418(ra) # 8000133a <uvmunmap>
    800014e4:	b7c5                	j	800014c4 <uvmdealloc+0x26>

00000000800014e6 <uvmalloc>:
  if(newsz < oldsz)
    800014e6:	0ab66163          	bltu	a2,a1,80001588 <uvmalloc+0xa2>
{
    800014ea:	7139                	addi	sp,sp,-64
    800014ec:	fc06                	sd	ra,56(sp)
    800014ee:	f822                	sd	s0,48(sp)
    800014f0:	f426                	sd	s1,40(sp)
    800014f2:	f04a                	sd	s2,32(sp)
    800014f4:	ec4e                	sd	s3,24(sp)
    800014f6:	e852                	sd	s4,16(sp)
    800014f8:	e456                	sd	s5,8(sp)
    800014fa:	0080                	addi	s0,sp,64
    800014fc:	8aaa                	mv	s5,a0
    800014fe:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001500:	6985                	lui	s3,0x1
    80001502:	19fd                	addi	s3,s3,-1
    80001504:	95ce                	add	a1,a1,s3
    80001506:	79fd                	lui	s3,0xfffff
    80001508:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000150c:	08c9f063          	bgeu	s3,a2,8000158c <uvmalloc+0xa6>
    80001510:	894e                	mv	s2,s3
    mem = kalloc();
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	672080e7          	jalr	1650(ra) # 80000b84 <kalloc>
    8000151a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000151c:	c51d                	beqz	a0,8000154a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000151e:	6605                	lui	a2,0x1
    80001520:	4581                	li	a1,0
    80001522:	00000097          	auipc	ra,0x0
    80001526:	84e080e7          	jalr	-1970(ra) # 80000d70 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000152a:	4779                	li	a4,30
    8000152c:	86a6                	mv	a3,s1
    8000152e:	6605                	lui	a2,0x1
    80001530:	85ca                	mv	a1,s2
    80001532:	8556                	mv	a0,s5
    80001534:	00000097          	auipc	ra,0x0
    80001538:	c6e080e7          	jalr	-914(ra) # 800011a2 <mappages>
    8000153c:	e905                	bnez	a0,8000156c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000153e:	6785                	lui	a5,0x1
    80001540:	993e                	add	s2,s2,a5
    80001542:	fd4968e3          	bltu	s2,s4,80001512 <uvmalloc+0x2c>
  return newsz;
    80001546:	8552                	mv	a0,s4
    80001548:	a809                	j	8000155a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000154a:	864e                	mv	a2,s3
    8000154c:	85ca                	mv	a1,s2
    8000154e:	8556                	mv	a0,s5
    80001550:	00000097          	auipc	ra,0x0
    80001554:	f4e080e7          	jalr	-178(ra) # 8000149e <uvmdealloc>
      return 0;
    80001558:	4501                	li	a0,0
}
    8000155a:	70e2                	ld	ra,56(sp)
    8000155c:	7442                	ld	s0,48(sp)
    8000155e:	74a2                	ld	s1,40(sp)
    80001560:	7902                	ld	s2,32(sp)
    80001562:	69e2                	ld	s3,24(sp)
    80001564:	6a42                	ld	s4,16(sp)
    80001566:	6aa2                	ld	s5,8(sp)
    80001568:	6121                	addi	sp,sp,64
    8000156a:	8082                	ret
      kfree(mem);
    8000156c:	8526                	mv	a0,s1
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	51a080e7          	jalr	1306(ra) # 80000a88 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001576:	864e                	mv	a2,s3
    80001578:	85ca                	mv	a1,s2
    8000157a:	8556                	mv	a0,s5
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	f22080e7          	jalr	-222(ra) # 8000149e <uvmdealloc>
      return 0;
    80001584:	4501                	li	a0,0
    80001586:	bfd1                	j	8000155a <uvmalloc+0x74>
    return oldsz;
    80001588:	852e                	mv	a0,a1
}
    8000158a:	8082                	ret
  return newsz;
    8000158c:	8532                	mv	a0,a2
    8000158e:	b7f1                	j	8000155a <uvmalloc+0x74>

0000000080001590 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001590:	7179                	addi	sp,sp,-48
    80001592:	f406                	sd	ra,40(sp)
    80001594:	f022                	sd	s0,32(sp)
    80001596:	ec26                	sd	s1,24(sp)
    80001598:	e84a                	sd	s2,16(sp)
    8000159a:	e44e                	sd	s3,8(sp)
    8000159c:	e052                	sd	s4,0(sp)
    8000159e:	1800                	addi	s0,sp,48
    800015a0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015a2:	84aa                	mv	s1,a0
    800015a4:	6905                	lui	s2,0x1
    800015a6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a8:	4985                	li	s3,1
    800015aa:	a821                	j	800015c2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015ac:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015ae:	0532                	slli	a0,a0,0xc
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	fe0080e7          	jalr	-32(ra) # 80001590 <freewalk>
      pagetable[i] = 0;
    800015b8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015bc:	04a1                	addi	s1,s1,8
    800015be:	03248163          	beq	s1,s2,800015e0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015c2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015c4:	00f57793          	andi	a5,a0,15
    800015c8:	ff3782e3          	beq	a5,s3,800015ac <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015cc:	8905                	andi	a0,a0,1
    800015ce:	d57d                	beqz	a0,800015bc <freewalk+0x2c>
      panic("freewalk: leaf");
    800015d0:	00007517          	auipc	a0,0x7
    800015d4:	ba050513          	addi	a0,a0,-1120 # 80008170 <digits+0x128>
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	ffe080e7          	jalr	-2(ra) # 800005d6 <panic>
    }
  }
  kfree((void*)pagetable);
    800015e0:	8552                	mv	a0,s4
    800015e2:	fffff097          	auipc	ra,0xfffff
    800015e6:	4a6080e7          	jalr	1190(ra) # 80000a88 <kfree>
}
    800015ea:	70a2                	ld	ra,40(sp)
    800015ec:	7402                	ld	s0,32(sp)
    800015ee:	64e2                	ld	s1,24(sp)
    800015f0:	6942                	ld	s2,16(sp)
    800015f2:	69a2                	ld	s3,8(sp)
    800015f4:	6a02                	ld	s4,0(sp)
    800015f6:	6145                	addi	sp,sp,48
    800015f8:	8082                	ret

00000000800015fa <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015fa:	1101                	addi	sp,sp,-32
    800015fc:	ec06                	sd	ra,24(sp)
    800015fe:	e822                	sd	s0,16(sp)
    80001600:	e426                	sd	s1,8(sp)
    80001602:	1000                	addi	s0,sp,32
    80001604:	84aa                	mv	s1,a0
  if(sz > 0)
    80001606:	e999                	bnez	a1,8000161c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001608:	8526                	mv	a0,s1
    8000160a:	00000097          	auipc	ra,0x0
    8000160e:	f86080e7          	jalr	-122(ra) # 80001590 <freewalk>
}
    80001612:	60e2                	ld	ra,24(sp)
    80001614:	6442                	ld	s0,16(sp)
    80001616:	64a2                	ld	s1,8(sp)
    80001618:	6105                	addi	sp,sp,32
    8000161a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000161c:	6605                	lui	a2,0x1
    8000161e:	167d                	addi	a2,a2,-1
    80001620:	962e                	add	a2,a2,a1
    80001622:	4685                	li	a3,1
    80001624:	8231                	srli	a2,a2,0xc
    80001626:	4581                	li	a1,0
    80001628:	00000097          	auipc	ra,0x0
    8000162c:	d12080e7          	jalr	-750(ra) # 8000133a <uvmunmap>
    80001630:	bfe1                	j	80001608 <uvmfree+0xe>

0000000080001632 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001632:	c679                	beqz	a2,80001700 <uvmcopy+0xce>
{
    80001634:	715d                	addi	sp,sp,-80
    80001636:	e486                	sd	ra,72(sp)
    80001638:	e0a2                	sd	s0,64(sp)
    8000163a:	fc26                	sd	s1,56(sp)
    8000163c:	f84a                	sd	s2,48(sp)
    8000163e:	f44e                	sd	s3,40(sp)
    80001640:	f052                	sd	s4,32(sp)
    80001642:	ec56                	sd	s5,24(sp)
    80001644:	e85a                	sd	s6,16(sp)
    80001646:	e45e                	sd	s7,8(sp)
    80001648:	0880                	addi	s0,sp,80
    8000164a:	8b2a                	mv	s6,a0
    8000164c:	8aae                	mv	s5,a1
    8000164e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001652:	4601                	li	a2,0
    80001654:	85ce                	mv	a1,s3
    80001656:	855a                	mv	a0,s6
    80001658:	00000097          	auipc	ra,0x0
    8000165c:	a04080e7          	jalr	-1532(ra) # 8000105c <walk>
    80001660:	c531                	beqz	a0,800016ac <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001662:	6118                	ld	a4,0(a0)
    80001664:	00177793          	andi	a5,a4,1
    80001668:	cbb1                	beqz	a5,800016bc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000166a:	00a75593          	srli	a1,a4,0xa
    8000166e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001672:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001676:	fffff097          	auipc	ra,0xfffff
    8000167a:	50e080e7          	jalr	1294(ra) # 80000b84 <kalloc>
    8000167e:	892a                	mv	s2,a0
    80001680:	c939                	beqz	a0,800016d6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001682:	6605                	lui	a2,0x1
    80001684:	85de                	mv	a1,s7
    80001686:	fffff097          	auipc	ra,0xfffff
    8000168a:	74a080e7          	jalr	1866(ra) # 80000dd0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000168e:	8726                	mv	a4,s1
    80001690:	86ca                	mv	a3,s2
    80001692:	6605                	lui	a2,0x1
    80001694:	85ce                	mv	a1,s3
    80001696:	8556                	mv	a0,s5
    80001698:	00000097          	auipc	ra,0x0
    8000169c:	b0a080e7          	jalr	-1270(ra) # 800011a2 <mappages>
    800016a0:	e515                	bnez	a0,800016cc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016a2:	6785                	lui	a5,0x1
    800016a4:	99be                	add	s3,s3,a5
    800016a6:	fb49e6e3          	bltu	s3,s4,80001652 <uvmcopy+0x20>
    800016aa:	a081                	j	800016ea <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016ac:	00007517          	auipc	a0,0x7
    800016b0:	ad450513          	addi	a0,a0,-1324 # 80008180 <digits+0x138>
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	f22080e7          	jalr	-222(ra) # 800005d6 <panic>
      panic("uvmcopy: page not present");
    800016bc:	00007517          	auipc	a0,0x7
    800016c0:	ae450513          	addi	a0,a0,-1308 # 800081a0 <digits+0x158>
    800016c4:	fffff097          	auipc	ra,0xfffff
    800016c8:	f12080e7          	jalr	-238(ra) # 800005d6 <panic>
      kfree(mem);
    800016cc:	854a                	mv	a0,s2
    800016ce:	fffff097          	auipc	ra,0xfffff
    800016d2:	3ba080e7          	jalr	954(ra) # 80000a88 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016d6:	4685                	li	a3,1
    800016d8:	00c9d613          	srli	a2,s3,0xc
    800016dc:	4581                	li	a1,0
    800016de:	8556                	mv	a0,s5
    800016e0:	00000097          	auipc	ra,0x0
    800016e4:	c5a080e7          	jalr	-934(ra) # 8000133a <uvmunmap>
  return -1;
    800016e8:	557d                	li	a0,-1
}
    800016ea:	60a6                	ld	ra,72(sp)
    800016ec:	6406                	ld	s0,64(sp)
    800016ee:	74e2                	ld	s1,56(sp)
    800016f0:	7942                	ld	s2,48(sp)
    800016f2:	79a2                	ld	s3,40(sp)
    800016f4:	7a02                	ld	s4,32(sp)
    800016f6:	6ae2                	ld	s5,24(sp)
    800016f8:	6b42                	ld	s6,16(sp)
    800016fa:	6ba2                	ld	s7,8(sp)
    800016fc:	6161                	addi	sp,sp,80
    800016fe:	8082                	ret
  return 0;
    80001700:	4501                	li	a0,0
}
    80001702:	8082                	ret

0000000080001704 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001704:	1141                	addi	sp,sp,-16
    80001706:	e406                	sd	ra,8(sp)
    80001708:	e022                	sd	s0,0(sp)
    8000170a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000170c:	4601                	li	a2,0
    8000170e:	00000097          	auipc	ra,0x0
    80001712:	94e080e7          	jalr	-1714(ra) # 8000105c <walk>
  if(pte == 0)
    80001716:	c901                	beqz	a0,80001726 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001718:	611c                	ld	a5,0(a0)
    8000171a:	9bbd                	andi	a5,a5,-17
    8000171c:	e11c                	sd	a5,0(a0)
}
    8000171e:	60a2                	ld	ra,8(sp)
    80001720:	6402                	ld	s0,0(sp)
    80001722:	0141                	addi	sp,sp,16
    80001724:	8082                	ret
    panic("uvmclear");
    80001726:	00007517          	auipc	a0,0x7
    8000172a:	a9a50513          	addi	a0,a0,-1382 # 800081c0 <digits+0x178>
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	ea8080e7          	jalr	-344(ra) # 800005d6 <panic>

0000000080001736 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001736:	c6bd                	beqz	a3,800017a4 <copyout+0x6e>
{
    80001738:	715d                	addi	sp,sp,-80
    8000173a:	e486                	sd	ra,72(sp)
    8000173c:	e0a2                	sd	s0,64(sp)
    8000173e:	fc26                	sd	s1,56(sp)
    80001740:	f84a                	sd	s2,48(sp)
    80001742:	f44e                	sd	s3,40(sp)
    80001744:	f052                	sd	s4,32(sp)
    80001746:	ec56                	sd	s5,24(sp)
    80001748:	e85a                	sd	s6,16(sp)
    8000174a:	e45e                	sd	s7,8(sp)
    8000174c:	e062                	sd	s8,0(sp)
    8000174e:	0880                	addi	s0,sp,80
    80001750:	8b2a                	mv	s6,a0
    80001752:	8c2e                	mv	s8,a1
    80001754:	8a32                	mv	s4,a2
    80001756:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001758:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000175a:	6a85                	lui	s5,0x1
    8000175c:	a015                	j	80001780 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000175e:	9562                	add	a0,a0,s8
    80001760:	0004861b          	sext.w	a2,s1
    80001764:	85d2                	mv	a1,s4
    80001766:	41250533          	sub	a0,a0,s2
    8000176a:	fffff097          	auipc	ra,0xfffff
    8000176e:	666080e7          	jalr	1638(ra) # 80000dd0 <memmove>

    len -= n;
    80001772:	409989b3          	sub	s3,s3,s1
    src += n;
    80001776:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001778:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000177c:	02098263          	beqz	s3,800017a0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001780:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001784:	85ca                	mv	a1,s2
    80001786:	855a                	mv	a0,s6
    80001788:	00000097          	auipc	ra,0x0
    8000178c:	97a080e7          	jalr	-1670(ra) # 80001102 <walkaddr>
    if(pa0 == 0)
    80001790:	cd01                	beqz	a0,800017a8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001792:	418904b3          	sub	s1,s2,s8
    80001796:	94d6                	add	s1,s1,s5
    if(n > len)
    80001798:	fc99f3e3          	bgeu	s3,s1,8000175e <copyout+0x28>
    8000179c:	84ce                	mv	s1,s3
    8000179e:	b7c1                	j	8000175e <copyout+0x28>
  }
  return 0;
    800017a0:	4501                	li	a0,0
    800017a2:	a021                	j	800017aa <copyout+0x74>
    800017a4:	4501                	li	a0,0
}
    800017a6:	8082                	ret
      return -1;
    800017a8:	557d                	li	a0,-1
}
    800017aa:	60a6                	ld	ra,72(sp)
    800017ac:	6406                	ld	s0,64(sp)
    800017ae:	74e2                	ld	s1,56(sp)
    800017b0:	7942                	ld	s2,48(sp)
    800017b2:	79a2                	ld	s3,40(sp)
    800017b4:	7a02                	ld	s4,32(sp)
    800017b6:	6ae2                	ld	s5,24(sp)
    800017b8:	6b42                	ld	s6,16(sp)
    800017ba:	6ba2                	ld	s7,8(sp)
    800017bc:	6c02                	ld	s8,0(sp)
    800017be:	6161                	addi	sp,sp,80
    800017c0:	8082                	ret

00000000800017c2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017c2:	c6bd                	beqz	a3,80001830 <copyin+0x6e>
{
    800017c4:	715d                	addi	sp,sp,-80
    800017c6:	e486                	sd	ra,72(sp)
    800017c8:	e0a2                	sd	s0,64(sp)
    800017ca:	fc26                	sd	s1,56(sp)
    800017cc:	f84a                	sd	s2,48(sp)
    800017ce:	f44e                	sd	s3,40(sp)
    800017d0:	f052                	sd	s4,32(sp)
    800017d2:	ec56                	sd	s5,24(sp)
    800017d4:	e85a                	sd	s6,16(sp)
    800017d6:	e45e                	sd	s7,8(sp)
    800017d8:	e062                	sd	s8,0(sp)
    800017da:	0880                	addi	s0,sp,80
    800017dc:	8b2a                	mv	s6,a0
    800017de:	8a2e                	mv	s4,a1
    800017e0:	8c32                	mv	s8,a2
    800017e2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017e4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e6:	6a85                	lui	s5,0x1
    800017e8:	a015                	j	8000180c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017ea:	9562                	add	a0,a0,s8
    800017ec:	0004861b          	sext.w	a2,s1
    800017f0:	412505b3          	sub	a1,a0,s2
    800017f4:	8552                	mv	a0,s4
    800017f6:	fffff097          	auipc	ra,0xfffff
    800017fa:	5da080e7          	jalr	1498(ra) # 80000dd0 <memmove>

    len -= n;
    800017fe:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001802:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001804:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001808:	02098263          	beqz	s3,8000182c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000180c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001810:	85ca                	mv	a1,s2
    80001812:	855a                	mv	a0,s6
    80001814:	00000097          	auipc	ra,0x0
    80001818:	8ee080e7          	jalr	-1810(ra) # 80001102 <walkaddr>
    if(pa0 == 0)
    8000181c:	cd01                	beqz	a0,80001834 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000181e:	418904b3          	sub	s1,s2,s8
    80001822:	94d6                	add	s1,s1,s5
    if(n > len)
    80001824:	fc99f3e3          	bgeu	s3,s1,800017ea <copyin+0x28>
    80001828:	84ce                	mv	s1,s3
    8000182a:	b7c1                	j	800017ea <copyin+0x28>
  }
  return 0;
    8000182c:	4501                	li	a0,0
    8000182e:	a021                	j	80001836 <copyin+0x74>
    80001830:	4501                	li	a0,0
}
    80001832:	8082                	ret
      return -1;
    80001834:	557d                	li	a0,-1
}
    80001836:	60a6                	ld	ra,72(sp)
    80001838:	6406                	ld	s0,64(sp)
    8000183a:	74e2                	ld	s1,56(sp)
    8000183c:	7942                	ld	s2,48(sp)
    8000183e:	79a2                	ld	s3,40(sp)
    80001840:	7a02                	ld	s4,32(sp)
    80001842:	6ae2                	ld	s5,24(sp)
    80001844:	6b42                	ld	s6,16(sp)
    80001846:	6ba2                	ld	s7,8(sp)
    80001848:	6c02                	ld	s8,0(sp)
    8000184a:	6161                	addi	sp,sp,80
    8000184c:	8082                	ret

000000008000184e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000184e:	c6c5                	beqz	a3,800018f6 <copyinstr+0xa8>
{
    80001850:	715d                	addi	sp,sp,-80
    80001852:	e486                	sd	ra,72(sp)
    80001854:	e0a2                	sd	s0,64(sp)
    80001856:	fc26                	sd	s1,56(sp)
    80001858:	f84a                	sd	s2,48(sp)
    8000185a:	f44e                	sd	s3,40(sp)
    8000185c:	f052                	sd	s4,32(sp)
    8000185e:	ec56                	sd	s5,24(sp)
    80001860:	e85a                	sd	s6,16(sp)
    80001862:	e45e                	sd	s7,8(sp)
    80001864:	0880                	addi	s0,sp,80
    80001866:	8a2a                	mv	s4,a0
    80001868:	8b2e                	mv	s6,a1
    8000186a:	8bb2                	mv	s7,a2
    8000186c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000186e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001870:	6985                	lui	s3,0x1
    80001872:	a035                	j	8000189e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001874:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001878:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000187a:	0017b793          	seqz	a5,a5
    8000187e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001882:	60a6                	ld	ra,72(sp)
    80001884:	6406                	ld	s0,64(sp)
    80001886:	74e2                	ld	s1,56(sp)
    80001888:	7942                	ld	s2,48(sp)
    8000188a:	79a2                	ld	s3,40(sp)
    8000188c:	7a02                	ld	s4,32(sp)
    8000188e:	6ae2                	ld	s5,24(sp)
    80001890:	6b42                	ld	s6,16(sp)
    80001892:	6ba2                	ld	s7,8(sp)
    80001894:	6161                	addi	sp,sp,80
    80001896:	8082                	ret
    srcva = va0 + PGSIZE;
    80001898:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000189c:	c8a9                	beqz	s1,800018ee <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000189e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018a2:	85ca                	mv	a1,s2
    800018a4:	8552                	mv	a0,s4
    800018a6:	00000097          	auipc	ra,0x0
    800018aa:	85c080e7          	jalr	-1956(ra) # 80001102 <walkaddr>
    if(pa0 == 0)
    800018ae:	c131                	beqz	a0,800018f2 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018b0:	41790833          	sub	a6,s2,s7
    800018b4:	984e                	add	a6,a6,s3
    if(n > max)
    800018b6:	0104f363          	bgeu	s1,a6,800018bc <copyinstr+0x6e>
    800018ba:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018bc:	955e                	add	a0,a0,s7
    800018be:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018c2:	fc080be3          	beqz	a6,80001898 <copyinstr+0x4a>
    800018c6:	985a                	add	a6,a6,s6
    800018c8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018ca:	41650633          	sub	a2,a0,s6
    800018ce:	14fd                	addi	s1,s1,-1
    800018d0:	9b26                	add	s6,s6,s1
    800018d2:	00f60733          	add	a4,a2,a5
    800018d6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd4000>
    800018da:	df49                	beqz	a4,80001874 <copyinstr+0x26>
        *dst = *p;
    800018dc:	00e78023          	sb	a4,0(a5)
      --max;
    800018e0:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018e4:	0785                	addi	a5,a5,1
    while(n > 0){
    800018e6:	ff0796e3          	bne	a5,a6,800018d2 <copyinstr+0x84>
      dst++;
    800018ea:	8b42                	mv	s6,a6
    800018ec:	b775                	j	80001898 <copyinstr+0x4a>
    800018ee:	4781                	li	a5,0
    800018f0:	b769                	j	8000187a <copyinstr+0x2c>
      return -1;
    800018f2:	557d                	li	a0,-1
    800018f4:	b779                	j	80001882 <copyinstr+0x34>
  int got_null = 0;
    800018f6:	4781                	li	a5,0
  if(got_null){
    800018f8:	0017b793          	seqz	a5,a5
    800018fc:	40f00533          	neg	a0,a5
}
    80001900:	8082                	ret

0000000080001902 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001902:	1101                	addi	sp,sp,-32
    80001904:	ec06                	sd	ra,24(sp)
    80001906:	e822                	sd	s0,16(sp)
    80001908:	e426                	sd	s1,8(sp)
    8000190a:	1000                	addi	s0,sp,32
    8000190c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000190e:	fffff097          	auipc	ra,0xfffff
    80001912:	2ec080e7          	jalr	748(ra) # 80000bfa <holding>
    80001916:	c909                	beqz	a0,80001928 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001918:	749c                	ld	a5,40(s1)
    8000191a:	00978f63          	beq	a5,s1,80001938 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000191e:	60e2                	ld	ra,24(sp)
    80001920:	6442                	ld	s0,16(sp)
    80001922:	64a2                	ld	s1,8(sp)
    80001924:	6105                	addi	sp,sp,32
    80001926:	8082                	ret
    panic("wakeup1");
    80001928:	00007517          	auipc	a0,0x7
    8000192c:	8a850513          	addi	a0,a0,-1880 # 800081d0 <digits+0x188>
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	ca6080e7          	jalr	-858(ra) # 800005d6 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001938:	4c98                	lw	a4,24(s1)
    8000193a:	4785                	li	a5,1
    8000193c:	fef711e3          	bne	a4,a5,8000191e <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001940:	4789                	li	a5,2
    80001942:	cc9c                	sw	a5,24(s1)
}
    80001944:	bfe9                	j	8000191e <wakeup1+0x1c>

0000000080001946 <procinit>:
{
    80001946:	715d                	addi	sp,sp,-80
    80001948:	e486                	sd	ra,72(sp)
    8000194a:	e0a2                	sd	s0,64(sp)
    8000194c:	fc26                	sd	s1,56(sp)
    8000194e:	f84a                	sd	s2,48(sp)
    80001950:	f44e                	sd	s3,40(sp)
    80001952:	f052                	sd	s4,32(sp)
    80001954:	ec56                	sd	s5,24(sp)
    80001956:	e85a                	sd	s6,16(sp)
    80001958:	e45e                	sd	s7,8(sp)
    8000195a:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000195c:	00007597          	auipc	a1,0x7
    80001960:	87c58593          	addi	a1,a1,-1924 # 800081d8 <digits+0x190>
    80001964:	00010517          	auipc	a0,0x10
    80001968:	fec50513          	addi	a0,a0,-20 # 80011950 <pid_lock>
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	278080e7          	jalr	632(ra) # 80000be4 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001974:	00010917          	auipc	s2,0x10
    80001978:	3f490913          	addi	s2,s2,1012 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    8000197c:	00007b97          	auipc	s7,0x7
    80001980:	864b8b93          	addi	s7,s7,-1948 # 800081e0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001984:	8b4a                	mv	s6,s2
    80001986:	00006a97          	auipc	s5,0x6
    8000198a:	67aa8a93          	addi	s5,s5,1658 # 80008000 <etext>
    8000198e:	040009b7          	lui	s3,0x4000
    80001992:	19fd                	addi	s3,s3,-1
    80001994:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001996:	0001aa17          	auipc	s4,0x1a
    8000199a:	3d2a0a13          	addi	s4,s4,978 # 8001bd68 <tickslock>
      initlock(&p->lock, "proc");
    8000199e:	85de                	mv	a1,s7
    800019a0:	854a                	mv	a0,s2
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	242080e7          	jalr	578(ra) # 80000be4 <initlock>
      char *pa = kalloc();
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	1da080e7          	jalr	474(ra) # 80000b84 <kalloc>
    800019b2:	85aa                	mv	a1,a0
      if(pa == 0)
    800019b4:	c929                	beqz	a0,80001a06 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019b6:	416904b3          	sub	s1,s2,s6
    800019ba:	849d                	srai	s1,s1,0x7
    800019bc:	000ab783          	ld	a5,0(s5)
    800019c0:	02f484b3          	mul	s1,s1,a5
    800019c4:	2485                	addiw	s1,s1,1
    800019c6:	00d4949b          	slliw	s1,s1,0xd
    800019ca:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019ce:	4699                	li	a3,6
    800019d0:	6605                	lui	a2,0x1
    800019d2:	8526                	mv	a0,s1
    800019d4:	00000097          	auipc	ra,0x0
    800019d8:	85c080e7          	jalr	-1956(ra) # 80001230 <kvmmap>
      p->kstack = va;
    800019dc:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019e0:	28090913          	addi	s2,s2,640
    800019e4:	fb491de3          	bne	s2,s4,8000199e <procinit+0x58>
  kvminithart();
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	650080e7          	jalr	1616(ra) # 80001038 <kvminithart>
}
    800019f0:	60a6                	ld	ra,72(sp)
    800019f2:	6406                	ld	s0,64(sp)
    800019f4:	74e2                	ld	s1,56(sp)
    800019f6:	7942                	ld	s2,48(sp)
    800019f8:	79a2                	ld	s3,40(sp)
    800019fa:	7a02                	ld	s4,32(sp)
    800019fc:	6ae2                	ld	s5,24(sp)
    800019fe:	6b42                	ld	s6,16(sp)
    80001a00:	6ba2                	ld	s7,8(sp)
    80001a02:	6161                	addi	sp,sp,80
    80001a04:	8082                	ret
        panic("kalloc");
    80001a06:	00006517          	auipc	a0,0x6
    80001a0a:	7e250513          	addi	a0,a0,2018 # 800081e8 <digits+0x1a0>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	bc8080e7          	jalr	-1080(ra) # 800005d6 <panic>

0000000080001a16 <cpuid>:
{
    80001a16:	1141                	addi	sp,sp,-16
    80001a18:	e422                	sd	s0,8(sp)
    80001a1a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a1c:	8512                	mv	a0,tp
}
    80001a1e:	2501                	sext.w	a0,a0
    80001a20:	6422                	ld	s0,8(sp)
    80001a22:	0141                	addi	sp,sp,16
    80001a24:	8082                	ret

0000000080001a26 <mycpu>:
mycpu(void) {
    80001a26:	1141                	addi	sp,sp,-16
    80001a28:	e422                	sd	s0,8(sp)
    80001a2a:	0800                	addi	s0,sp,16
    80001a2c:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a2e:	2781                	sext.w	a5,a5
    80001a30:	079e                	slli	a5,a5,0x7
}
    80001a32:	00010517          	auipc	a0,0x10
    80001a36:	f3650513          	addi	a0,a0,-202 # 80011968 <cpus>
    80001a3a:	953e                	add	a0,a0,a5
    80001a3c:	6422                	ld	s0,8(sp)
    80001a3e:	0141                	addi	sp,sp,16
    80001a40:	8082                	ret

0000000080001a42 <myproc>:
myproc(void) {
    80001a42:	1101                	addi	sp,sp,-32
    80001a44:	ec06                	sd	ra,24(sp)
    80001a46:	e822                	sd	s0,16(sp)
    80001a48:	e426                	sd	s1,8(sp)
    80001a4a:	1000                	addi	s0,sp,32
  push_off();
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	1dc080e7          	jalr	476(ra) # 80000c28 <push_off>
    80001a54:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a56:	2781                	sext.w	a5,a5
    80001a58:	079e                	slli	a5,a5,0x7
    80001a5a:	00010717          	auipc	a4,0x10
    80001a5e:	ef670713          	addi	a4,a4,-266 # 80011950 <pid_lock>
    80001a62:	97ba                	add	a5,a5,a4
    80001a64:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	262080e7          	jalr	610(ra) # 80000cc8 <pop_off>
}
    80001a6e:	8526                	mv	a0,s1
    80001a70:	60e2                	ld	ra,24(sp)
    80001a72:	6442                	ld	s0,16(sp)
    80001a74:	64a2                	ld	s1,8(sp)
    80001a76:	6105                	addi	sp,sp,32
    80001a78:	8082                	ret

0000000080001a7a <forkret>:
{
    80001a7a:	1141                	addi	sp,sp,-16
    80001a7c:	e406                	sd	ra,8(sp)
    80001a7e:	e022                	sd	s0,0(sp)
    80001a80:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	fc0080e7          	jalr	-64(ra) # 80001a42 <myproc>
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	29e080e7          	jalr	670(ra) # 80000d28 <release>
  if (first) {
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	d9e7a783          	lw	a5,-610(a5) # 80008830 <first.1704>
    80001a9a:	eb89                	bnez	a5,80001aac <forkret+0x32>
  usertrapret();
    80001a9c:	00001097          	auipc	ra,0x1
    80001aa0:	c2a080e7          	jalr	-982(ra) # 800026c6 <usertrapret>
}
    80001aa4:	60a2                	ld	ra,8(sp)
    80001aa6:	6402                	ld	s0,0(sp)
    80001aa8:	0141                	addi	sp,sp,16
    80001aaa:	8082                	ret
    first = 0;
    80001aac:	00007797          	auipc	a5,0x7
    80001ab0:	d807a223          	sw	zero,-636(a5) # 80008830 <first.1704>
    fsinit(ROOTDEV);
    80001ab4:	4505                	li	a0,1
    80001ab6:	00002097          	auipc	ra,0x2
    80001aba:	a76080e7          	jalr	-1418(ra) # 8000352c <fsinit>
    80001abe:	bff9                	j	80001a9c <forkret+0x22>

0000000080001ac0 <allocpid>:
allocpid() {
    80001ac0:	1101                	addi	sp,sp,-32
    80001ac2:	ec06                	sd	ra,24(sp)
    80001ac4:	e822                	sd	s0,16(sp)
    80001ac6:	e426                	sd	s1,8(sp)
    80001ac8:	e04a                	sd	s2,0(sp)
    80001aca:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001acc:	00010917          	auipc	s2,0x10
    80001ad0:	e8490913          	addi	s2,s2,-380 # 80011950 <pid_lock>
    80001ad4:	854a                	mv	a0,s2
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	19e080e7          	jalr	414(ra) # 80000c74 <acquire>
  pid = nextpid;
    80001ade:	00007797          	auipc	a5,0x7
    80001ae2:	d5678793          	addi	a5,a5,-682 # 80008834 <nextpid>
    80001ae6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ae8:	0014871b          	addiw	a4,s1,1
    80001aec:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aee:	854a                	mv	a0,s2
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	238080e7          	jalr	568(ra) # 80000d28 <release>
}
    80001af8:	8526                	mv	a0,s1
    80001afa:	60e2                	ld	ra,24(sp)
    80001afc:	6442                	ld	s0,16(sp)
    80001afe:	64a2                	ld	s1,8(sp)
    80001b00:	6902                	ld	s2,0(sp)
    80001b02:	6105                	addi	sp,sp,32
    80001b04:	8082                	ret

0000000080001b06 <proc_pagetable>:
{
    80001b06:	1101                	addi	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	addi	s0,sp,32
    80001b12:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	8ea080e7          	jalr	-1814(ra) # 800013fe <uvmcreate>
    80001b1c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b1e:	c121                	beqz	a0,80001b5e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b20:	4729                	li	a4,10
    80001b22:	00005697          	auipc	a3,0x5
    80001b26:	4de68693          	addi	a3,a3,1246 # 80007000 <_trampoline>
    80001b2a:	6605                	lui	a2,0x1
    80001b2c:	040005b7          	lui	a1,0x4000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b2                	slli	a1,a1,0xc
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	66e080e7          	jalr	1646(ra) # 800011a2 <mappages>
    80001b3c:	02054863          	bltz	a0,80001b6c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b40:	4719                	li	a4,6
    80001b42:	05893683          	ld	a3,88(s2)
    80001b46:	6605                	lui	a2,0x1
    80001b48:	020005b7          	lui	a1,0x2000
    80001b4c:	15fd                	addi	a1,a1,-1
    80001b4e:	05b6                	slli	a1,a1,0xd
    80001b50:	8526                	mv	a0,s1
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	650080e7          	jalr	1616(ra) # 800011a2 <mappages>
    80001b5a:	02054163          	bltz	a0,80001b7c <proc_pagetable+0x76>
}
    80001b5e:	8526                	mv	a0,s1
    80001b60:	60e2                	ld	ra,24(sp)
    80001b62:	6442                	ld	s0,16(sp)
    80001b64:	64a2                	ld	s1,8(sp)
    80001b66:	6902                	ld	s2,0(sp)
    80001b68:	6105                	addi	sp,sp,32
    80001b6a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b6c:	4581                	li	a1,0
    80001b6e:	8526                	mv	a0,s1
    80001b70:	00000097          	auipc	ra,0x0
    80001b74:	a8a080e7          	jalr	-1398(ra) # 800015fa <uvmfree>
    return 0;
    80001b78:	4481                	li	s1,0
    80001b7a:	b7d5                	j	80001b5e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7c:	4681                	li	a3,0
    80001b7e:	4605                	li	a2,1
    80001b80:	040005b7          	lui	a1,0x4000
    80001b84:	15fd                	addi	a1,a1,-1
    80001b86:	05b2                	slli	a1,a1,0xc
    80001b88:	8526                	mv	a0,s1
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	7b0080e7          	jalr	1968(ra) # 8000133a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b92:	4581                	li	a1,0
    80001b94:	8526                	mv	a0,s1
    80001b96:	00000097          	auipc	ra,0x0
    80001b9a:	a64080e7          	jalr	-1436(ra) # 800015fa <uvmfree>
    return 0;
    80001b9e:	4481                	li	s1,0
    80001ba0:	bf7d                	j	80001b5e <proc_pagetable+0x58>

0000000080001ba2 <proc_freepagetable>:
{
    80001ba2:	1101                	addi	sp,sp,-32
    80001ba4:	ec06                	sd	ra,24(sp)
    80001ba6:	e822                	sd	s0,16(sp)
    80001ba8:	e426                	sd	s1,8(sp)
    80001baa:	e04a                	sd	s2,0(sp)
    80001bac:	1000                	addi	s0,sp,32
    80001bae:	84aa                	mv	s1,a0
    80001bb0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bb2:	4681                	li	a3,0
    80001bb4:	4605                	li	a2,1
    80001bb6:	040005b7          	lui	a1,0x4000
    80001bba:	15fd                	addi	a1,a1,-1
    80001bbc:	05b2                	slli	a1,a1,0xc
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	77c080e7          	jalr	1916(ra) # 8000133a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bc6:	4681                	li	a3,0
    80001bc8:	4605                	li	a2,1
    80001bca:	020005b7          	lui	a1,0x2000
    80001bce:	15fd                	addi	a1,a1,-1
    80001bd0:	05b6                	slli	a1,a1,0xd
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	766080e7          	jalr	1894(ra) # 8000133a <uvmunmap>
  uvmfree(pagetable, sz);
    80001bdc:	85ca                	mv	a1,s2
    80001bde:	8526                	mv	a0,s1
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	a1a080e7          	jalr	-1510(ra) # 800015fa <uvmfree>
}
    80001be8:	60e2                	ld	ra,24(sp)
    80001bea:	6442                	ld	s0,16(sp)
    80001bec:	64a2                	ld	s1,8(sp)
    80001bee:	6902                	ld	s2,0(sp)
    80001bf0:	6105                	addi	sp,sp,32
    80001bf2:	8082                	ret

0000000080001bf4 <freeproc>:
{
    80001bf4:	1101                	addi	sp,sp,-32
    80001bf6:	ec06                	sd	ra,24(sp)
    80001bf8:	e822                	sd	s0,16(sp)
    80001bfa:	e426                	sd	s1,8(sp)
    80001bfc:	1000                	addi	s0,sp,32
    80001bfe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c00:	6d28                	ld	a0,88(a0)
    80001c02:	c509                	beqz	a0,80001c0c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	e84080e7          	jalr	-380(ra) # 80000a88 <kfree>
  p->trapframe = 0;
    80001c0c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c10:	68a8                	ld	a0,80(s1)
    80001c12:	c511                	beqz	a0,80001c1e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c14:	64ac                	ld	a1,72(s1)
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	f8c080e7          	jalr	-116(ra) # 80001ba2 <proc_freepagetable>
  p->pagetable = 0;
    80001c1e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c22:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c26:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c2a:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c2e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c32:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c36:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c3a:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c3e:	0004ac23          	sw	zero,24(s1)
}
    80001c42:	60e2                	ld	ra,24(sp)
    80001c44:	6442                	ld	s0,16(sp)
    80001c46:	64a2                	ld	s1,8(sp)
    80001c48:	6105                	addi	sp,sp,32
    80001c4a:	8082                	ret

0000000080001c4c <allocproc>:
{
    80001c4c:	1101                	addi	sp,sp,-32
    80001c4e:	ec06                	sd	ra,24(sp)
    80001c50:	e822                	sd	s0,16(sp)
    80001c52:	e426                	sd	s1,8(sp)
    80001c54:	e04a                	sd	s2,0(sp)
    80001c56:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c58:	00010497          	auipc	s1,0x10
    80001c5c:	11048493          	addi	s1,s1,272 # 80011d68 <proc>
    80001c60:	0001a917          	auipc	s2,0x1a
    80001c64:	10890913          	addi	s2,s2,264 # 8001bd68 <tickslock>
    acquire(&p->lock);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	00a080e7          	jalr	10(ra) # 80000c74 <acquire>
    if(p->state == UNUSED) {
    80001c72:	4c9c                	lw	a5,24(s1)
    80001c74:	cf81                	beqz	a5,80001c8c <allocproc+0x40>
      release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	0b0080e7          	jalr	176(ra) # 80000d28 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c80:	28048493          	addi	s1,s1,640
    80001c84:	ff2492e3          	bne	s1,s2,80001c68 <allocproc+0x1c>
  return 0;
    80001c88:	4481                	li	s1,0
    80001c8a:	a085                	j	80001cea <allocproc+0x9e>
  p->pid = allocpid();
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	e34080e7          	jalr	-460(ra) # 80001ac0 <allocpid>
    80001c94:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	eee080e7          	jalr	-274(ra) # 80000b84 <kalloc>
    80001c9e:	892a                	mv	s2,a0
    80001ca0:	eca8                	sd	a0,88(s1)
    80001ca2:	c939                	beqz	a0,80001cf8 <allocproc+0xac>
  p->pagetable = proc_pagetable(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	e60080e7          	jalr	-416(ra) # 80001b06 <proc_pagetable>
    80001cae:	892a                	mv	s2,a0
    80001cb0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cb2:	c931                	beqz	a0,80001d06 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001cb4:	07000613          	li	a2,112
    80001cb8:	4581                	li	a1,0
    80001cba:	06048513          	addi	a0,s1,96
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	0b2080e7          	jalr	178(ra) # 80000d70 <memset>
  p->context.ra = (uint64)forkret;
    80001cc6:	00000797          	auipc	a5,0x0
    80001cca:	db478793          	addi	a5,a5,-588 # 80001a7a <forkret>
    80001cce:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cd0:	60bc                	ld	a5,64(s1)
    80001cd2:	6705                	lui	a4,0x1
    80001cd4:	97ba                	add	a5,a5,a4
    80001cd6:	f4bc                	sd	a5,104(s1)
  p->ticked = 0;
    80001cd8:	1604a623          	sw	zero,364(s1)
  p->ticks = 0;
    80001cdc:	1604a423          	sw	zero,360(s1)
  p->handler = 0;
    80001ce0:	1604b823          	sd	zero,368(s1)
  p->flag = 1;
    80001ce4:	4785                	li	a5,1
    80001ce6:	18f4a023          	sw	a5,384(s1)
}
    80001cea:	8526                	mv	a0,s1
    80001cec:	60e2                	ld	ra,24(sp)
    80001cee:	6442                	ld	s0,16(sp)
    80001cf0:	64a2                	ld	s1,8(sp)
    80001cf2:	6902                	ld	s2,0(sp)
    80001cf4:	6105                	addi	sp,sp,32
    80001cf6:	8082                	ret
    release(&p->lock);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	02e080e7          	jalr	46(ra) # 80000d28 <release>
    return 0;
    80001d02:	84ca                	mv	s1,s2
    80001d04:	b7dd                	j	80001cea <allocproc+0x9e>
    freeproc(p);
    80001d06:	8526                	mv	a0,s1
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	eec080e7          	jalr	-276(ra) # 80001bf4 <freeproc>
    release(&p->lock);
    80001d10:	8526                	mv	a0,s1
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	016080e7          	jalr	22(ra) # 80000d28 <release>
    return 0;
    80001d1a:	84ca                	mv	s1,s2
    80001d1c:	b7f9                	j	80001cea <allocproc+0x9e>

0000000080001d1e <userinit>:
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	f24080e7          	jalr	-220(ra) # 80001c4c <allocproc>
    80001d30:	84aa                	mv	s1,a0
  initproc = p;
    80001d32:	00007797          	auipc	a5,0x7
    80001d36:	2ea7b323          	sd	a0,742(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d3a:	03400613          	li	a2,52
    80001d3e:	00007597          	auipc	a1,0x7
    80001d42:	b0258593          	addi	a1,a1,-1278 # 80008840 <initcode>
    80001d46:	6928                	ld	a0,80(a0)
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	6e4080e7          	jalr	1764(ra) # 8000142c <uvminit>
  p->sz = PGSIZE;
    80001d50:	6785                	lui	a5,0x1
    80001d52:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d54:	6cb8                	ld	a4,88(s1)
    80001d56:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d5a:	6cb8                	ld	a4,88(s1)
    80001d5c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d5e:	4641                	li	a2,16
    80001d60:	00006597          	auipc	a1,0x6
    80001d64:	49058593          	addi	a1,a1,1168 # 800081f0 <digits+0x1a8>
    80001d68:	15848513          	addi	a0,s1,344
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	15a080e7          	jalr	346(ra) # 80000ec6 <safestrcpy>
  p->cwd = namei("/");
    80001d74:	00006517          	auipc	a0,0x6
    80001d78:	48c50513          	addi	a0,a0,1164 # 80008200 <digits+0x1b8>
    80001d7c:	00002097          	auipc	ra,0x2
    80001d80:	1d8080e7          	jalr	472(ra) # 80003f54 <namei>
    80001d84:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d88:	4789                	li	a5,2
    80001d8a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d8c:	8526                	mv	a0,s1
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	f9a080e7          	jalr	-102(ra) # 80000d28 <release>
}
    80001d96:	60e2                	ld	ra,24(sp)
    80001d98:	6442                	ld	s0,16(sp)
    80001d9a:	64a2                	ld	s1,8(sp)
    80001d9c:	6105                	addi	sp,sp,32
    80001d9e:	8082                	ret

0000000080001da0 <growproc>:
{
    80001da0:	1101                	addi	sp,sp,-32
    80001da2:	ec06                	sd	ra,24(sp)
    80001da4:	e822                	sd	s0,16(sp)
    80001da6:	e426                	sd	s1,8(sp)
    80001da8:	e04a                	sd	s2,0(sp)
    80001daa:	1000                	addi	s0,sp,32
    80001dac:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	c94080e7          	jalr	-876(ra) # 80001a42 <myproc>
    80001db6:	892a                	mv	s2,a0
  sz = p->sz;
    80001db8:	652c                	ld	a1,72(a0)
    80001dba:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dbe:	00904f63          	bgtz	s1,80001ddc <growproc+0x3c>
  } else if(n < 0){
    80001dc2:	0204cc63          	bltz	s1,80001dfa <growproc+0x5a>
  p->sz = sz;
    80001dc6:	1602                	slli	a2,a2,0x20
    80001dc8:	9201                	srli	a2,a2,0x20
    80001dca:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dce:	4501                	li	a0,0
}
    80001dd0:	60e2                	ld	ra,24(sp)
    80001dd2:	6442                	ld	s0,16(sp)
    80001dd4:	64a2                	ld	s1,8(sp)
    80001dd6:	6902                	ld	s2,0(sp)
    80001dd8:	6105                	addi	sp,sp,32
    80001dda:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001ddc:	9e25                	addw	a2,a2,s1
    80001dde:	1602                	slli	a2,a2,0x20
    80001de0:	9201                	srli	a2,a2,0x20
    80001de2:	1582                	slli	a1,a1,0x20
    80001de4:	9181                	srli	a1,a1,0x20
    80001de6:	6928                	ld	a0,80(a0)
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	6fe080e7          	jalr	1790(ra) # 800014e6 <uvmalloc>
    80001df0:	0005061b          	sext.w	a2,a0
    80001df4:	fa69                	bnez	a2,80001dc6 <growproc+0x26>
      return -1;
    80001df6:	557d                	li	a0,-1
    80001df8:	bfe1                	j	80001dd0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dfa:	9e25                	addw	a2,a2,s1
    80001dfc:	1602                	slli	a2,a2,0x20
    80001dfe:	9201                	srli	a2,a2,0x20
    80001e00:	1582                	slli	a1,a1,0x20
    80001e02:	9181                	srli	a1,a1,0x20
    80001e04:	6928                	ld	a0,80(a0)
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	698080e7          	jalr	1688(ra) # 8000149e <uvmdealloc>
    80001e0e:	0005061b          	sext.w	a2,a0
    80001e12:	bf55                	j	80001dc6 <growproc+0x26>

0000000080001e14 <fork>:
{
    80001e14:	7179                	addi	sp,sp,-48
    80001e16:	f406                	sd	ra,40(sp)
    80001e18:	f022                	sd	s0,32(sp)
    80001e1a:	ec26                	sd	s1,24(sp)
    80001e1c:	e84a                	sd	s2,16(sp)
    80001e1e:	e44e                	sd	s3,8(sp)
    80001e20:	e052                	sd	s4,0(sp)
    80001e22:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	c1e080e7          	jalr	-994(ra) # 80001a42 <myproc>
    80001e2c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	e1e080e7          	jalr	-482(ra) # 80001c4c <allocproc>
    80001e36:	c175                	beqz	a0,80001f1a <fork+0x106>
    80001e38:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e3a:	04893603          	ld	a2,72(s2)
    80001e3e:	692c                	ld	a1,80(a0)
    80001e40:	05093503          	ld	a0,80(s2)
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	7ee080e7          	jalr	2030(ra) # 80001632 <uvmcopy>
    80001e4c:	04054863          	bltz	a0,80001e9c <fork+0x88>
  np->sz = p->sz;
    80001e50:	04893783          	ld	a5,72(s2)
    80001e54:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e58:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e5c:	05893683          	ld	a3,88(s2)
    80001e60:	87b6                	mv	a5,a3
    80001e62:	0589b703          	ld	a4,88(s3)
    80001e66:	12068693          	addi	a3,a3,288
    80001e6a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e6e:	6788                	ld	a0,8(a5)
    80001e70:	6b8c                	ld	a1,16(a5)
    80001e72:	6f90                	ld	a2,24(a5)
    80001e74:	01073023          	sd	a6,0(a4)
    80001e78:	e708                	sd	a0,8(a4)
    80001e7a:	eb0c                	sd	a1,16(a4)
    80001e7c:	ef10                	sd	a2,24(a4)
    80001e7e:	02078793          	addi	a5,a5,32
    80001e82:	02070713          	addi	a4,a4,32
    80001e86:	fed792e3          	bne	a5,a3,80001e6a <fork+0x56>
  np->trapframe->a0 = 0;
    80001e8a:	0589b783          	ld	a5,88(s3)
    80001e8e:	0607b823          	sd	zero,112(a5)
    80001e92:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e96:	15000a13          	li	s4,336
    80001e9a:	a03d                	j	80001ec8 <fork+0xb4>
    freeproc(np);
    80001e9c:	854e                	mv	a0,s3
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	d56080e7          	jalr	-682(ra) # 80001bf4 <freeproc>
    release(&np->lock);
    80001ea6:	854e                	mv	a0,s3
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	e80080e7          	jalr	-384(ra) # 80000d28 <release>
    return -1;
    80001eb0:	54fd                	li	s1,-1
    80001eb2:	a899                	j	80001f08 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb4:	00002097          	auipc	ra,0x2
    80001eb8:	72c080e7          	jalr	1836(ra) # 800045e0 <filedup>
    80001ebc:	009987b3          	add	a5,s3,s1
    80001ec0:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ec2:	04a1                	addi	s1,s1,8
    80001ec4:	01448763          	beq	s1,s4,80001ed2 <fork+0xbe>
    if(p->ofile[i])
    80001ec8:	009907b3          	add	a5,s2,s1
    80001ecc:	6388                	ld	a0,0(a5)
    80001ece:	f17d                	bnez	a0,80001eb4 <fork+0xa0>
    80001ed0:	bfcd                	j	80001ec2 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001ed2:	15093503          	ld	a0,336(s2)
    80001ed6:	00002097          	auipc	ra,0x2
    80001eda:	890080e7          	jalr	-1904(ra) # 80003766 <idup>
    80001ede:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ee2:	4641                	li	a2,16
    80001ee4:	15890593          	addi	a1,s2,344
    80001ee8:	15898513          	addi	a0,s3,344
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	fda080e7          	jalr	-38(ra) # 80000ec6 <safestrcpy>
  pid = np->pid;
    80001ef4:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ef8:	4789                	li	a5,2
    80001efa:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001efe:	854e                	mv	a0,s3
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	e28080e7          	jalr	-472(ra) # 80000d28 <release>
}
    80001f08:	8526                	mv	a0,s1
    80001f0a:	70a2                	ld	ra,40(sp)
    80001f0c:	7402                	ld	s0,32(sp)
    80001f0e:	64e2                	ld	s1,24(sp)
    80001f10:	6942                	ld	s2,16(sp)
    80001f12:	69a2                	ld	s3,8(sp)
    80001f14:	6a02                	ld	s4,0(sp)
    80001f16:	6145                	addi	sp,sp,48
    80001f18:	8082                	ret
    return -1;
    80001f1a:	54fd                	li	s1,-1
    80001f1c:	b7f5                	j	80001f08 <fork+0xf4>

0000000080001f1e <reparent>:
{
    80001f1e:	7179                	addi	sp,sp,-48
    80001f20:	f406                	sd	ra,40(sp)
    80001f22:	f022                	sd	s0,32(sp)
    80001f24:	ec26                	sd	s1,24(sp)
    80001f26:	e84a                	sd	s2,16(sp)
    80001f28:	e44e                	sd	s3,8(sp)
    80001f2a:	e052                	sd	s4,0(sp)
    80001f2c:	1800                	addi	s0,sp,48
    80001f2e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f30:	00010497          	auipc	s1,0x10
    80001f34:	e3848493          	addi	s1,s1,-456 # 80011d68 <proc>
      pp->parent = initproc;
    80001f38:	00007a17          	auipc	s4,0x7
    80001f3c:	0e0a0a13          	addi	s4,s4,224 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f40:	0001a997          	auipc	s3,0x1a
    80001f44:	e2898993          	addi	s3,s3,-472 # 8001bd68 <tickslock>
    80001f48:	a029                	j	80001f52 <reparent+0x34>
    80001f4a:	28048493          	addi	s1,s1,640
    80001f4e:	03348363          	beq	s1,s3,80001f74 <reparent+0x56>
    if(pp->parent == p){
    80001f52:	709c                	ld	a5,32(s1)
    80001f54:	ff279be3          	bne	a5,s2,80001f4a <reparent+0x2c>
      acquire(&pp->lock);
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	d1a080e7          	jalr	-742(ra) # 80000c74 <acquire>
      pp->parent = initproc;
    80001f62:	000a3783          	ld	a5,0(s4)
    80001f66:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f68:	8526                	mv	a0,s1
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	dbe080e7          	jalr	-578(ra) # 80000d28 <release>
    80001f72:	bfe1                	j	80001f4a <reparent+0x2c>
}
    80001f74:	70a2                	ld	ra,40(sp)
    80001f76:	7402                	ld	s0,32(sp)
    80001f78:	64e2                	ld	s1,24(sp)
    80001f7a:	6942                	ld	s2,16(sp)
    80001f7c:	69a2                	ld	s3,8(sp)
    80001f7e:	6a02                	ld	s4,0(sp)
    80001f80:	6145                	addi	sp,sp,48
    80001f82:	8082                	ret

0000000080001f84 <scheduler>:
{
    80001f84:	715d                	addi	sp,sp,-80
    80001f86:	e486                	sd	ra,72(sp)
    80001f88:	e0a2                	sd	s0,64(sp)
    80001f8a:	fc26                	sd	s1,56(sp)
    80001f8c:	f84a                	sd	s2,48(sp)
    80001f8e:	f44e                	sd	s3,40(sp)
    80001f90:	f052                	sd	s4,32(sp)
    80001f92:	ec56                	sd	s5,24(sp)
    80001f94:	e85a                	sd	s6,16(sp)
    80001f96:	e45e                	sd	s7,8(sp)
    80001f98:	e062                	sd	s8,0(sp)
    80001f9a:	0880                	addi	s0,sp,80
    80001f9c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f9e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fa0:	00779b13          	slli	s6,a5,0x7
    80001fa4:	00010717          	auipc	a4,0x10
    80001fa8:	9ac70713          	addi	a4,a4,-1620 # 80011950 <pid_lock>
    80001fac:	975a                	add	a4,a4,s6
    80001fae:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001fb2:	00010717          	auipc	a4,0x10
    80001fb6:	9be70713          	addi	a4,a4,-1602 # 80011970 <cpus+0x8>
    80001fba:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fbc:	4c0d                	li	s8,3
        c->proc = p;
    80001fbe:	079e                	slli	a5,a5,0x7
    80001fc0:	00010a17          	auipc	s4,0x10
    80001fc4:	990a0a13          	addi	s4,s4,-1648 # 80011950 <pid_lock>
    80001fc8:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fca:	0001a997          	auipc	s3,0x1a
    80001fce:	d9e98993          	addi	s3,s3,-610 # 8001bd68 <tickslock>
        found = 1;
    80001fd2:	4b85                	li	s7,1
    80001fd4:	a899                	j	8000202a <scheduler+0xa6>
        p->state = RUNNING;
    80001fd6:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fda:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fde:	06048593          	addi	a1,s1,96
    80001fe2:	855a                	mv	a0,s6
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	638080e7          	jalr	1592(ra) # 8000261c <swtch>
        c->proc = 0;
    80001fec:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001ff0:	8ade                	mv	s5,s7
      release(&p->lock);
    80001ff2:	8526                	mv	a0,s1
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	d34080e7          	jalr	-716(ra) # 80000d28 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ffc:	28048493          	addi	s1,s1,640
    80002000:	01348b63          	beq	s1,s3,80002016 <scheduler+0x92>
      acquire(&p->lock);
    80002004:	8526                	mv	a0,s1
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	c6e080e7          	jalr	-914(ra) # 80000c74 <acquire>
      if(p->state == RUNNABLE) {
    8000200e:	4c9c                	lw	a5,24(s1)
    80002010:	ff2791e3          	bne	a5,s2,80001ff2 <scheduler+0x6e>
    80002014:	b7c9                	j	80001fd6 <scheduler+0x52>
    if(found == 0) {
    80002016:	000a9a63          	bnez	s5,8000202a <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000201e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002022:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002026:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000202e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002032:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002036:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002038:	00010497          	auipc	s1,0x10
    8000203c:	d3048493          	addi	s1,s1,-720 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002040:	4909                	li	s2,2
    80002042:	b7c9                	j	80002004 <scheduler+0x80>

0000000080002044 <sched>:
{
    80002044:	7179                	addi	sp,sp,-48
    80002046:	f406                	sd	ra,40(sp)
    80002048:	f022                	sd	s0,32(sp)
    8000204a:	ec26                	sd	s1,24(sp)
    8000204c:	e84a                	sd	s2,16(sp)
    8000204e:	e44e                	sd	s3,8(sp)
    80002050:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002052:	00000097          	auipc	ra,0x0
    80002056:	9f0080e7          	jalr	-1552(ra) # 80001a42 <myproc>
    8000205a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	b9e080e7          	jalr	-1122(ra) # 80000bfa <holding>
    80002064:	c93d                	beqz	a0,800020da <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002066:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002068:	2781                	sext.w	a5,a5
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	00010717          	auipc	a4,0x10
    80002070:	8e470713          	addi	a4,a4,-1820 # 80011950 <pid_lock>
    80002074:	97ba                	add	a5,a5,a4
    80002076:	0907a703          	lw	a4,144(a5)
    8000207a:	4785                	li	a5,1
    8000207c:	06f71763          	bne	a4,a5,800020ea <sched+0xa6>
  if(p->state == RUNNING)
    80002080:	4c98                	lw	a4,24(s1)
    80002082:	478d                	li	a5,3
    80002084:	06f70b63          	beq	a4,a5,800020fa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002088:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000208c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000208e:	efb5                	bnez	a5,8000210a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002090:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002092:	00010917          	auipc	s2,0x10
    80002096:	8be90913          	addi	s2,s2,-1858 # 80011950 <pid_lock>
    8000209a:	2781                	sext.w	a5,a5
    8000209c:	079e                	slli	a5,a5,0x7
    8000209e:	97ca                	add	a5,a5,s2
    800020a0:	0947a983          	lw	s3,148(a5)
    800020a4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020a6:	2781                	sext.w	a5,a5
    800020a8:	079e                	slli	a5,a5,0x7
    800020aa:	00010597          	auipc	a1,0x10
    800020ae:	8c658593          	addi	a1,a1,-1850 # 80011970 <cpus+0x8>
    800020b2:	95be                	add	a1,a1,a5
    800020b4:	06048513          	addi	a0,s1,96
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	564080e7          	jalr	1380(ra) # 8000261c <swtch>
    800020c0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020c2:	2781                	sext.w	a5,a5
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	97ca                	add	a5,a5,s2
    800020c8:	0937aa23          	sw	s3,148(a5)
}
    800020cc:	70a2                	ld	ra,40(sp)
    800020ce:	7402                	ld	s0,32(sp)
    800020d0:	64e2                	ld	s1,24(sp)
    800020d2:	6942                	ld	s2,16(sp)
    800020d4:	69a2                	ld	s3,8(sp)
    800020d6:	6145                	addi	sp,sp,48
    800020d8:	8082                	ret
    panic("sched p->lock");
    800020da:	00006517          	auipc	a0,0x6
    800020de:	12e50513          	addi	a0,a0,302 # 80008208 <digits+0x1c0>
    800020e2:	ffffe097          	auipc	ra,0xffffe
    800020e6:	4f4080e7          	jalr	1268(ra) # 800005d6 <panic>
    panic("sched locks");
    800020ea:	00006517          	auipc	a0,0x6
    800020ee:	12e50513          	addi	a0,a0,302 # 80008218 <digits+0x1d0>
    800020f2:	ffffe097          	auipc	ra,0xffffe
    800020f6:	4e4080e7          	jalr	1252(ra) # 800005d6 <panic>
    panic("sched running");
    800020fa:	00006517          	auipc	a0,0x6
    800020fe:	12e50513          	addi	a0,a0,302 # 80008228 <digits+0x1e0>
    80002102:	ffffe097          	auipc	ra,0xffffe
    80002106:	4d4080e7          	jalr	1236(ra) # 800005d6 <panic>
    panic("sched interruptible");
    8000210a:	00006517          	auipc	a0,0x6
    8000210e:	12e50513          	addi	a0,a0,302 # 80008238 <digits+0x1f0>
    80002112:	ffffe097          	auipc	ra,0xffffe
    80002116:	4c4080e7          	jalr	1220(ra) # 800005d6 <panic>

000000008000211a <exit>:
{
    8000211a:	7179                	addi	sp,sp,-48
    8000211c:	f406                	sd	ra,40(sp)
    8000211e:	f022                	sd	s0,32(sp)
    80002120:	ec26                	sd	s1,24(sp)
    80002122:	e84a                	sd	s2,16(sp)
    80002124:	e44e                	sd	s3,8(sp)
    80002126:	e052                	sd	s4,0(sp)
    80002128:	1800                	addi	s0,sp,48
    8000212a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000212c:	00000097          	auipc	ra,0x0
    80002130:	916080e7          	jalr	-1770(ra) # 80001a42 <myproc>
    80002134:	89aa                	mv	s3,a0
  if(p == initproc)
    80002136:	00007797          	auipc	a5,0x7
    8000213a:	ee27b783          	ld	a5,-286(a5) # 80009018 <initproc>
    8000213e:	0d050493          	addi	s1,a0,208
    80002142:	15050913          	addi	s2,a0,336
    80002146:	02a79363          	bne	a5,a0,8000216c <exit+0x52>
    panic("init exiting");
    8000214a:	00006517          	auipc	a0,0x6
    8000214e:	10650513          	addi	a0,a0,262 # 80008250 <digits+0x208>
    80002152:	ffffe097          	auipc	ra,0xffffe
    80002156:	484080e7          	jalr	1156(ra) # 800005d6 <panic>
      fileclose(f);
    8000215a:	00002097          	auipc	ra,0x2
    8000215e:	4d8080e7          	jalr	1240(ra) # 80004632 <fileclose>
      p->ofile[fd] = 0;
    80002162:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002166:	04a1                	addi	s1,s1,8
    80002168:	01248563          	beq	s1,s2,80002172 <exit+0x58>
    if(p->ofile[fd]){
    8000216c:	6088                	ld	a0,0(s1)
    8000216e:	f575                	bnez	a0,8000215a <exit+0x40>
    80002170:	bfdd                	j	80002166 <exit+0x4c>
  begin_op();
    80002172:	00002097          	auipc	ra,0x2
    80002176:	fee080e7          	jalr	-18(ra) # 80004160 <begin_op>
  iput(p->cwd);
    8000217a:	1509b503          	ld	a0,336(s3)
    8000217e:	00001097          	auipc	ra,0x1
    80002182:	7e0080e7          	jalr	2016(ra) # 8000395e <iput>
  end_op();
    80002186:	00002097          	auipc	ra,0x2
    8000218a:	05a080e7          	jalr	90(ra) # 800041e0 <end_op>
  p->cwd = 0;
    8000218e:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002192:	00007497          	auipc	s1,0x7
    80002196:	e8648493          	addi	s1,s1,-378 # 80009018 <initproc>
    8000219a:	6088                	ld	a0,0(s1)
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	ad8080e7          	jalr	-1320(ra) # 80000c74 <acquire>
  wakeup1(initproc);
    800021a4:	6088                	ld	a0,0(s1)
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	75c080e7          	jalr	1884(ra) # 80001902 <wakeup1>
  release(&initproc->lock);
    800021ae:	6088                	ld	a0,0(s1)
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	b78080e7          	jalr	-1160(ra) # 80000d28 <release>
  acquire(&p->lock);
    800021b8:	854e                	mv	a0,s3
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	aba080e7          	jalr	-1350(ra) # 80000c74 <acquire>
  struct proc *original_parent = p->parent;
    800021c2:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021c6:	854e                	mv	a0,s3
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	b60080e7          	jalr	-1184(ra) # 80000d28 <release>
  acquire(&original_parent->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	aa2080e7          	jalr	-1374(ra) # 80000c74 <acquire>
  acquire(&p->lock);
    800021da:	854e                	mv	a0,s3
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	a98080e7          	jalr	-1384(ra) # 80000c74 <acquire>
  reparent(p);
    800021e4:	854e                	mv	a0,s3
    800021e6:	00000097          	auipc	ra,0x0
    800021ea:	d38080e7          	jalr	-712(ra) # 80001f1e <reparent>
  wakeup1(original_parent);
    800021ee:	8526                	mv	a0,s1
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	712080e7          	jalr	1810(ra) # 80001902 <wakeup1>
  p->xstate = status;
    800021f8:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021fc:	4791                	li	a5,4
    800021fe:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	b24080e7          	jalr	-1244(ra) # 80000d28 <release>
  sched();
    8000220c:	00000097          	auipc	ra,0x0
    80002210:	e38080e7          	jalr	-456(ra) # 80002044 <sched>
  panic("zombie exit");
    80002214:	00006517          	auipc	a0,0x6
    80002218:	04c50513          	addi	a0,a0,76 # 80008260 <digits+0x218>
    8000221c:	ffffe097          	auipc	ra,0xffffe
    80002220:	3ba080e7          	jalr	954(ra) # 800005d6 <panic>

0000000080002224 <yield>:
{
    80002224:	1101                	addi	sp,sp,-32
    80002226:	ec06                	sd	ra,24(sp)
    80002228:	e822                	sd	s0,16(sp)
    8000222a:	e426                	sd	s1,8(sp)
    8000222c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	814080e7          	jalr	-2028(ra) # 80001a42 <myproc>
    80002236:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a3c080e7          	jalr	-1476(ra) # 80000c74 <acquire>
  p->state = RUNNABLE;
    80002240:	4789                	li	a5,2
    80002242:	cc9c                	sw	a5,24(s1)
  sched();
    80002244:	00000097          	auipc	ra,0x0
    80002248:	e00080e7          	jalr	-512(ra) # 80002044 <sched>
  release(&p->lock);
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	ada080e7          	jalr	-1318(ra) # 80000d28 <release>
}
    80002256:	60e2                	ld	ra,24(sp)
    80002258:	6442                	ld	s0,16(sp)
    8000225a:	64a2                	ld	s1,8(sp)
    8000225c:	6105                	addi	sp,sp,32
    8000225e:	8082                	ret

0000000080002260 <sleep>:
{
    80002260:	7179                	addi	sp,sp,-48
    80002262:	f406                	sd	ra,40(sp)
    80002264:	f022                	sd	s0,32(sp)
    80002266:	ec26                	sd	s1,24(sp)
    80002268:	e84a                	sd	s2,16(sp)
    8000226a:	e44e                	sd	s3,8(sp)
    8000226c:	1800                	addi	s0,sp,48
    8000226e:	89aa                	mv	s3,a0
    80002270:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	7d0080e7          	jalr	2000(ra) # 80001a42 <myproc>
    8000227a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000227c:	05250663          	beq	a0,s2,800022c8 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	9f4080e7          	jalr	-1548(ra) # 80000c74 <acquire>
    release(lk);
    80002288:	854a                	mv	a0,s2
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	a9e080e7          	jalr	-1378(ra) # 80000d28 <release>
  p->chan = chan;
    80002292:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002296:	4785                	li	a5,1
    80002298:	cc9c                	sw	a5,24(s1)
  sched();
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	daa080e7          	jalr	-598(ra) # 80002044 <sched>
  p->chan = 0;
    800022a2:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022a6:	8526                	mv	a0,s1
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	a80080e7          	jalr	-1408(ra) # 80000d28 <release>
    acquire(lk);
    800022b0:	854a                	mv	a0,s2
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9c2080e7          	jalr	-1598(ra) # 80000c74 <acquire>
}
    800022ba:	70a2                	ld	ra,40(sp)
    800022bc:	7402                	ld	s0,32(sp)
    800022be:	64e2                	ld	s1,24(sp)
    800022c0:	6942                	ld	s2,16(sp)
    800022c2:	69a2                	ld	s3,8(sp)
    800022c4:	6145                	addi	sp,sp,48
    800022c6:	8082                	ret
  p->chan = chan;
    800022c8:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022cc:	4785                	li	a5,1
    800022ce:	cd1c                	sw	a5,24(a0)
  sched();
    800022d0:	00000097          	auipc	ra,0x0
    800022d4:	d74080e7          	jalr	-652(ra) # 80002044 <sched>
  p->chan = 0;
    800022d8:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022dc:	bff9                	j	800022ba <sleep+0x5a>

00000000800022de <wait>:
{
    800022de:	715d                	addi	sp,sp,-80
    800022e0:	e486                	sd	ra,72(sp)
    800022e2:	e0a2                	sd	s0,64(sp)
    800022e4:	fc26                	sd	s1,56(sp)
    800022e6:	f84a                	sd	s2,48(sp)
    800022e8:	f44e                	sd	s3,40(sp)
    800022ea:	f052                	sd	s4,32(sp)
    800022ec:	ec56                	sd	s5,24(sp)
    800022ee:	e85a                	sd	s6,16(sp)
    800022f0:	e45e                	sd	s7,8(sp)
    800022f2:	e062                	sd	s8,0(sp)
    800022f4:	0880                	addi	s0,sp,80
    800022f6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	74a080e7          	jalr	1866(ra) # 80001a42 <myproc>
    80002300:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002302:	8c2a                	mv	s8,a0
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	970080e7          	jalr	-1680(ra) # 80000c74 <acquire>
    havekids = 0;
    8000230c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000230e:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002310:	0001a997          	auipc	s3,0x1a
    80002314:	a5898993          	addi	s3,s3,-1448 # 8001bd68 <tickslock>
        havekids = 1;
    80002318:	4a85                	li	s5,1
    havekids = 0;
    8000231a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000231c:	00010497          	auipc	s1,0x10
    80002320:	a4c48493          	addi	s1,s1,-1460 # 80011d68 <proc>
    80002324:	a08d                	j	80002386 <wait+0xa8>
          pid = np->pid;
    80002326:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000232a:	000b0e63          	beqz	s6,80002346 <wait+0x68>
    8000232e:	4691                	li	a3,4
    80002330:	03448613          	addi	a2,s1,52
    80002334:	85da                	mv	a1,s6
    80002336:	05093503          	ld	a0,80(s2)
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	3fc080e7          	jalr	1020(ra) # 80001736 <copyout>
    80002342:	02054263          	bltz	a0,80002366 <wait+0x88>
          freeproc(np);
    80002346:	8526                	mv	a0,s1
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	8ac080e7          	jalr	-1876(ra) # 80001bf4 <freeproc>
          release(&np->lock);
    80002350:	8526                	mv	a0,s1
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	9d6080e7          	jalr	-1578(ra) # 80000d28 <release>
          release(&p->lock);
    8000235a:	854a                	mv	a0,s2
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	9cc080e7          	jalr	-1588(ra) # 80000d28 <release>
          return pid;
    80002364:	a8a9                	j	800023be <wait+0xe0>
            release(&np->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	9c0080e7          	jalr	-1600(ra) # 80000d28 <release>
            release(&p->lock);
    80002370:	854a                	mv	a0,s2
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	9b6080e7          	jalr	-1610(ra) # 80000d28 <release>
            return -1;
    8000237a:	59fd                	li	s3,-1
    8000237c:	a089                	j	800023be <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000237e:	28048493          	addi	s1,s1,640
    80002382:	03348463          	beq	s1,s3,800023aa <wait+0xcc>
      if(np->parent == p){
    80002386:	709c                	ld	a5,32(s1)
    80002388:	ff279be3          	bne	a5,s2,8000237e <wait+0xa0>
        acquire(&np->lock);
    8000238c:	8526                	mv	a0,s1
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	8e6080e7          	jalr	-1818(ra) # 80000c74 <acquire>
        if(np->state == ZOMBIE){
    80002396:	4c9c                	lw	a5,24(s1)
    80002398:	f94787e3          	beq	a5,s4,80002326 <wait+0x48>
        release(&np->lock);
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	98a080e7          	jalr	-1654(ra) # 80000d28 <release>
        havekids = 1;
    800023a6:	8756                	mv	a4,s5
    800023a8:	bfd9                	j	8000237e <wait+0xa0>
    if(!havekids || p->killed){
    800023aa:	c701                	beqz	a4,800023b2 <wait+0xd4>
    800023ac:	03092783          	lw	a5,48(s2)
    800023b0:	c785                	beqz	a5,800023d8 <wait+0xfa>
      release(&p->lock);
    800023b2:	854a                	mv	a0,s2
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	974080e7          	jalr	-1676(ra) # 80000d28 <release>
      return -1;
    800023bc:	59fd                	li	s3,-1
}
    800023be:	854e                	mv	a0,s3
    800023c0:	60a6                	ld	ra,72(sp)
    800023c2:	6406                	ld	s0,64(sp)
    800023c4:	74e2                	ld	s1,56(sp)
    800023c6:	7942                	ld	s2,48(sp)
    800023c8:	79a2                	ld	s3,40(sp)
    800023ca:	7a02                	ld	s4,32(sp)
    800023cc:	6ae2                	ld	s5,24(sp)
    800023ce:	6b42                	ld	s6,16(sp)
    800023d0:	6ba2                	ld	s7,8(sp)
    800023d2:	6c02                	ld	s8,0(sp)
    800023d4:	6161                	addi	sp,sp,80
    800023d6:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023d8:	85e2                	mv	a1,s8
    800023da:	854a                	mv	a0,s2
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	e84080e7          	jalr	-380(ra) # 80002260 <sleep>
    havekids = 0;
    800023e4:	bf1d                	j	8000231a <wait+0x3c>

00000000800023e6 <wakeup>:
{
    800023e6:	7139                	addi	sp,sp,-64
    800023e8:	fc06                	sd	ra,56(sp)
    800023ea:	f822                	sd	s0,48(sp)
    800023ec:	f426                	sd	s1,40(sp)
    800023ee:	f04a                	sd	s2,32(sp)
    800023f0:	ec4e                	sd	s3,24(sp)
    800023f2:	e852                	sd	s4,16(sp)
    800023f4:	e456                	sd	s5,8(sp)
    800023f6:	0080                	addi	s0,sp,64
    800023f8:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023fa:	00010497          	auipc	s1,0x10
    800023fe:	96e48493          	addi	s1,s1,-1682 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002402:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002404:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002406:	0001a917          	auipc	s2,0x1a
    8000240a:	96290913          	addi	s2,s2,-1694 # 8001bd68 <tickslock>
    8000240e:	a821                	j	80002426 <wakeup+0x40>
      p->state = RUNNABLE;
    80002410:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	912080e7          	jalr	-1774(ra) # 80000d28 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000241e:	28048493          	addi	s1,s1,640
    80002422:	01248e63          	beq	s1,s2,8000243e <wakeup+0x58>
    acquire(&p->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	84c080e7          	jalr	-1972(ra) # 80000c74 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002430:	4c9c                	lw	a5,24(s1)
    80002432:	ff3791e3          	bne	a5,s3,80002414 <wakeup+0x2e>
    80002436:	749c                	ld	a5,40(s1)
    80002438:	fd479ee3          	bne	a5,s4,80002414 <wakeup+0x2e>
    8000243c:	bfd1                	j	80002410 <wakeup+0x2a>
}
    8000243e:	70e2                	ld	ra,56(sp)
    80002440:	7442                	ld	s0,48(sp)
    80002442:	74a2                	ld	s1,40(sp)
    80002444:	7902                	ld	s2,32(sp)
    80002446:	69e2                	ld	s3,24(sp)
    80002448:	6a42                	ld	s4,16(sp)
    8000244a:	6aa2                	ld	s5,8(sp)
    8000244c:	6121                	addi	sp,sp,64
    8000244e:	8082                	ret

0000000080002450 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002450:	7179                	addi	sp,sp,-48
    80002452:	f406                	sd	ra,40(sp)
    80002454:	f022                	sd	s0,32(sp)
    80002456:	ec26                	sd	s1,24(sp)
    80002458:	e84a                	sd	s2,16(sp)
    8000245a:	e44e                	sd	s3,8(sp)
    8000245c:	1800                	addi	s0,sp,48
    8000245e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002460:	00010497          	auipc	s1,0x10
    80002464:	90848493          	addi	s1,s1,-1784 # 80011d68 <proc>
    80002468:	0001a997          	auipc	s3,0x1a
    8000246c:	90098993          	addi	s3,s3,-1792 # 8001bd68 <tickslock>
    acquire(&p->lock);
    80002470:	8526                	mv	a0,s1
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	802080e7          	jalr	-2046(ra) # 80000c74 <acquire>
    if(p->pid == pid){
    8000247a:	5c9c                	lw	a5,56(s1)
    8000247c:	01278d63          	beq	a5,s2,80002496 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	8a6080e7          	jalr	-1882(ra) # 80000d28 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000248a:	28048493          	addi	s1,s1,640
    8000248e:	ff3491e3          	bne	s1,s3,80002470 <kill+0x20>
  }
  return -1;
    80002492:	557d                	li	a0,-1
    80002494:	a829                	j	800024ae <kill+0x5e>
      p->killed = 1;
    80002496:	4785                	li	a5,1
    80002498:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000249a:	4c98                	lw	a4,24(s1)
    8000249c:	4785                	li	a5,1
    8000249e:	00f70f63          	beq	a4,a5,800024bc <kill+0x6c>
      release(&p->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	884080e7          	jalr	-1916(ra) # 80000d28 <release>
      return 0;
    800024ac:	4501                	li	a0,0
}
    800024ae:	70a2                	ld	ra,40(sp)
    800024b0:	7402                	ld	s0,32(sp)
    800024b2:	64e2                	ld	s1,24(sp)
    800024b4:	6942                	ld	s2,16(sp)
    800024b6:	69a2                	ld	s3,8(sp)
    800024b8:	6145                	addi	sp,sp,48
    800024ba:	8082                	ret
        p->state = RUNNABLE;
    800024bc:	4789                	li	a5,2
    800024be:	cc9c                	sw	a5,24(s1)
    800024c0:	b7cd                	j	800024a2 <kill+0x52>

00000000800024c2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024c2:	7179                	addi	sp,sp,-48
    800024c4:	f406                	sd	ra,40(sp)
    800024c6:	f022                	sd	s0,32(sp)
    800024c8:	ec26                	sd	s1,24(sp)
    800024ca:	e84a                	sd	s2,16(sp)
    800024cc:	e44e                	sd	s3,8(sp)
    800024ce:	e052                	sd	s4,0(sp)
    800024d0:	1800                	addi	s0,sp,48
    800024d2:	84aa                	mv	s1,a0
    800024d4:	892e                	mv	s2,a1
    800024d6:	89b2                	mv	s3,a2
    800024d8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	568080e7          	jalr	1384(ra) # 80001a42 <myproc>
  if(user_dst){
    800024e2:	c08d                	beqz	s1,80002504 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024e4:	86d2                	mv	a3,s4
    800024e6:	864e                	mv	a2,s3
    800024e8:	85ca                	mv	a1,s2
    800024ea:	6928                	ld	a0,80(a0)
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	24a080e7          	jalr	586(ra) # 80001736 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024f4:	70a2                	ld	ra,40(sp)
    800024f6:	7402                	ld	s0,32(sp)
    800024f8:	64e2                	ld	s1,24(sp)
    800024fa:	6942                	ld	s2,16(sp)
    800024fc:	69a2                	ld	s3,8(sp)
    800024fe:	6a02                	ld	s4,0(sp)
    80002500:	6145                	addi	sp,sp,48
    80002502:	8082                	ret
    memmove((char *)dst, src, len);
    80002504:	000a061b          	sext.w	a2,s4
    80002508:	85ce                	mv	a1,s3
    8000250a:	854a                	mv	a0,s2
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	8c4080e7          	jalr	-1852(ra) # 80000dd0 <memmove>
    return 0;
    80002514:	8526                	mv	a0,s1
    80002516:	bff9                	j	800024f4 <either_copyout+0x32>

0000000080002518 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002518:	7179                	addi	sp,sp,-48
    8000251a:	f406                	sd	ra,40(sp)
    8000251c:	f022                	sd	s0,32(sp)
    8000251e:	ec26                	sd	s1,24(sp)
    80002520:	e84a                	sd	s2,16(sp)
    80002522:	e44e                	sd	s3,8(sp)
    80002524:	e052                	sd	s4,0(sp)
    80002526:	1800                	addi	s0,sp,48
    80002528:	892a                	mv	s2,a0
    8000252a:	84ae                	mv	s1,a1
    8000252c:	89b2                	mv	s3,a2
    8000252e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	512080e7          	jalr	1298(ra) # 80001a42 <myproc>
  if(user_src){
    80002538:	c08d                	beqz	s1,8000255a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000253a:	86d2                	mv	a3,s4
    8000253c:	864e                	mv	a2,s3
    8000253e:	85ca                	mv	a1,s2
    80002540:	6928                	ld	a0,80(a0)
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	280080e7          	jalr	640(ra) # 800017c2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000254a:	70a2                	ld	ra,40(sp)
    8000254c:	7402                	ld	s0,32(sp)
    8000254e:	64e2                	ld	s1,24(sp)
    80002550:	6942                	ld	s2,16(sp)
    80002552:	69a2                	ld	s3,8(sp)
    80002554:	6a02                	ld	s4,0(sp)
    80002556:	6145                	addi	sp,sp,48
    80002558:	8082                	ret
    memmove(dst, (char*)src, len);
    8000255a:	000a061b          	sext.w	a2,s4
    8000255e:	85ce                	mv	a1,s3
    80002560:	854a                	mv	a0,s2
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	86e080e7          	jalr	-1938(ra) # 80000dd0 <memmove>
    return 0;
    8000256a:	8526                	mv	a0,s1
    8000256c:	bff9                	j	8000254a <either_copyin+0x32>

000000008000256e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000256e:	715d                	addi	sp,sp,-80
    80002570:	e486                	sd	ra,72(sp)
    80002572:	e0a2                	sd	s0,64(sp)
    80002574:	fc26                	sd	s1,56(sp)
    80002576:	f84a                	sd	s2,48(sp)
    80002578:	f44e                	sd	s3,40(sp)
    8000257a:	f052                	sd	s4,32(sp)
    8000257c:	ec56                	sd	s5,24(sp)
    8000257e:	e85a                	sd	s6,16(sp)
    80002580:	e45e                	sd	s7,8(sp)
    80002582:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002584:	00006517          	auipc	a0,0x6
    80002588:	b4c50513          	addi	a0,a0,-1204 # 800080d0 <digits+0x88>
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	09c080e7          	jalr	156(ra) # 80000628 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002594:	00010497          	auipc	s1,0x10
    80002598:	92c48493          	addi	s1,s1,-1748 # 80011ec0 <proc+0x158>
    8000259c:	0001a917          	auipc	s2,0x1a
    800025a0:	92490913          	addi	s2,s2,-1756 # 8001bec0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a4:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025a6:	00006997          	auipc	s3,0x6
    800025aa:	cca98993          	addi	s3,s3,-822 # 80008270 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025ae:	00006a97          	auipc	s5,0x6
    800025b2:	ccaa8a93          	addi	s5,s5,-822 # 80008278 <digits+0x230>
    printf("\n");
    800025b6:	00006a17          	auipc	s4,0x6
    800025ba:	b1aa0a13          	addi	s4,s4,-1254 # 800080d0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025be:	00006b97          	auipc	s7,0x6
    800025c2:	cf2b8b93          	addi	s7,s7,-782 # 800082b0 <states.1744>
    800025c6:	a00d                	j	800025e8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025c8:	ee06a583          	lw	a1,-288(a3)
    800025cc:	8556                	mv	a0,s5
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	05a080e7          	jalr	90(ra) # 80000628 <printf>
    printf("\n");
    800025d6:	8552                	mv	a0,s4
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	050080e7          	jalr	80(ra) # 80000628 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e0:	28048493          	addi	s1,s1,640
    800025e4:	03248163          	beq	s1,s2,80002606 <procdump+0x98>
    if(p->state == UNUSED)
    800025e8:	86a6                	mv	a3,s1
    800025ea:	ec04a783          	lw	a5,-320(s1)
    800025ee:	dbed                	beqz	a5,800025e0 <procdump+0x72>
      state = "???";
    800025f0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f2:	fcfb6be3          	bltu	s6,a5,800025c8 <procdump+0x5a>
    800025f6:	1782                	slli	a5,a5,0x20
    800025f8:	9381                	srli	a5,a5,0x20
    800025fa:	078e                	slli	a5,a5,0x3
    800025fc:	97de                	add	a5,a5,s7
    800025fe:	6390                	ld	a2,0(a5)
    80002600:	f661                	bnez	a2,800025c8 <procdump+0x5a>
      state = "???";
    80002602:	864e                	mv	a2,s3
    80002604:	b7d1                	j	800025c8 <procdump+0x5a>
  }
}
    80002606:	60a6                	ld	ra,72(sp)
    80002608:	6406                	ld	s0,64(sp)
    8000260a:	74e2                	ld	s1,56(sp)
    8000260c:	7942                	ld	s2,48(sp)
    8000260e:	79a2                	ld	s3,40(sp)
    80002610:	7a02                	ld	s4,32(sp)
    80002612:	6ae2                	ld	s5,24(sp)
    80002614:	6b42                	ld	s6,16(sp)
    80002616:	6ba2                	ld	s7,8(sp)
    80002618:	6161                	addi	sp,sp,80
    8000261a:	8082                	ret

000000008000261c <swtch>:
    8000261c:	00153023          	sd	ra,0(a0)
    80002620:	00253423          	sd	sp,8(a0)
    80002624:	e900                	sd	s0,16(a0)
    80002626:	ed04                	sd	s1,24(a0)
    80002628:	03253023          	sd	s2,32(a0)
    8000262c:	03353423          	sd	s3,40(a0)
    80002630:	03453823          	sd	s4,48(a0)
    80002634:	03553c23          	sd	s5,56(a0)
    80002638:	05653023          	sd	s6,64(a0)
    8000263c:	05753423          	sd	s7,72(a0)
    80002640:	05853823          	sd	s8,80(a0)
    80002644:	05953c23          	sd	s9,88(a0)
    80002648:	07a53023          	sd	s10,96(a0)
    8000264c:	07b53423          	sd	s11,104(a0)
    80002650:	0005b083          	ld	ra,0(a1)
    80002654:	0085b103          	ld	sp,8(a1)
    80002658:	6980                	ld	s0,16(a1)
    8000265a:	6d84                	ld	s1,24(a1)
    8000265c:	0205b903          	ld	s2,32(a1)
    80002660:	0285b983          	ld	s3,40(a1)
    80002664:	0305ba03          	ld	s4,48(a1)
    80002668:	0385ba83          	ld	s5,56(a1)
    8000266c:	0405bb03          	ld	s6,64(a1)
    80002670:	0485bb83          	ld	s7,72(a1)
    80002674:	0505bc03          	ld	s8,80(a1)
    80002678:	0585bc83          	ld	s9,88(a1)
    8000267c:	0605bd03          	ld	s10,96(a1)
    80002680:	0685bd83          	ld	s11,104(a1)
    80002684:	8082                	ret

0000000080002686 <trapinit>:
extern int devintr();
extern pagetable_t kernel_pagetable;

void
trapinit(void)
{
    80002686:	1141                	addi	sp,sp,-16
    80002688:	e406                	sd	ra,8(sp)
    8000268a:	e022                	sd	s0,0(sp)
    8000268c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000268e:	00006597          	auipc	a1,0x6
    80002692:	c4a58593          	addi	a1,a1,-950 # 800082d8 <states.1744+0x28>
    80002696:	00019517          	auipc	a0,0x19
    8000269a:	6d250513          	addi	a0,a0,1746 # 8001bd68 <tickslock>
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	546080e7          	jalr	1350(ra) # 80000be4 <initlock>
}
    800026a6:	60a2                	ld	ra,8(sp)
    800026a8:	6402                	ld	s0,0(sp)
    800026aa:	0141                	addi	sp,sp,16
    800026ac:	8082                	ret

00000000800026ae <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026ae:	1141                	addi	sp,sp,-16
    800026b0:	e422                	sd	s0,8(sp)
    800026b2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b4:	00003797          	auipc	a5,0x3
    800026b8:	7bc78793          	addi	a5,a5,1980 # 80005e70 <kernelvec>
    800026bc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026c0:	6422                	ld	s0,8(sp)
    800026c2:	0141                	addi	sp,sp,16
    800026c4:	8082                	ret

00000000800026c6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026c6:	1141                	addi	sp,sp,-16
    800026c8:	e406                	sd	ra,8(sp)
    800026ca:	e022                	sd	s0,0(sp)
    800026cc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026ce:	fffff097          	auipc	ra,0xfffff
    800026d2:	374080e7          	jalr	884(ra) # 80001a42 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026da:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026dc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026e0:	00005617          	auipc	a2,0x5
    800026e4:	92060613          	addi	a2,a2,-1760 # 80007000 <_trampoline>
    800026e8:	00005697          	auipc	a3,0x5
    800026ec:	91868693          	addi	a3,a3,-1768 # 80007000 <_trampoline>
    800026f0:	8e91                	sub	a3,a3,a2
    800026f2:	040007b7          	lui	a5,0x4000
    800026f6:	17fd                	addi	a5,a5,-1
    800026f8:	07b2                	slli	a5,a5,0xc
    800026fa:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002700:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002702:	180026f3          	csrr	a3,satp
    80002706:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002708:	6d38                	ld	a4,88(a0)
    8000270a:	6134                	ld	a3,64(a0)
    8000270c:	6585                	lui	a1,0x1
    8000270e:	96ae                	add	a3,a3,a1
    80002710:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002712:	6d38                	ld	a4,88(a0)
    80002714:	00000697          	auipc	a3,0x0
    80002718:	13868693          	addi	a3,a3,312 # 8000284c <usertrap>
    8000271c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000271e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002720:	8692                	mv	a3,tp
    80002722:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002724:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002728:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000272c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002730:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002734:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002736:	6f18                	ld	a4,24(a4)
    80002738:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000273c:	692c                	ld	a1,80(a0)
    8000273e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002740:	00005717          	auipc	a4,0x5
    80002744:	95070713          	addi	a4,a4,-1712 # 80007090 <userret>
    80002748:	8f11                	sub	a4,a4,a2
    8000274a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000274c:	577d                	li	a4,-1
    8000274e:	177e                	slli	a4,a4,0x3f
    80002750:	8dd9                	or	a1,a1,a4
    80002752:	02000537          	lui	a0,0x2000
    80002756:	157d                	addi	a0,a0,-1
    80002758:	0536                	slli	a0,a0,0xd
    8000275a:	9782                	jalr	a5
}
    8000275c:	60a2                	ld	ra,8(sp)
    8000275e:	6402                	ld	s0,0(sp)
    80002760:	0141                	addi	sp,sp,16
    80002762:	8082                	ret

0000000080002764 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002764:	1101                	addi	sp,sp,-32
    80002766:	ec06                	sd	ra,24(sp)
    80002768:	e822                	sd	s0,16(sp)
    8000276a:	e426                	sd	s1,8(sp)
    8000276c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000276e:	00019497          	auipc	s1,0x19
    80002772:	5fa48493          	addi	s1,s1,1530 # 8001bd68 <tickslock>
    80002776:	8526                	mv	a0,s1
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	4fc080e7          	jalr	1276(ra) # 80000c74 <acquire>
  ticks++;
    80002780:	00007517          	auipc	a0,0x7
    80002784:	8a050513          	addi	a0,a0,-1888 # 80009020 <ticks>
    80002788:	411c                	lw	a5,0(a0)
    8000278a:	2785                	addiw	a5,a5,1
    8000278c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000278e:	00000097          	auipc	ra,0x0
    80002792:	c58080e7          	jalr	-936(ra) # 800023e6 <wakeup>
  release(&tickslock);
    80002796:	8526                	mv	a0,s1
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	590080e7          	jalr	1424(ra) # 80000d28 <release>
}
    800027a0:	60e2                	ld	ra,24(sp)
    800027a2:	6442                	ld	s0,16(sp)
    800027a4:	64a2                	ld	s1,8(sp)
    800027a6:	6105                	addi	sp,sp,32
    800027a8:	8082                	ret

00000000800027aa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027aa:	1101                	addi	sp,sp,-32
    800027ac:	ec06                	sd	ra,24(sp)
    800027ae:	e822                	sd	s0,16(sp)
    800027b0:	e426                	sd	s1,8(sp)
    800027b2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027b4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027b8:	00074d63          	bltz	a4,800027d2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027bc:	57fd                	li	a5,-1
    800027be:	17fe                	slli	a5,a5,0x3f
    800027c0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027c2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027c4:	06f70363          	beq	a4,a5,8000282a <devintr+0x80>
  }
}
    800027c8:	60e2                	ld	ra,24(sp)
    800027ca:	6442                	ld	s0,16(sp)
    800027cc:	64a2                	ld	s1,8(sp)
    800027ce:	6105                	addi	sp,sp,32
    800027d0:	8082                	ret
     (scause & 0xff) == 9){
    800027d2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027d6:	46a5                	li	a3,9
    800027d8:	fed792e3          	bne	a5,a3,800027bc <devintr+0x12>
    int irq = plic_claim();
    800027dc:	00003097          	auipc	ra,0x3
    800027e0:	79c080e7          	jalr	1948(ra) # 80005f78 <plic_claim>
    800027e4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027e6:	47a9                	li	a5,10
    800027e8:	02f50763          	beq	a0,a5,80002816 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027ec:	4785                	li	a5,1
    800027ee:	02f50963          	beq	a0,a5,80002820 <devintr+0x76>
    return 1;
    800027f2:	4505                	li	a0,1
    } else if(irq){
    800027f4:	d8f1                	beqz	s1,800027c8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027f6:	85a6                	mv	a1,s1
    800027f8:	00006517          	auipc	a0,0x6
    800027fc:	ae850513          	addi	a0,a0,-1304 # 800082e0 <states.1744+0x30>
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	e28080e7          	jalr	-472(ra) # 80000628 <printf>
      plic_complete(irq);
    80002808:	8526                	mv	a0,s1
    8000280a:	00003097          	auipc	ra,0x3
    8000280e:	792080e7          	jalr	1938(ra) # 80005f9c <plic_complete>
    return 1;
    80002812:	4505                	li	a0,1
    80002814:	bf55                	j	800027c8 <devintr+0x1e>
      uartintr();
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	222080e7          	jalr	546(ra) # 80000a38 <uartintr>
    8000281e:	b7ed                	j	80002808 <devintr+0x5e>
      virtio_disk_intr();
    80002820:	00004097          	auipc	ra,0x4
    80002824:	c16080e7          	jalr	-1002(ra) # 80006436 <virtio_disk_intr>
    80002828:	b7c5                	j	80002808 <devintr+0x5e>
    if(cpuid() == 0){
    8000282a:	fffff097          	auipc	ra,0xfffff
    8000282e:	1ec080e7          	jalr	492(ra) # 80001a16 <cpuid>
    80002832:	c901                	beqz	a0,80002842 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002834:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002838:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000283a:	14479073          	csrw	sip,a5
    return 2;
    8000283e:	4509                	li	a0,2
    80002840:	b761                	j	800027c8 <devintr+0x1e>
      clockintr();
    80002842:	00000097          	auipc	ra,0x0
    80002846:	f22080e7          	jalr	-222(ra) # 80002764 <clockintr>
    8000284a:	b7ed                	j	80002834 <devintr+0x8a>

000000008000284c <usertrap>:
{
    8000284c:	1101                	addi	sp,sp,-32
    8000284e:	ec06                	sd	ra,24(sp)
    80002850:	e822                	sd	s0,16(sp)
    80002852:	e426                	sd	s1,8(sp)
    80002854:	e04a                	sd	s2,0(sp)
    80002856:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002858:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000285c:	1007f793          	andi	a5,a5,256
    80002860:	e3bd                	bnez	a5,800028c6 <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002862:	00003797          	auipc	a5,0x3
    80002866:	60e78793          	addi	a5,a5,1550 # 80005e70 <kernelvec>
    8000286a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000286e:	fffff097          	auipc	ra,0xfffff
    80002872:	1d4080e7          	jalr	468(ra) # 80001a42 <myproc>
    80002876:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002878:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000287a:	14102773          	csrr	a4,sepc
    8000287e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002880:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002884:	47a1                	li	a5,8
    80002886:	04f71e63          	bne	a4,a5,800028e2 <usertrap+0x96>
    if(p->killed)
    8000288a:	591c                	lw	a5,48(a0)
    8000288c:	e7a9                	bnez	a5,800028d6 <usertrap+0x8a>
    p->trapframe->epc += 4;
    8000288e:	6cb8                	ld	a4,88(s1)
    80002890:	6f1c                	ld	a5,24(a4)
    80002892:	0791                	addi	a5,a5,4
    80002894:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002896:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000289a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000289e:	10079073          	csrw	sstatus,a5
    syscall();
    800028a2:	00000097          	auipc	ra,0x0
    800028a6:	3fc080e7          	jalr	1020(ra) # 80002c9e <syscall>
  int which_dev = 0;
    800028aa:	4901                	li	s2,0
  if(p->killed)
    800028ac:	589c                	lw	a5,48(s1)
    800028ae:	18079a63          	bnez	a5,80002a42 <usertrap+0x1f6>
  usertrapret();
    800028b2:	00000097          	auipc	ra,0x0
    800028b6:	e14080e7          	jalr	-492(ra) # 800026c6 <usertrapret>
}
    800028ba:	60e2                	ld	ra,24(sp)
    800028bc:	6442                	ld	s0,16(sp)
    800028be:	64a2                	ld	s1,8(sp)
    800028c0:	6902                	ld	s2,0(sp)
    800028c2:	6105                	addi	sp,sp,32
    800028c4:	8082                	ret
    panic("usertrap: not from user mode");
    800028c6:	00006517          	auipc	a0,0x6
    800028ca:	a3a50513          	addi	a0,a0,-1478 # 80008300 <states.1744+0x50>
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	d08080e7          	jalr	-760(ra) # 800005d6 <panic>
      exit(-1);
    800028d6:	557d                	li	a0,-1
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	842080e7          	jalr	-1982(ra) # 8000211a <exit>
    800028e0:	b77d                	j	8000288e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	ec8080e7          	jalr	-312(ra) # 800027aa <devintr>
    800028ea:	892a                	mv	s2,a0
    800028ec:	10050c63          	beqz	a0,80002a04 <usertrap+0x1b8>
    if (which_dev == 2 && p->ticks > 0 && p->flag) {
    800028f0:	4789                	li	a5,2
    800028f2:	faf51de3          	bne	a0,a5,800028ac <usertrap+0x60>
    800028f6:	1684a783          	lw	a5,360(s1)
    800028fa:	00f05e63          	blez	a5,80002916 <usertrap+0xca>
    800028fe:	1804a703          	lw	a4,384(s1)
    80002902:	cb11                	beqz	a4,80002916 <usertrap+0xca>
      p->ticked++;
    80002904:	16c4a703          	lw	a4,364(s1)
    80002908:	2705                	addiw	a4,a4,1
    8000290a:	0007069b          	sext.w	a3,a4
      if (p->ticked == p->ticks) {
    8000290e:	00d78d63          	beq	a5,a3,80002928 <usertrap+0xdc>
      p->ticked++;
    80002912:	16e4a623          	sw	a4,364(s1)
  if(p->killed)
    80002916:	589c                	lw	a5,48(s1)
    80002918:	12078d63          	beqz	a5,80002a52 <usertrap+0x206>
    exit(-1);
    8000291c:	557d                	li	a0,-1
    8000291e:	fffff097          	auipc	ra,0xfffff
    80002922:	7fc080e7          	jalr	2044(ra) # 8000211a <exit>
  if(which_dev == 2)
    80002926:	a235                	j	80002a52 <usertrap+0x206>
        p->ticked = 0;
    80002928:	1604a623          	sw	zero,364(s1)
        p->last_epc = p->trapframe->epc;
    8000292c:	6cbc                	ld	a5,88(s1)
    8000292e:	6f98                	ld	a4,24(a5)
    80002930:	16e4bc23          	sd	a4,376(s1)
        p->trapframe->epc = (uint64)(p->handler);
    80002934:	1704b703          	ld	a4,368(s1)
    80002938:	ef98                	sd	a4,24(a5)
        p->flag = 0;
    8000293a:	1804a023          	sw	zero,384(s1)
        p->ra = p->trapframe->ra;
    8000293e:	6cbc                	ld	a5,88(s1)
    80002940:	7798                	ld	a4,40(a5)
    80002942:	18e4b423          	sd	a4,392(s1)
        p->sp = p->trapframe->sp;
    80002946:	7b98                	ld	a4,48(a5)
    80002948:	18e4b823          	sd	a4,400(s1)
        p->gp = p->trapframe->gp;
    8000294c:	7f98                	ld	a4,56(a5)
    8000294e:	18e4bc23          	sd	a4,408(s1)
        p->tp = p->trapframe->tp;
    80002952:	63b8                	ld	a4,64(a5)
    80002954:	1ae4b023          	sd	a4,416(s1)
        p->t0 = p->trapframe->t0;
    80002958:	67b8                	ld	a4,72(a5)
    8000295a:	1ae4b423          	sd	a4,424(s1)
        p->t1 = p->trapframe->t1;
    8000295e:	6bb8                	ld	a4,80(a5)
    80002960:	1ae4b823          	sd	a4,432(s1)
        p->t2 = p->trapframe->t2;
    80002964:	6fb8                	ld	a4,88(a5)
    80002966:	1ae4bc23          	sd	a4,440(s1)
        p->s0 = p->trapframe->s0;
    8000296a:	73b8                	ld	a4,96(a5)
    8000296c:	1ce4b023          	sd	a4,448(s1)
        p->s1 = p->trapframe->s1;
    80002970:	77b8                	ld	a4,104(a5)
    80002972:	1ce4b423          	sd	a4,456(s1)
        p->s2 = p->trapframe->s2;
    80002976:	7bd8                	ld	a4,176(a5)
    80002978:	20e4b823          	sd	a4,528(s1)
        p->s3 = p->trapframe->s3;
    8000297c:	7fd8                	ld	a4,184(a5)
    8000297e:	20e4bc23          	sd	a4,536(s1)
        p->s4 = p->trapframe->s4;
    80002982:	63f8                	ld	a4,192(a5)
    80002984:	22e4b023          	sd	a4,544(s1)
        p->s5 = p->trapframe->s5;
    80002988:	67f8                	ld	a4,200(a5)
    8000298a:	22e4b423          	sd	a4,552(s1)
        p->s6 = p->trapframe->s6;
    8000298e:	6bf8                	ld	a4,208(a5)
    80002990:	22e4b823          	sd	a4,560(s1)
        p->s7 = p->trapframe->s7;
    80002994:	6ff8                	ld	a4,216(a5)
    80002996:	22e4bc23          	sd	a4,568(s1)
        p->s8 = p->trapframe->s8;
    8000299a:	73f8                	ld	a4,224(a5)
    8000299c:	24e4b023          	sd	a4,576(s1)
        p->s9 = p->trapframe->s9;
    800029a0:	77f8                	ld	a4,232(a5)
    800029a2:	24e4b423          	sd	a4,584(s1)
        p->s10 = p->trapframe->s10;
    800029a6:	7bf8                	ld	a4,240(a5)
    800029a8:	24e4b823          	sd	a4,592(s1)
        p->s11 = p->trapframe->s11;
    800029ac:	7ff8                	ld	a4,248(a5)
    800029ae:	24e4bc23          	sd	a4,600(s1)
        p->a0 = p->trapframe->a0;
    800029b2:	7bb8                	ld	a4,112(a5)
    800029b4:	1ce4b823          	sd	a4,464(s1)
        p->a1 = p->trapframe->a1;
    800029b8:	7fb8                	ld	a4,120(a5)
    800029ba:	1ce4bc23          	sd	a4,472(s1)
        p->a2 = p->trapframe->a2;
    800029be:	63d8                	ld	a4,128(a5)
    800029c0:	1ee4b023          	sd	a4,480(s1)
        p->a3 = p->trapframe->a3;
    800029c4:	67d8                	ld	a4,136(a5)
    800029c6:	1ee4b423          	sd	a4,488(s1)
        p->a4 = p->trapframe->a4;
    800029ca:	6bd8                	ld	a4,144(a5)
    800029cc:	1ee4b823          	sd	a4,496(s1)
        p->a5 = p->trapframe->a5;
    800029d0:	6fd8                	ld	a4,152(a5)
    800029d2:	1ee4bc23          	sd	a4,504(s1)
        p->a6 = p->trapframe->a6;
    800029d6:	73d8                	ld	a4,160(a5)
    800029d8:	20e4b023          	sd	a4,512(s1)
        p->a7 = p->trapframe->a7;
    800029dc:	77d8                	ld	a4,168(a5)
    800029de:	20e4b423          	sd	a4,520(s1)
        p->t3 = p->trapframe->t3;
    800029e2:	1007b703          	ld	a4,256(a5)
    800029e6:	26e4b023          	sd	a4,608(s1)
        p->t4 = p->trapframe->t4;
    800029ea:	1087b703          	ld	a4,264(a5)
    800029ee:	26e4b423          	sd	a4,616(s1)
        p->t5 = p->trapframe->t5;
    800029f2:	1107b703          	ld	a4,272(a5)
    800029f6:	26e4b823          	sd	a4,624(s1)
        p->t6 = p->trapframe->t6;
    800029fa:	1187b783          	ld	a5,280(a5)
    800029fe:	26f4bc23          	sd	a5,632(s1)
    80002a02:	bf11                	j	80002916 <usertrap+0xca>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a04:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a08:	5c90                	lw	a2,56(s1)
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	91650513          	addi	a0,a0,-1770 # 80008320 <states.1744+0x70>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	c16080e7          	jalr	-1002(ra) # 80000628 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a1e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	92e50513          	addi	a0,a0,-1746 # 80008350 <states.1744+0xa0>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	bfe080e7          	jalr	-1026(ra) # 80000628 <printf>
    p->killed = 1;
    80002a32:	4785                	li	a5,1
    80002a34:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002a36:	557d                	li	a0,-1
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	6e2080e7          	jalr	1762(ra) # 8000211a <exit>
  if(which_dev == 2)
    80002a40:	bd8d                	j	800028b2 <usertrap+0x66>
    exit(-1);
    80002a42:	557d                	li	a0,-1
    80002a44:	fffff097          	auipc	ra,0xfffff
    80002a48:	6d6080e7          	jalr	1750(ra) # 8000211a <exit>
  if(which_dev == 2)
    80002a4c:	4789                	li	a5,2
    80002a4e:	e6f912e3          	bne	s2,a5,800028b2 <usertrap+0x66>
    yield();
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	7d2080e7          	jalr	2002(ra) # 80002224 <yield>
    80002a5a:	bda1                	j	800028b2 <usertrap+0x66>

0000000080002a5c <kerneltrap>:
{
    80002a5c:	7179                	addi	sp,sp,-48
    80002a5e:	f406                	sd	ra,40(sp)
    80002a60:	f022                	sd	s0,32(sp)
    80002a62:	ec26                	sd	s1,24(sp)
    80002a64:	e84a                	sd	s2,16(sp)
    80002a66:	e44e                	sd	s3,8(sp)
    80002a68:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a6a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a72:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a76:	1004f793          	andi	a5,s1,256
    80002a7a:	cb85                	beqz	a5,80002aaa <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a7c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a80:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a82:	ef85                	bnez	a5,80002aba <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a84:	00000097          	auipc	ra,0x0
    80002a88:	d26080e7          	jalr	-730(ra) # 800027aa <devintr>
    80002a8c:	cd1d                	beqz	a0,80002aca <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002a8e:	4789                	li	a5,2
    80002a90:	06f50a63          	beq	a0,a5,80002b04 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a94:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a98:	10049073          	csrw	sstatus,s1
}
    80002a9c:	70a2                	ld	ra,40(sp)
    80002a9e:	7402                	ld	s0,32(sp)
    80002aa0:	64e2                	ld	s1,24(sp)
    80002aa2:	6942                	ld	s2,16(sp)
    80002aa4:	69a2                	ld	s3,8(sp)
    80002aa6:	6145                	addi	sp,sp,48
    80002aa8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	8c650513          	addi	a0,a0,-1850 # 80008370 <states.1744+0xc0>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	b24080e7          	jalr	-1244(ra) # 800005d6 <panic>
    panic("kerneltrap: interrupts enabled");
    80002aba:	00006517          	auipc	a0,0x6
    80002abe:	8de50513          	addi	a0,a0,-1826 # 80008398 <states.1744+0xe8>
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	b14080e7          	jalr	-1260(ra) # 800005d6 <panic>
    printf("scause %p\n", scause);
    80002aca:	85ce                	mv	a1,s3
    80002acc:	00006517          	auipc	a0,0x6
    80002ad0:	8ec50513          	addi	a0,a0,-1812 # 800083b8 <states.1744+0x108>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	b54080e7          	jalr	-1196(ra) # 80000628 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002adc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ae0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	8e450513          	addi	a0,a0,-1820 # 800083c8 <states.1744+0x118>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	b3c080e7          	jalr	-1220(ra) # 80000628 <printf>
    panic("kerneltrap");
    80002af4:	00006517          	auipc	a0,0x6
    80002af8:	8ec50513          	addi	a0,a0,-1812 # 800083e0 <states.1744+0x130>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	ada080e7          	jalr	-1318(ra) # 800005d6 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING) {
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	f3e080e7          	jalr	-194(ra) # 80001a42 <myproc>
    80002b0c:	d541                	beqz	a0,80002a94 <kerneltrap+0x38>
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	f34080e7          	jalr	-204(ra) # 80001a42 <myproc>
    80002b16:	4d18                	lw	a4,24(a0)
    80002b18:	478d                	li	a5,3
    80002b1a:	f6f71de3          	bne	a4,a5,80002a94 <kerneltrap+0x38>
    yield();
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	706080e7          	jalr	1798(ra) # 80002224 <yield>
    80002b26:	b7bd                	j	80002a94 <kerneltrap+0x38>

0000000080002b28 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	1000                	addi	s0,sp,32
    80002b32:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	f0e080e7          	jalr	-242(ra) # 80001a42 <myproc>
  switch (n) {
    80002b3c:	4795                	li	a5,5
    80002b3e:	0497e163          	bltu	a5,s1,80002b80 <argraw+0x58>
    80002b42:	048a                	slli	s1,s1,0x2
    80002b44:	00006717          	auipc	a4,0x6
    80002b48:	8d470713          	addi	a4,a4,-1836 # 80008418 <states.1744+0x168>
    80002b4c:	94ba                	add	s1,s1,a4
    80002b4e:	409c                	lw	a5,0(s1)
    80002b50:	97ba                	add	a5,a5,a4
    80002b52:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b54:	6d3c                	ld	a5,88(a0)
    80002b56:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b58:	60e2                	ld	ra,24(sp)
    80002b5a:	6442                	ld	s0,16(sp)
    80002b5c:	64a2                	ld	s1,8(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret
    return p->trapframe->a1;
    80002b62:	6d3c                	ld	a5,88(a0)
    80002b64:	7fa8                	ld	a0,120(a5)
    80002b66:	bfcd                	j	80002b58 <argraw+0x30>
    return p->trapframe->a2;
    80002b68:	6d3c                	ld	a5,88(a0)
    80002b6a:	63c8                	ld	a0,128(a5)
    80002b6c:	b7f5                	j	80002b58 <argraw+0x30>
    return p->trapframe->a3;
    80002b6e:	6d3c                	ld	a5,88(a0)
    80002b70:	67c8                	ld	a0,136(a5)
    80002b72:	b7dd                	j	80002b58 <argraw+0x30>
    return p->trapframe->a4;
    80002b74:	6d3c                	ld	a5,88(a0)
    80002b76:	6bc8                	ld	a0,144(a5)
    80002b78:	b7c5                	j	80002b58 <argraw+0x30>
    return p->trapframe->a5;
    80002b7a:	6d3c                	ld	a5,88(a0)
    80002b7c:	6fc8                	ld	a0,152(a5)
    80002b7e:	bfe9                	j	80002b58 <argraw+0x30>
  panic("argraw");
    80002b80:	00006517          	auipc	a0,0x6
    80002b84:	87050513          	addi	a0,a0,-1936 # 800083f0 <states.1744+0x140>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	a4e080e7          	jalr	-1458(ra) # 800005d6 <panic>

0000000080002b90 <fetchaddr>:
{
    80002b90:	1101                	addi	sp,sp,-32
    80002b92:	ec06                	sd	ra,24(sp)
    80002b94:	e822                	sd	s0,16(sp)
    80002b96:	e426                	sd	s1,8(sp)
    80002b98:	e04a                	sd	s2,0(sp)
    80002b9a:	1000                	addi	s0,sp,32
    80002b9c:	84aa                	mv	s1,a0
    80002b9e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	ea2080e7          	jalr	-350(ra) # 80001a42 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ba8:	653c                	ld	a5,72(a0)
    80002baa:	02f4f863          	bgeu	s1,a5,80002bda <fetchaddr+0x4a>
    80002bae:	00848713          	addi	a4,s1,8
    80002bb2:	02e7e663          	bltu	a5,a4,80002bde <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bb6:	46a1                	li	a3,8
    80002bb8:	8626                	mv	a2,s1
    80002bba:	85ca                	mv	a1,s2
    80002bbc:	6928                	ld	a0,80(a0)
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	c04080e7          	jalr	-1020(ra) # 800017c2 <copyin>
    80002bc6:	00a03533          	snez	a0,a0
    80002bca:	40a00533          	neg	a0,a0
}
    80002bce:	60e2                	ld	ra,24(sp)
    80002bd0:	6442                	ld	s0,16(sp)
    80002bd2:	64a2                	ld	s1,8(sp)
    80002bd4:	6902                	ld	s2,0(sp)
    80002bd6:	6105                	addi	sp,sp,32
    80002bd8:	8082                	ret
    return -1;
    80002bda:	557d                	li	a0,-1
    80002bdc:	bfcd                	j	80002bce <fetchaddr+0x3e>
    80002bde:	557d                	li	a0,-1
    80002be0:	b7fd                	j	80002bce <fetchaddr+0x3e>

0000000080002be2 <fetchstr>:
{
    80002be2:	7179                	addi	sp,sp,-48
    80002be4:	f406                	sd	ra,40(sp)
    80002be6:	f022                	sd	s0,32(sp)
    80002be8:	ec26                	sd	s1,24(sp)
    80002bea:	e84a                	sd	s2,16(sp)
    80002bec:	e44e                	sd	s3,8(sp)
    80002bee:	1800                	addi	s0,sp,48
    80002bf0:	892a                	mv	s2,a0
    80002bf2:	84ae                	mv	s1,a1
    80002bf4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	e4c080e7          	jalr	-436(ra) # 80001a42 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bfe:	86ce                	mv	a3,s3
    80002c00:	864a                	mv	a2,s2
    80002c02:	85a6                	mv	a1,s1
    80002c04:	6928                	ld	a0,80(a0)
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	c48080e7          	jalr	-952(ra) # 8000184e <copyinstr>
  if(err < 0)
    80002c0e:	00054763          	bltz	a0,80002c1c <fetchstr+0x3a>
  return strlen(buf);
    80002c12:	8526                	mv	a0,s1
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	2e4080e7          	jalr	740(ra) # 80000ef8 <strlen>
}
    80002c1c:	70a2                	ld	ra,40(sp)
    80002c1e:	7402                	ld	s0,32(sp)
    80002c20:	64e2                	ld	s1,24(sp)
    80002c22:	6942                	ld	s2,16(sp)
    80002c24:	69a2                	ld	s3,8(sp)
    80002c26:	6145                	addi	sp,sp,48
    80002c28:	8082                	ret

0000000080002c2a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	e426                	sd	s1,8(sp)
    80002c32:	1000                	addi	s0,sp,32
    80002c34:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	ef2080e7          	jalr	-270(ra) # 80002b28 <argraw>
    80002c3e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c40:	4501                	li	a0,0
    80002c42:	60e2                	ld	ra,24(sp)
    80002c44:	6442                	ld	s0,16(sp)
    80002c46:	64a2                	ld	s1,8(sp)
    80002c48:	6105                	addi	sp,sp,32
    80002c4a:	8082                	ret

0000000080002c4c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c4c:	1101                	addi	sp,sp,-32
    80002c4e:	ec06                	sd	ra,24(sp)
    80002c50:	e822                	sd	s0,16(sp)
    80002c52:	e426                	sd	s1,8(sp)
    80002c54:	1000                	addi	s0,sp,32
    80002c56:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c58:	00000097          	auipc	ra,0x0
    80002c5c:	ed0080e7          	jalr	-304(ra) # 80002b28 <argraw>
    80002c60:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c62:	4501                	li	a0,0
    80002c64:	60e2                	ld	ra,24(sp)
    80002c66:	6442                	ld	s0,16(sp)
    80002c68:	64a2                	ld	s1,8(sp)
    80002c6a:	6105                	addi	sp,sp,32
    80002c6c:	8082                	ret

0000000080002c6e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c6e:	1101                	addi	sp,sp,-32
    80002c70:	ec06                	sd	ra,24(sp)
    80002c72:	e822                	sd	s0,16(sp)
    80002c74:	e426                	sd	s1,8(sp)
    80002c76:	e04a                	sd	s2,0(sp)
    80002c78:	1000                	addi	s0,sp,32
    80002c7a:	84ae                	mv	s1,a1
    80002c7c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	eaa080e7          	jalr	-342(ra) # 80002b28 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c86:	864a                	mv	a2,s2
    80002c88:	85a6                	mv	a1,s1
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	f58080e7          	jalr	-168(ra) # 80002be2 <fetchstr>
}
    80002c92:	60e2                	ld	ra,24(sp)
    80002c94:	6442                	ld	s0,16(sp)
    80002c96:	64a2                	ld	s1,8(sp)
    80002c98:	6902                	ld	s2,0(sp)
    80002c9a:	6105                	addi	sp,sp,32
    80002c9c:	8082                	ret

0000000080002c9e <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002c9e:	1101                	addi	sp,sp,-32
    80002ca0:	ec06                	sd	ra,24(sp)
    80002ca2:	e822                	sd	s0,16(sp)
    80002ca4:	e426                	sd	s1,8(sp)
    80002ca6:	e04a                	sd	s2,0(sp)
    80002ca8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	d98080e7          	jalr	-616(ra) # 80001a42 <myproc>
    80002cb2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cb4:	05853903          	ld	s2,88(a0)
    80002cb8:	0a893783          	ld	a5,168(s2)
    80002cbc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cc0:	37fd                	addiw	a5,a5,-1
    80002cc2:	4759                	li	a4,22
    80002cc4:	00f76f63          	bltu	a4,a5,80002ce2 <syscall+0x44>
    80002cc8:	00369713          	slli	a4,a3,0x3
    80002ccc:	00005797          	auipc	a5,0x5
    80002cd0:	76478793          	addi	a5,a5,1892 # 80008430 <syscalls>
    80002cd4:	97ba                	add	a5,a5,a4
    80002cd6:	639c                	ld	a5,0(a5)
    80002cd8:	c789                	beqz	a5,80002ce2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cda:	9782                	jalr	a5
    80002cdc:	06a93823          	sd	a0,112(s2)
    80002ce0:	a839                	j	80002cfe <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ce2:	15848613          	addi	a2,s1,344
    80002ce6:	5c8c                	lw	a1,56(s1)
    80002ce8:	00005517          	auipc	a0,0x5
    80002cec:	71050513          	addi	a0,a0,1808 # 800083f8 <states.1744+0x148>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	938080e7          	jalr	-1736(ra) # 80000628 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cf8:	6cbc                	ld	a5,88(s1)
    80002cfa:	577d                	li	a4,-1
    80002cfc:	fbb8                	sd	a4,112(a5)
  }
}
    80002cfe:	60e2                	ld	ra,24(sp)
    80002d00:	6442                	ld	s0,16(sp)
    80002d02:	64a2                	ld	s1,8(sp)
    80002d04:	6902                	ld	s2,0(sp)
    80002d06:	6105                	addi	sp,sp,32
    80002d08:	8082                	ret

0000000080002d0a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d0a:	1101                	addi	sp,sp,-32
    80002d0c:	ec06                	sd	ra,24(sp)
    80002d0e:	e822                	sd	s0,16(sp)
    80002d10:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d12:	fec40593          	addi	a1,s0,-20
    80002d16:	4501                	li	a0,0
    80002d18:	00000097          	auipc	ra,0x0
    80002d1c:	f12080e7          	jalr	-238(ra) # 80002c2a <argint>
    return -1;
    80002d20:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d22:	00054963          	bltz	a0,80002d34 <sys_exit+0x2a>
  exit(n);
    80002d26:	fec42503          	lw	a0,-20(s0)
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	3f0080e7          	jalr	1008(ra) # 8000211a <exit>
  return 0;  // not reached
    80002d32:	4781                	li	a5,0
}
    80002d34:	853e                	mv	a0,a5
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d3e:	1141                	addi	sp,sp,-16
    80002d40:	e406                	sd	ra,8(sp)
    80002d42:	e022                	sd	s0,0(sp)
    80002d44:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	cfc080e7          	jalr	-772(ra) # 80001a42 <myproc>
}
    80002d4e:	5d08                	lw	a0,56(a0)
    80002d50:	60a2                	ld	ra,8(sp)
    80002d52:	6402                	ld	s0,0(sp)
    80002d54:	0141                	addi	sp,sp,16
    80002d56:	8082                	ret

0000000080002d58 <sys_fork>:

uint64
sys_fork(void)
{
    80002d58:	1141                	addi	sp,sp,-16
    80002d5a:	e406                	sd	ra,8(sp)
    80002d5c:	e022                	sd	s0,0(sp)
    80002d5e:	0800                	addi	s0,sp,16
  return fork();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	0b4080e7          	jalr	180(ra) # 80001e14 <fork>
}
    80002d68:	60a2                	ld	ra,8(sp)
    80002d6a:	6402                	ld	s0,0(sp)
    80002d6c:	0141                	addi	sp,sp,16
    80002d6e:	8082                	ret

0000000080002d70 <sys_wait>:

uint64
sys_wait(void)
{
    80002d70:	1101                	addi	sp,sp,-32
    80002d72:	ec06                	sd	ra,24(sp)
    80002d74:	e822                	sd	s0,16(sp)
    80002d76:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d78:	fe840593          	addi	a1,s0,-24
    80002d7c:	4501                	li	a0,0
    80002d7e:	00000097          	auipc	ra,0x0
    80002d82:	ece080e7          	jalr	-306(ra) # 80002c4c <argaddr>
    80002d86:	87aa                	mv	a5,a0
    return -1;
    80002d88:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d8a:	0007c863          	bltz	a5,80002d9a <sys_wait+0x2a>
  return wait(p);
    80002d8e:	fe843503          	ld	a0,-24(s0)
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	54c080e7          	jalr	1356(ra) # 800022de <wait>
}
    80002d9a:	60e2                	ld	ra,24(sp)
    80002d9c:	6442                	ld	s0,16(sp)
    80002d9e:	6105                	addi	sp,sp,32
    80002da0:	8082                	ret

0000000080002da2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002da2:	7179                	addi	sp,sp,-48
    80002da4:	f406                	sd	ra,40(sp)
    80002da6:	f022                	sd	s0,32(sp)
    80002da8:	ec26                	sd	s1,24(sp)
    80002daa:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dac:	fdc40593          	addi	a1,s0,-36
    80002db0:	4501                	li	a0,0
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	e78080e7          	jalr	-392(ra) # 80002c2a <argint>
    80002dba:	87aa                	mv	a5,a0
    return -1;
    80002dbc:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002dbe:	0207c063          	bltz	a5,80002dde <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	c80080e7          	jalr	-896(ra) # 80001a42 <myproc>
    80002dca:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002dcc:	fdc42503          	lw	a0,-36(s0)
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	fd0080e7          	jalr	-48(ra) # 80001da0 <growproc>
    80002dd8:	00054863          	bltz	a0,80002de8 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ddc:	8526                	mv	a0,s1
}
    80002dde:	70a2                	ld	ra,40(sp)
    80002de0:	7402                	ld	s0,32(sp)
    80002de2:	64e2                	ld	s1,24(sp)
    80002de4:	6145                	addi	sp,sp,48
    80002de6:	8082                	ret
    return -1;
    80002de8:	557d                	li	a0,-1
    80002dea:	bfd5                	j	80002dde <sys_sbrk+0x3c>

0000000080002dec <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dec:	7139                	addi	sp,sp,-64
    80002dee:	fc06                	sd	ra,56(sp)
    80002df0:	f822                	sd	s0,48(sp)
    80002df2:	f426                	sd	s1,40(sp)
    80002df4:	f04a                	sd	s2,32(sp)
    80002df6:	ec4e                	sd	s3,24(sp)
    80002df8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002dfa:	fcc40593          	addi	a1,s0,-52
    80002dfe:	4501                	li	a0,0
    80002e00:	00000097          	auipc	ra,0x0
    80002e04:	e2a080e7          	jalr	-470(ra) # 80002c2a <argint>
    return -1;
    80002e08:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e0a:	06054963          	bltz	a0,80002e7c <sys_sleep+0x90>
  acquire(&tickslock);
    80002e0e:	00019517          	auipc	a0,0x19
    80002e12:	f5a50513          	addi	a0,a0,-166 # 8001bd68 <tickslock>
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	e5e080e7          	jalr	-418(ra) # 80000c74 <acquire>
  ticks0 = ticks;
    80002e1e:	00006917          	auipc	s2,0x6
    80002e22:	20292903          	lw	s2,514(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002e26:	fcc42783          	lw	a5,-52(s0)
    80002e2a:	cf85                	beqz	a5,80002e62 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e2c:	00019997          	auipc	s3,0x19
    80002e30:	f3c98993          	addi	s3,s3,-196 # 8001bd68 <tickslock>
    80002e34:	00006497          	auipc	s1,0x6
    80002e38:	1ec48493          	addi	s1,s1,492 # 80009020 <ticks>
    if(myproc()->killed){
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	c06080e7          	jalr	-1018(ra) # 80001a42 <myproc>
    80002e44:	591c                	lw	a5,48(a0)
    80002e46:	e3b9                	bnez	a5,80002e8c <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002e48:	85ce                	mv	a1,s3
    80002e4a:	8526                	mv	a0,s1
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	414080e7          	jalr	1044(ra) # 80002260 <sleep>
  while(ticks - ticks0 < n){
    80002e54:	409c                	lw	a5,0(s1)
    80002e56:	412787bb          	subw	a5,a5,s2
    80002e5a:	fcc42703          	lw	a4,-52(s0)
    80002e5e:	fce7efe3          	bltu	a5,a4,80002e3c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e62:	00019517          	auipc	a0,0x19
    80002e66:	f0650513          	addi	a0,a0,-250 # 8001bd68 <tickslock>
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	ebe080e7          	jalr	-322(ra) # 80000d28 <release>
  backtrace();
    80002e72:	ffffd097          	auipc	ra,0xffffd
    80002e76:	708080e7          	jalr	1800(ra) # 8000057a <backtrace>
  return 0;
    80002e7a:	4781                	li	a5,0
}
    80002e7c:	853e                	mv	a0,a5
    80002e7e:	70e2                	ld	ra,56(sp)
    80002e80:	7442                	ld	s0,48(sp)
    80002e82:	74a2                	ld	s1,40(sp)
    80002e84:	7902                	ld	s2,32(sp)
    80002e86:	69e2                	ld	s3,24(sp)
    80002e88:	6121                	addi	sp,sp,64
    80002e8a:	8082                	ret
      release(&tickslock);
    80002e8c:	00019517          	auipc	a0,0x19
    80002e90:	edc50513          	addi	a0,a0,-292 # 8001bd68 <tickslock>
    80002e94:	ffffe097          	auipc	ra,0xffffe
    80002e98:	e94080e7          	jalr	-364(ra) # 80000d28 <release>
      return -1;
    80002e9c:	57fd                	li	a5,-1
    80002e9e:	bff9                	j	80002e7c <sys_sleep+0x90>

0000000080002ea0 <sys_kill>:

uint64
sys_kill(void)
{
    80002ea0:	1101                	addi	sp,sp,-32
    80002ea2:	ec06                	sd	ra,24(sp)
    80002ea4:	e822                	sd	s0,16(sp)
    80002ea6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ea8:	fec40593          	addi	a1,s0,-20
    80002eac:	4501                	li	a0,0
    80002eae:	00000097          	auipc	ra,0x0
    80002eb2:	d7c080e7          	jalr	-644(ra) # 80002c2a <argint>
    80002eb6:	87aa                	mv	a5,a0
    return -1;
    80002eb8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002eba:	0007c863          	bltz	a5,80002eca <sys_kill+0x2a>
  return kill(pid);
    80002ebe:	fec42503          	lw	a0,-20(s0)
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	58e080e7          	jalr	1422(ra) # 80002450 <kill>
}
    80002eca:	60e2                	ld	ra,24(sp)
    80002ecc:	6442                	ld	s0,16(sp)
    80002ece:	6105                	addi	sp,sp,32
    80002ed0:	8082                	ret

0000000080002ed2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ed2:	1101                	addi	sp,sp,-32
    80002ed4:	ec06                	sd	ra,24(sp)
    80002ed6:	e822                	sd	s0,16(sp)
    80002ed8:	e426                	sd	s1,8(sp)
    80002eda:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002edc:	00019517          	auipc	a0,0x19
    80002ee0:	e8c50513          	addi	a0,a0,-372 # 8001bd68 <tickslock>
    80002ee4:	ffffe097          	auipc	ra,0xffffe
    80002ee8:	d90080e7          	jalr	-624(ra) # 80000c74 <acquire>
  xticks = ticks;
    80002eec:	00006497          	auipc	s1,0x6
    80002ef0:	1344a483          	lw	s1,308(s1) # 80009020 <ticks>
  release(&tickslock);
    80002ef4:	00019517          	auipc	a0,0x19
    80002ef8:	e7450513          	addi	a0,a0,-396 # 8001bd68 <tickslock>
    80002efc:	ffffe097          	auipc	ra,0xffffe
    80002f00:	e2c080e7          	jalr	-468(ra) # 80000d28 <release>
  return xticks;
}
    80002f04:	02049513          	slli	a0,s1,0x20
    80002f08:	9101                	srli	a0,a0,0x20
    80002f0a:	60e2                	ld	ra,24(sp)
    80002f0c:	6442                	ld	s0,16(sp)
    80002f0e:	64a2                	ld	s1,8(sp)
    80002f10:	6105                	addi	sp,sp,32
    80002f12:	8082                	ret

0000000080002f14 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f14:	7179                	addi	sp,sp,-48
    80002f16:	f406                	sd	ra,40(sp)
    80002f18:	f022                	sd	s0,32(sp)
    80002f1a:	ec26                	sd	s1,24(sp)
    80002f1c:	e84a                	sd	s2,16(sp)
    80002f1e:	e44e                	sd	s3,8(sp)
    80002f20:	e052                	sd	s4,0(sp)
    80002f22:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f24:	00005597          	auipc	a1,0x5
    80002f28:	5cc58593          	addi	a1,a1,1484 # 800084f0 <syscalls+0xc0>
    80002f2c:	00019517          	auipc	a0,0x19
    80002f30:	e5450513          	addi	a0,a0,-428 # 8001bd80 <bcache>
    80002f34:	ffffe097          	auipc	ra,0xffffe
    80002f38:	cb0080e7          	jalr	-848(ra) # 80000be4 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f3c:	00021797          	auipc	a5,0x21
    80002f40:	e4478793          	addi	a5,a5,-444 # 80023d80 <bcache+0x8000>
    80002f44:	00021717          	auipc	a4,0x21
    80002f48:	0a470713          	addi	a4,a4,164 # 80023fe8 <bcache+0x8268>
    80002f4c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f50:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f54:	00019497          	auipc	s1,0x19
    80002f58:	e4448493          	addi	s1,s1,-444 # 8001bd98 <bcache+0x18>
    b->next = bcache.head.next;
    80002f5c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f5e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f60:	00005a17          	auipc	s4,0x5
    80002f64:	598a0a13          	addi	s4,s4,1432 # 800084f8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f68:	2b893783          	ld	a5,696(s2)
    80002f6c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f6e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f72:	85d2                	mv	a1,s4
    80002f74:	01048513          	addi	a0,s1,16
    80002f78:	00001097          	auipc	ra,0x1
    80002f7c:	4ac080e7          	jalr	1196(ra) # 80004424 <initsleeplock>
    bcache.head.next->prev = b;
    80002f80:	2b893783          	ld	a5,696(s2)
    80002f84:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f86:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f8a:	45848493          	addi	s1,s1,1112
    80002f8e:	fd349de3          	bne	s1,s3,80002f68 <binit+0x54>
  }
}
    80002f92:	70a2                	ld	ra,40(sp)
    80002f94:	7402                	ld	s0,32(sp)
    80002f96:	64e2                	ld	s1,24(sp)
    80002f98:	6942                	ld	s2,16(sp)
    80002f9a:	69a2                	ld	s3,8(sp)
    80002f9c:	6a02                	ld	s4,0(sp)
    80002f9e:	6145                	addi	sp,sp,48
    80002fa0:	8082                	ret

0000000080002fa2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fa2:	7179                	addi	sp,sp,-48
    80002fa4:	f406                	sd	ra,40(sp)
    80002fa6:	f022                	sd	s0,32(sp)
    80002fa8:	ec26                	sd	s1,24(sp)
    80002faa:	e84a                	sd	s2,16(sp)
    80002fac:	e44e                	sd	s3,8(sp)
    80002fae:	1800                	addi	s0,sp,48
    80002fb0:	89aa                	mv	s3,a0
    80002fb2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fb4:	00019517          	auipc	a0,0x19
    80002fb8:	dcc50513          	addi	a0,a0,-564 # 8001bd80 <bcache>
    80002fbc:	ffffe097          	auipc	ra,0xffffe
    80002fc0:	cb8080e7          	jalr	-840(ra) # 80000c74 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fc4:	00021497          	auipc	s1,0x21
    80002fc8:	0744b483          	ld	s1,116(s1) # 80024038 <bcache+0x82b8>
    80002fcc:	00021797          	auipc	a5,0x21
    80002fd0:	01c78793          	addi	a5,a5,28 # 80023fe8 <bcache+0x8268>
    80002fd4:	02f48f63          	beq	s1,a5,80003012 <bread+0x70>
    80002fd8:	873e                	mv	a4,a5
    80002fda:	a021                	j	80002fe2 <bread+0x40>
    80002fdc:	68a4                	ld	s1,80(s1)
    80002fde:	02e48a63          	beq	s1,a4,80003012 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fe2:	449c                	lw	a5,8(s1)
    80002fe4:	ff379ce3          	bne	a5,s3,80002fdc <bread+0x3a>
    80002fe8:	44dc                	lw	a5,12(s1)
    80002fea:	ff2799e3          	bne	a5,s2,80002fdc <bread+0x3a>
      b->refcnt++;
    80002fee:	40bc                	lw	a5,64(s1)
    80002ff0:	2785                	addiw	a5,a5,1
    80002ff2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ff4:	00019517          	auipc	a0,0x19
    80002ff8:	d8c50513          	addi	a0,a0,-628 # 8001bd80 <bcache>
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	d2c080e7          	jalr	-724(ra) # 80000d28 <release>
      acquiresleep(&b->lock);
    80003004:	01048513          	addi	a0,s1,16
    80003008:	00001097          	auipc	ra,0x1
    8000300c:	456080e7          	jalr	1110(ra) # 8000445e <acquiresleep>
      return b;
    80003010:	a8b9                	j	8000306e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003012:	00021497          	auipc	s1,0x21
    80003016:	01e4b483          	ld	s1,30(s1) # 80024030 <bcache+0x82b0>
    8000301a:	00021797          	auipc	a5,0x21
    8000301e:	fce78793          	addi	a5,a5,-50 # 80023fe8 <bcache+0x8268>
    80003022:	00f48863          	beq	s1,a5,80003032 <bread+0x90>
    80003026:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003028:	40bc                	lw	a5,64(s1)
    8000302a:	cf81                	beqz	a5,80003042 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000302c:	64a4                	ld	s1,72(s1)
    8000302e:	fee49de3          	bne	s1,a4,80003028 <bread+0x86>
  panic("bget: no buffers");
    80003032:	00005517          	auipc	a0,0x5
    80003036:	4ce50513          	addi	a0,a0,1230 # 80008500 <syscalls+0xd0>
    8000303a:	ffffd097          	auipc	ra,0xffffd
    8000303e:	59c080e7          	jalr	1436(ra) # 800005d6 <panic>
      b->dev = dev;
    80003042:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003046:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000304a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000304e:	4785                	li	a5,1
    80003050:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003052:	00019517          	auipc	a0,0x19
    80003056:	d2e50513          	addi	a0,a0,-722 # 8001bd80 <bcache>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	cce080e7          	jalr	-818(ra) # 80000d28 <release>
      acquiresleep(&b->lock);
    80003062:	01048513          	addi	a0,s1,16
    80003066:	00001097          	auipc	ra,0x1
    8000306a:	3f8080e7          	jalr	1016(ra) # 8000445e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000306e:	409c                	lw	a5,0(s1)
    80003070:	cb89                	beqz	a5,80003082 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003072:	8526                	mv	a0,s1
    80003074:	70a2                	ld	ra,40(sp)
    80003076:	7402                	ld	s0,32(sp)
    80003078:	64e2                	ld	s1,24(sp)
    8000307a:	6942                	ld	s2,16(sp)
    8000307c:	69a2                	ld	s3,8(sp)
    8000307e:	6145                	addi	sp,sp,48
    80003080:	8082                	ret
    virtio_disk_rw(b, 0);
    80003082:	4581                	li	a1,0
    80003084:	8526                	mv	a0,s1
    80003086:	00003097          	auipc	ra,0x3
    8000308a:	106080e7          	jalr	262(ra) # 8000618c <virtio_disk_rw>
    b->valid = 1;
    8000308e:	4785                	li	a5,1
    80003090:	c09c                	sw	a5,0(s1)
  return b;
    80003092:	b7c5                	j	80003072 <bread+0xd0>

0000000080003094 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	e426                	sd	s1,8(sp)
    8000309c:	1000                	addi	s0,sp,32
    8000309e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030a0:	0541                	addi	a0,a0,16
    800030a2:	00001097          	auipc	ra,0x1
    800030a6:	456080e7          	jalr	1110(ra) # 800044f8 <holdingsleep>
    800030aa:	cd01                	beqz	a0,800030c2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030ac:	4585                	li	a1,1
    800030ae:	8526                	mv	a0,s1
    800030b0:	00003097          	auipc	ra,0x3
    800030b4:	0dc080e7          	jalr	220(ra) # 8000618c <virtio_disk_rw>
}
    800030b8:	60e2                	ld	ra,24(sp)
    800030ba:	6442                	ld	s0,16(sp)
    800030bc:	64a2                	ld	s1,8(sp)
    800030be:	6105                	addi	sp,sp,32
    800030c0:	8082                	ret
    panic("bwrite");
    800030c2:	00005517          	auipc	a0,0x5
    800030c6:	45650513          	addi	a0,a0,1110 # 80008518 <syscalls+0xe8>
    800030ca:	ffffd097          	auipc	ra,0xffffd
    800030ce:	50c080e7          	jalr	1292(ra) # 800005d6 <panic>

00000000800030d2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030d2:	1101                	addi	sp,sp,-32
    800030d4:	ec06                	sd	ra,24(sp)
    800030d6:	e822                	sd	s0,16(sp)
    800030d8:	e426                	sd	s1,8(sp)
    800030da:	e04a                	sd	s2,0(sp)
    800030dc:	1000                	addi	s0,sp,32
    800030de:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030e0:	01050913          	addi	s2,a0,16
    800030e4:	854a                	mv	a0,s2
    800030e6:	00001097          	auipc	ra,0x1
    800030ea:	412080e7          	jalr	1042(ra) # 800044f8 <holdingsleep>
    800030ee:	c92d                	beqz	a0,80003160 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030f0:	854a                	mv	a0,s2
    800030f2:	00001097          	auipc	ra,0x1
    800030f6:	3c2080e7          	jalr	962(ra) # 800044b4 <releasesleep>

  acquire(&bcache.lock);
    800030fa:	00019517          	auipc	a0,0x19
    800030fe:	c8650513          	addi	a0,a0,-890 # 8001bd80 <bcache>
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	b72080e7          	jalr	-1166(ra) # 80000c74 <acquire>
  b->refcnt--;
    8000310a:	40bc                	lw	a5,64(s1)
    8000310c:	37fd                	addiw	a5,a5,-1
    8000310e:	0007871b          	sext.w	a4,a5
    80003112:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003114:	eb05                	bnez	a4,80003144 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003116:	68bc                	ld	a5,80(s1)
    80003118:	64b8                	ld	a4,72(s1)
    8000311a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000311c:	64bc                	ld	a5,72(s1)
    8000311e:	68b8                	ld	a4,80(s1)
    80003120:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003122:	00021797          	auipc	a5,0x21
    80003126:	c5e78793          	addi	a5,a5,-930 # 80023d80 <bcache+0x8000>
    8000312a:	2b87b703          	ld	a4,696(a5)
    8000312e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003130:	00021717          	auipc	a4,0x21
    80003134:	eb870713          	addi	a4,a4,-328 # 80023fe8 <bcache+0x8268>
    80003138:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000313a:	2b87b703          	ld	a4,696(a5)
    8000313e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003140:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003144:	00019517          	auipc	a0,0x19
    80003148:	c3c50513          	addi	a0,a0,-964 # 8001bd80 <bcache>
    8000314c:	ffffe097          	auipc	ra,0xffffe
    80003150:	bdc080e7          	jalr	-1060(ra) # 80000d28 <release>
}
    80003154:	60e2                	ld	ra,24(sp)
    80003156:	6442                	ld	s0,16(sp)
    80003158:	64a2                	ld	s1,8(sp)
    8000315a:	6902                	ld	s2,0(sp)
    8000315c:	6105                	addi	sp,sp,32
    8000315e:	8082                	ret
    panic("brelse");
    80003160:	00005517          	auipc	a0,0x5
    80003164:	3c050513          	addi	a0,a0,960 # 80008520 <syscalls+0xf0>
    80003168:	ffffd097          	auipc	ra,0xffffd
    8000316c:	46e080e7          	jalr	1134(ra) # 800005d6 <panic>

0000000080003170 <bpin>:

void
bpin(struct buf *b) {
    80003170:	1101                	addi	sp,sp,-32
    80003172:	ec06                	sd	ra,24(sp)
    80003174:	e822                	sd	s0,16(sp)
    80003176:	e426                	sd	s1,8(sp)
    80003178:	1000                	addi	s0,sp,32
    8000317a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000317c:	00019517          	auipc	a0,0x19
    80003180:	c0450513          	addi	a0,a0,-1020 # 8001bd80 <bcache>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	af0080e7          	jalr	-1296(ra) # 80000c74 <acquire>
  b->refcnt++;
    8000318c:	40bc                	lw	a5,64(s1)
    8000318e:	2785                	addiw	a5,a5,1
    80003190:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003192:	00019517          	auipc	a0,0x19
    80003196:	bee50513          	addi	a0,a0,-1042 # 8001bd80 <bcache>
    8000319a:	ffffe097          	auipc	ra,0xffffe
    8000319e:	b8e080e7          	jalr	-1138(ra) # 80000d28 <release>
}
    800031a2:	60e2                	ld	ra,24(sp)
    800031a4:	6442                	ld	s0,16(sp)
    800031a6:	64a2                	ld	s1,8(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret

00000000800031ac <bunpin>:

void
bunpin(struct buf *b) {
    800031ac:	1101                	addi	sp,sp,-32
    800031ae:	ec06                	sd	ra,24(sp)
    800031b0:	e822                	sd	s0,16(sp)
    800031b2:	e426                	sd	s1,8(sp)
    800031b4:	1000                	addi	s0,sp,32
    800031b6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031b8:	00019517          	auipc	a0,0x19
    800031bc:	bc850513          	addi	a0,a0,-1080 # 8001bd80 <bcache>
    800031c0:	ffffe097          	auipc	ra,0xffffe
    800031c4:	ab4080e7          	jalr	-1356(ra) # 80000c74 <acquire>
  b->refcnt--;
    800031c8:	40bc                	lw	a5,64(s1)
    800031ca:	37fd                	addiw	a5,a5,-1
    800031cc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ce:	00019517          	auipc	a0,0x19
    800031d2:	bb250513          	addi	a0,a0,-1102 # 8001bd80 <bcache>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	b52080e7          	jalr	-1198(ra) # 80000d28 <release>
}
    800031de:	60e2                	ld	ra,24(sp)
    800031e0:	6442                	ld	s0,16(sp)
    800031e2:	64a2                	ld	s1,8(sp)
    800031e4:	6105                	addi	sp,sp,32
    800031e6:	8082                	ret

00000000800031e8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031e8:	1101                	addi	sp,sp,-32
    800031ea:	ec06                	sd	ra,24(sp)
    800031ec:	e822                	sd	s0,16(sp)
    800031ee:	e426                	sd	s1,8(sp)
    800031f0:	e04a                	sd	s2,0(sp)
    800031f2:	1000                	addi	s0,sp,32
    800031f4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031f6:	00d5d59b          	srliw	a1,a1,0xd
    800031fa:	00021797          	auipc	a5,0x21
    800031fe:	2627a783          	lw	a5,610(a5) # 8002445c <sb+0x1c>
    80003202:	9dbd                	addw	a1,a1,a5
    80003204:	00000097          	auipc	ra,0x0
    80003208:	d9e080e7          	jalr	-610(ra) # 80002fa2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000320c:	0074f713          	andi	a4,s1,7
    80003210:	4785                	li	a5,1
    80003212:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003216:	14ce                	slli	s1,s1,0x33
    80003218:	90d9                	srli	s1,s1,0x36
    8000321a:	00950733          	add	a4,a0,s1
    8000321e:	05874703          	lbu	a4,88(a4)
    80003222:	00e7f6b3          	and	a3,a5,a4
    80003226:	c69d                	beqz	a3,80003254 <bfree+0x6c>
    80003228:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000322a:	94aa                	add	s1,s1,a0
    8000322c:	fff7c793          	not	a5,a5
    80003230:	8ff9                	and	a5,a5,a4
    80003232:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003236:	00001097          	auipc	ra,0x1
    8000323a:	100080e7          	jalr	256(ra) # 80004336 <log_write>
  brelse(bp);
    8000323e:	854a                	mv	a0,s2
    80003240:	00000097          	auipc	ra,0x0
    80003244:	e92080e7          	jalr	-366(ra) # 800030d2 <brelse>
}
    80003248:	60e2                	ld	ra,24(sp)
    8000324a:	6442                	ld	s0,16(sp)
    8000324c:	64a2                	ld	s1,8(sp)
    8000324e:	6902                	ld	s2,0(sp)
    80003250:	6105                	addi	sp,sp,32
    80003252:	8082                	ret
    panic("freeing free block");
    80003254:	00005517          	auipc	a0,0x5
    80003258:	2d450513          	addi	a0,a0,724 # 80008528 <syscalls+0xf8>
    8000325c:	ffffd097          	auipc	ra,0xffffd
    80003260:	37a080e7          	jalr	890(ra) # 800005d6 <panic>

0000000080003264 <balloc>:
{
    80003264:	711d                	addi	sp,sp,-96
    80003266:	ec86                	sd	ra,88(sp)
    80003268:	e8a2                	sd	s0,80(sp)
    8000326a:	e4a6                	sd	s1,72(sp)
    8000326c:	e0ca                	sd	s2,64(sp)
    8000326e:	fc4e                	sd	s3,56(sp)
    80003270:	f852                	sd	s4,48(sp)
    80003272:	f456                	sd	s5,40(sp)
    80003274:	f05a                	sd	s6,32(sp)
    80003276:	ec5e                	sd	s7,24(sp)
    80003278:	e862                	sd	s8,16(sp)
    8000327a:	e466                	sd	s9,8(sp)
    8000327c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000327e:	00021797          	auipc	a5,0x21
    80003282:	1c67a783          	lw	a5,454(a5) # 80024444 <sb+0x4>
    80003286:	cbd1                	beqz	a5,8000331a <balloc+0xb6>
    80003288:	8baa                	mv	s7,a0
    8000328a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000328c:	00021b17          	auipc	s6,0x21
    80003290:	1b4b0b13          	addi	s6,s6,436 # 80024440 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003294:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003296:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003298:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000329a:	6c89                	lui	s9,0x2
    8000329c:	a831                	j	800032b8 <balloc+0x54>
    brelse(bp);
    8000329e:	854a                	mv	a0,s2
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	e32080e7          	jalr	-462(ra) # 800030d2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032a8:	015c87bb          	addw	a5,s9,s5
    800032ac:	00078a9b          	sext.w	s5,a5
    800032b0:	004b2703          	lw	a4,4(s6)
    800032b4:	06eaf363          	bgeu	s5,a4,8000331a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032b8:	41fad79b          	sraiw	a5,s5,0x1f
    800032bc:	0137d79b          	srliw	a5,a5,0x13
    800032c0:	015787bb          	addw	a5,a5,s5
    800032c4:	40d7d79b          	sraiw	a5,a5,0xd
    800032c8:	01cb2583          	lw	a1,28(s6)
    800032cc:	9dbd                	addw	a1,a1,a5
    800032ce:	855e                	mv	a0,s7
    800032d0:	00000097          	auipc	ra,0x0
    800032d4:	cd2080e7          	jalr	-814(ra) # 80002fa2 <bread>
    800032d8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032da:	004b2503          	lw	a0,4(s6)
    800032de:	000a849b          	sext.w	s1,s5
    800032e2:	8662                	mv	a2,s8
    800032e4:	faa4fde3          	bgeu	s1,a0,8000329e <balloc+0x3a>
      m = 1 << (bi % 8);
    800032e8:	41f6579b          	sraiw	a5,a2,0x1f
    800032ec:	01d7d69b          	srliw	a3,a5,0x1d
    800032f0:	00c6873b          	addw	a4,a3,a2
    800032f4:	00777793          	andi	a5,a4,7
    800032f8:	9f95                	subw	a5,a5,a3
    800032fa:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032fe:	4037571b          	sraiw	a4,a4,0x3
    80003302:	00e906b3          	add	a3,s2,a4
    80003306:	0586c683          	lbu	a3,88(a3)
    8000330a:	00d7f5b3          	and	a1,a5,a3
    8000330e:	cd91                	beqz	a1,8000332a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003310:	2605                	addiw	a2,a2,1
    80003312:	2485                	addiw	s1,s1,1
    80003314:	fd4618e3          	bne	a2,s4,800032e4 <balloc+0x80>
    80003318:	b759                	j	8000329e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000331a:	00005517          	auipc	a0,0x5
    8000331e:	22650513          	addi	a0,a0,550 # 80008540 <syscalls+0x110>
    80003322:	ffffd097          	auipc	ra,0xffffd
    80003326:	2b4080e7          	jalr	692(ra) # 800005d6 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000332a:	974a                	add	a4,a4,s2
    8000332c:	8fd5                	or	a5,a5,a3
    8000332e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003332:	854a                	mv	a0,s2
    80003334:	00001097          	auipc	ra,0x1
    80003338:	002080e7          	jalr	2(ra) # 80004336 <log_write>
        brelse(bp);
    8000333c:	854a                	mv	a0,s2
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	d94080e7          	jalr	-620(ra) # 800030d2 <brelse>
  bp = bread(dev, bno);
    80003346:	85a6                	mv	a1,s1
    80003348:	855e                	mv	a0,s7
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	c58080e7          	jalr	-936(ra) # 80002fa2 <bread>
    80003352:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003354:	40000613          	li	a2,1024
    80003358:	4581                	li	a1,0
    8000335a:	05850513          	addi	a0,a0,88
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	a12080e7          	jalr	-1518(ra) # 80000d70 <memset>
  log_write(bp);
    80003366:	854a                	mv	a0,s2
    80003368:	00001097          	auipc	ra,0x1
    8000336c:	fce080e7          	jalr	-50(ra) # 80004336 <log_write>
  brelse(bp);
    80003370:	854a                	mv	a0,s2
    80003372:	00000097          	auipc	ra,0x0
    80003376:	d60080e7          	jalr	-672(ra) # 800030d2 <brelse>
}
    8000337a:	8526                	mv	a0,s1
    8000337c:	60e6                	ld	ra,88(sp)
    8000337e:	6446                	ld	s0,80(sp)
    80003380:	64a6                	ld	s1,72(sp)
    80003382:	6906                	ld	s2,64(sp)
    80003384:	79e2                	ld	s3,56(sp)
    80003386:	7a42                	ld	s4,48(sp)
    80003388:	7aa2                	ld	s5,40(sp)
    8000338a:	7b02                	ld	s6,32(sp)
    8000338c:	6be2                	ld	s7,24(sp)
    8000338e:	6c42                	ld	s8,16(sp)
    80003390:	6ca2                	ld	s9,8(sp)
    80003392:	6125                	addi	sp,sp,96
    80003394:	8082                	ret

0000000080003396 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003396:	7179                	addi	sp,sp,-48
    80003398:	f406                	sd	ra,40(sp)
    8000339a:	f022                	sd	s0,32(sp)
    8000339c:	ec26                	sd	s1,24(sp)
    8000339e:	e84a                	sd	s2,16(sp)
    800033a0:	e44e                	sd	s3,8(sp)
    800033a2:	e052                	sd	s4,0(sp)
    800033a4:	1800                	addi	s0,sp,48
    800033a6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033a8:	47ad                	li	a5,11
    800033aa:	04b7fe63          	bgeu	a5,a1,80003406 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033ae:	ff45849b          	addiw	s1,a1,-12
    800033b2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033b6:	0ff00793          	li	a5,255
    800033ba:	0ae7e363          	bltu	a5,a4,80003460 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033be:	08052583          	lw	a1,128(a0)
    800033c2:	c5ad                	beqz	a1,8000342c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033c4:	00092503          	lw	a0,0(s2)
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	bda080e7          	jalr	-1062(ra) # 80002fa2 <bread>
    800033d0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033d2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033d6:	02049593          	slli	a1,s1,0x20
    800033da:	9181                	srli	a1,a1,0x20
    800033dc:	058a                	slli	a1,a1,0x2
    800033de:	00b784b3          	add	s1,a5,a1
    800033e2:	0004a983          	lw	s3,0(s1)
    800033e6:	04098d63          	beqz	s3,80003440 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033ea:	8552                	mv	a0,s4
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	ce6080e7          	jalr	-794(ra) # 800030d2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033f4:	854e                	mv	a0,s3
    800033f6:	70a2                	ld	ra,40(sp)
    800033f8:	7402                	ld	s0,32(sp)
    800033fa:	64e2                	ld	s1,24(sp)
    800033fc:	6942                	ld	s2,16(sp)
    800033fe:	69a2                	ld	s3,8(sp)
    80003400:	6a02                	ld	s4,0(sp)
    80003402:	6145                	addi	sp,sp,48
    80003404:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003406:	02059493          	slli	s1,a1,0x20
    8000340a:	9081                	srli	s1,s1,0x20
    8000340c:	048a                	slli	s1,s1,0x2
    8000340e:	94aa                	add	s1,s1,a0
    80003410:	0504a983          	lw	s3,80(s1)
    80003414:	fe0990e3          	bnez	s3,800033f4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003418:	4108                	lw	a0,0(a0)
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	e4a080e7          	jalr	-438(ra) # 80003264 <balloc>
    80003422:	0005099b          	sext.w	s3,a0
    80003426:	0534a823          	sw	s3,80(s1)
    8000342a:	b7e9                	j	800033f4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000342c:	4108                	lw	a0,0(a0)
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	e36080e7          	jalr	-458(ra) # 80003264 <balloc>
    80003436:	0005059b          	sext.w	a1,a0
    8000343a:	08b92023          	sw	a1,128(s2)
    8000343e:	b759                	j	800033c4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003440:	00092503          	lw	a0,0(s2)
    80003444:	00000097          	auipc	ra,0x0
    80003448:	e20080e7          	jalr	-480(ra) # 80003264 <balloc>
    8000344c:	0005099b          	sext.w	s3,a0
    80003450:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003454:	8552                	mv	a0,s4
    80003456:	00001097          	auipc	ra,0x1
    8000345a:	ee0080e7          	jalr	-288(ra) # 80004336 <log_write>
    8000345e:	b771                	j	800033ea <bmap+0x54>
  panic("bmap: out of range");
    80003460:	00005517          	auipc	a0,0x5
    80003464:	0f850513          	addi	a0,a0,248 # 80008558 <syscalls+0x128>
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	16e080e7          	jalr	366(ra) # 800005d6 <panic>

0000000080003470 <iget>:
{
    80003470:	7179                	addi	sp,sp,-48
    80003472:	f406                	sd	ra,40(sp)
    80003474:	f022                	sd	s0,32(sp)
    80003476:	ec26                	sd	s1,24(sp)
    80003478:	e84a                	sd	s2,16(sp)
    8000347a:	e44e                	sd	s3,8(sp)
    8000347c:	e052                	sd	s4,0(sp)
    8000347e:	1800                	addi	s0,sp,48
    80003480:	89aa                	mv	s3,a0
    80003482:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003484:	00021517          	auipc	a0,0x21
    80003488:	fdc50513          	addi	a0,a0,-36 # 80024460 <icache>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	7e8080e7          	jalr	2024(ra) # 80000c74 <acquire>
  empty = 0;
    80003494:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003496:	00021497          	auipc	s1,0x21
    8000349a:	fe248493          	addi	s1,s1,-30 # 80024478 <icache+0x18>
    8000349e:	00023697          	auipc	a3,0x23
    800034a2:	a6a68693          	addi	a3,a3,-1430 # 80025f08 <log>
    800034a6:	a039                	j	800034b4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034a8:	02090b63          	beqz	s2,800034de <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034ac:	08848493          	addi	s1,s1,136
    800034b0:	02d48a63          	beq	s1,a3,800034e4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034b4:	449c                	lw	a5,8(s1)
    800034b6:	fef059e3          	blez	a5,800034a8 <iget+0x38>
    800034ba:	4098                	lw	a4,0(s1)
    800034bc:	ff3716e3          	bne	a4,s3,800034a8 <iget+0x38>
    800034c0:	40d8                	lw	a4,4(s1)
    800034c2:	ff4713e3          	bne	a4,s4,800034a8 <iget+0x38>
      ip->ref++;
    800034c6:	2785                	addiw	a5,a5,1
    800034c8:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034ca:	00021517          	auipc	a0,0x21
    800034ce:	f9650513          	addi	a0,a0,-106 # 80024460 <icache>
    800034d2:	ffffe097          	auipc	ra,0xffffe
    800034d6:	856080e7          	jalr	-1962(ra) # 80000d28 <release>
      return ip;
    800034da:	8926                	mv	s2,s1
    800034dc:	a03d                	j	8000350a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034de:	f7f9                	bnez	a5,800034ac <iget+0x3c>
    800034e0:	8926                	mv	s2,s1
    800034e2:	b7e9                	j	800034ac <iget+0x3c>
  if(empty == 0)
    800034e4:	02090c63          	beqz	s2,8000351c <iget+0xac>
  ip->dev = dev;
    800034e8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034ec:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034f0:	4785                	li	a5,1
    800034f2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034f6:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034fa:	00021517          	auipc	a0,0x21
    800034fe:	f6650513          	addi	a0,a0,-154 # 80024460 <icache>
    80003502:	ffffe097          	auipc	ra,0xffffe
    80003506:	826080e7          	jalr	-2010(ra) # 80000d28 <release>
}
    8000350a:	854a                	mv	a0,s2
    8000350c:	70a2                	ld	ra,40(sp)
    8000350e:	7402                	ld	s0,32(sp)
    80003510:	64e2                	ld	s1,24(sp)
    80003512:	6942                	ld	s2,16(sp)
    80003514:	69a2                	ld	s3,8(sp)
    80003516:	6a02                	ld	s4,0(sp)
    80003518:	6145                	addi	sp,sp,48
    8000351a:	8082                	ret
    panic("iget: no inodes");
    8000351c:	00005517          	auipc	a0,0x5
    80003520:	05450513          	addi	a0,a0,84 # 80008570 <syscalls+0x140>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	0b2080e7          	jalr	178(ra) # 800005d6 <panic>

000000008000352c <fsinit>:
fsinit(int dev) {
    8000352c:	7179                	addi	sp,sp,-48
    8000352e:	f406                	sd	ra,40(sp)
    80003530:	f022                	sd	s0,32(sp)
    80003532:	ec26                	sd	s1,24(sp)
    80003534:	e84a                	sd	s2,16(sp)
    80003536:	e44e                	sd	s3,8(sp)
    80003538:	1800                	addi	s0,sp,48
    8000353a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000353c:	4585                	li	a1,1
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	a64080e7          	jalr	-1436(ra) # 80002fa2 <bread>
    80003546:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003548:	00021997          	auipc	s3,0x21
    8000354c:	ef898993          	addi	s3,s3,-264 # 80024440 <sb>
    80003550:	02000613          	li	a2,32
    80003554:	05850593          	addi	a1,a0,88
    80003558:	854e                	mv	a0,s3
    8000355a:	ffffe097          	auipc	ra,0xffffe
    8000355e:	876080e7          	jalr	-1930(ra) # 80000dd0 <memmove>
  brelse(bp);
    80003562:	8526                	mv	a0,s1
    80003564:	00000097          	auipc	ra,0x0
    80003568:	b6e080e7          	jalr	-1170(ra) # 800030d2 <brelse>
  if(sb.magic != FSMAGIC)
    8000356c:	0009a703          	lw	a4,0(s3)
    80003570:	102037b7          	lui	a5,0x10203
    80003574:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003578:	02f71263          	bne	a4,a5,8000359c <fsinit+0x70>
  initlog(dev, &sb);
    8000357c:	00021597          	auipc	a1,0x21
    80003580:	ec458593          	addi	a1,a1,-316 # 80024440 <sb>
    80003584:	854a                	mv	a0,s2
    80003586:	00001097          	auipc	ra,0x1
    8000358a:	b38080e7          	jalr	-1224(ra) # 800040be <initlog>
}
    8000358e:	70a2                	ld	ra,40(sp)
    80003590:	7402                	ld	s0,32(sp)
    80003592:	64e2                	ld	s1,24(sp)
    80003594:	6942                	ld	s2,16(sp)
    80003596:	69a2                	ld	s3,8(sp)
    80003598:	6145                	addi	sp,sp,48
    8000359a:	8082                	ret
    panic("invalid file system");
    8000359c:	00005517          	auipc	a0,0x5
    800035a0:	fe450513          	addi	a0,a0,-28 # 80008580 <syscalls+0x150>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	032080e7          	jalr	50(ra) # 800005d6 <panic>

00000000800035ac <iinit>:
{
    800035ac:	7179                	addi	sp,sp,-48
    800035ae:	f406                	sd	ra,40(sp)
    800035b0:	f022                	sd	s0,32(sp)
    800035b2:	ec26                	sd	s1,24(sp)
    800035b4:	e84a                	sd	s2,16(sp)
    800035b6:	e44e                	sd	s3,8(sp)
    800035b8:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035ba:	00005597          	auipc	a1,0x5
    800035be:	fde58593          	addi	a1,a1,-34 # 80008598 <syscalls+0x168>
    800035c2:	00021517          	auipc	a0,0x21
    800035c6:	e9e50513          	addi	a0,a0,-354 # 80024460 <icache>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	61a080e7          	jalr	1562(ra) # 80000be4 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035d2:	00021497          	auipc	s1,0x21
    800035d6:	eb648493          	addi	s1,s1,-330 # 80024488 <icache+0x28>
    800035da:	00023997          	auipc	s3,0x23
    800035de:	93e98993          	addi	s3,s3,-1730 # 80025f18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035e2:	00005917          	auipc	s2,0x5
    800035e6:	fbe90913          	addi	s2,s2,-66 # 800085a0 <syscalls+0x170>
    800035ea:	85ca                	mv	a1,s2
    800035ec:	8526                	mv	a0,s1
    800035ee:	00001097          	auipc	ra,0x1
    800035f2:	e36080e7          	jalr	-458(ra) # 80004424 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035f6:	08848493          	addi	s1,s1,136
    800035fa:	ff3498e3          	bne	s1,s3,800035ea <iinit+0x3e>
}
    800035fe:	70a2                	ld	ra,40(sp)
    80003600:	7402                	ld	s0,32(sp)
    80003602:	64e2                	ld	s1,24(sp)
    80003604:	6942                	ld	s2,16(sp)
    80003606:	69a2                	ld	s3,8(sp)
    80003608:	6145                	addi	sp,sp,48
    8000360a:	8082                	ret

000000008000360c <ialloc>:
{
    8000360c:	715d                	addi	sp,sp,-80
    8000360e:	e486                	sd	ra,72(sp)
    80003610:	e0a2                	sd	s0,64(sp)
    80003612:	fc26                	sd	s1,56(sp)
    80003614:	f84a                	sd	s2,48(sp)
    80003616:	f44e                	sd	s3,40(sp)
    80003618:	f052                	sd	s4,32(sp)
    8000361a:	ec56                	sd	s5,24(sp)
    8000361c:	e85a                	sd	s6,16(sp)
    8000361e:	e45e                	sd	s7,8(sp)
    80003620:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003622:	00021717          	auipc	a4,0x21
    80003626:	e2a72703          	lw	a4,-470(a4) # 8002444c <sb+0xc>
    8000362a:	4785                	li	a5,1
    8000362c:	04e7fa63          	bgeu	a5,a4,80003680 <ialloc+0x74>
    80003630:	8aaa                	mv	s5,a0
    80003632:	8bae                	mv	s7,a1
    80003634:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003636:	00021a17          	auipc	s4,0x21
    8000363a:	e0aa0a13          	addi	s4,s4,-502 # 80024440 <sb>
    8000363e:	00048b1b          	sext.w	s6,s1
    80003642:	0044d593          	srli	a1,s1,0x4
    80003646:	018a2783          	lw	a5,24(s4)
    8000364a:	9dbd                	addw	a1,a1,a5
    8000364c:	8556                	mv	a0,s5
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	954080e7          	jalr	-1708(ra) # 80002fa2 <bread>
    80003656:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003658:	05850993          	addi	s3,a0,88
    8000365c:	00f4f793          	andi	a5,s1,15
    80003660:	079a                	slli	a5,a5,0x6
    80003662:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003664:	00099783          	lh	a5,0(s3)
    80003668:	c785                	beqz	a5,80003690 <ialloc+0x84>
    brelse(bp);
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	a68080e7          	jalr	-1432(ra) # 800030d2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003672:	0485                	addi	s1,s1,1
    80003674:	00ca2703          	lw	a4,12(s4)
    80003678:	0004879b          	sext.w	a5,s1
    8000367c:	fce7e1e3          	bltu	a5,a4,8000363e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003680:	00005517          	auipc	a0,0x5
    80003684:	f2850513          	addi	a0,a0,-216 # 800085a8 <syscalls+0x178>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	f4e080e7          	jalr	-178(ra) # 800005d6 <panic>
      memset(dip, 0, sizeof(*dip));
    80003690:	04000613          	li	a2,64
    80003694:	4581                	li	a1,0
    80003696:	854e                	mv	a0,s3
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	6d8080e7          	jalr	1752(ra) # 80000d70 <memset>
      dip->type = type;
    800036a0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036a4:	854a                	mv	a0,s2
    800036a6:	00001097          	auipc	ra,0x1
    800036aa:	c90080e7          	jalr	-880(ra) # 80004336 <log_write>
      brelse(bp);
    800036ae:	854a                	mv	a0,s2
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	a22080e7          	jalr	-1502(ra) # 800030d2 <brelse>
      return iget(dev, inum);
    800036b8:	85da                	mv	a1,s6
    800036ba:	8556                	mv	a0,s5
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	db4080e7          	jalr	-588(ra) # 80003470 <iget>
}
    800036c4:	60a6                	ld	ra,72(sp)
    800036c6:	6406                	ld	s0,64(sp)
    800036c8:	74e2                	ld	s1,56(sp)
    800036ca:	7942                	ld	s2,48(sp)
    800036cc:	79a2                	ld	s3,40(sp)
    800036ce:	7a02                	ld	s4,32(sp)
    800036d0:	6ae2                	ld	s5,24(sp)
    800036d2:	6b42                	ld	s6,16(sp)
    800036d4:	6ba2                	ld	s7,8(sp)
    800036d6:	6161                	addi	sp,sp,80
    800036d8:	8082                	ret

00000000800036da <iupdate>:
{
    800036da:	1101                	addi	sp,sp,-32
    800036dc:	ec06                	sd	ra,24(sp)
    800036de:	e822                	sd	s0,16(sp)
    800036e0:	e426                	sd	s1,8(sp)
    800036e2:	e04a                	sd	s2,0(sp)
    800036e4:	1000                	addi	s0,sp,32
    800036e6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036e8:	415c                	lw	a5,4(a0)
    800036ea:	0047d79b          	srliw	a5,a5,0x4
    800036ee:	00021597          	auipc	a1,0x21
    800036f2:	d6a5a583          	lw	a1,-662(a1) # 80024458 <sb+0x18>
    800036f6:	9dbd                	addw	a1,a1,a5
    800036f8:	4108                	lw	a0,0(a0)
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	8a8080e7          	jalr	-1880(ra) # 80002fa2 <bread>
    80003702:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003704:	05850793          	addi	a5,a0,88
    80003708:	40c8                	lw	a0,4(s1)
    8000370a:	893d                	andi	a0,a0,15
    8000370c:	051a                	slli	a0,a0,0x6
    8000370e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003710:	04449703          	lh	a4,68(s1)
    80003714:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003718:	04649703          	lh	a4,70(s1)
    8000371c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003720:	04849703          	lh	a4,72(s1)
    80003724:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003728:	04a49703          	lh	a4,74(s1)
    8000372c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003730:	44f8                	lw	a4,76(s1)
    80003732:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003734:	03400613          	li	a2,52
    80003738:	05048593          	addi	a1,s1,80
    8000373c:	0531                	addi	a0,a0,12
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	692080e7          	jalr	1682(ra) # 80000dd0 <memmove>
  log_write(bp);
    80003746:	854a                	mv	a0,s2
    80003748:	00001097          	auipc	ra,0x1
    8000374c:	bee080e7          	jalr	-1042(ra) # 80004336 <log_write>
  brelse(bp);
    80003750:	854a                	mv	a0,s2
    80003752:	00000097          	auipc	ra,0x0
    80003756:	980080e7          	jalr	-1664(ra) # 800030d2 <brelse>
}
    8000375a:	60e2                	ld	ra,24(sp)
    8000375c:	6442                	ld	s0,16(sp)
    8000375e:	64a2                	ld	s1,8(sp)
    80003760:	6902                	ld	s2,0(sp)
    80003762:	6105                	addi	sp,sp,32
    80003764:	8082                	ret

0000000080003766 <idup>:
{
    80003766:	1101                	addi	sp,sp,-32
    80003768:	ec06                	sd	ra,24(sp)
    8000376a:	e822                	sd	s0,16(sp)
    8000376c:	e426                	sd	s1,8(sp)
    8000376e:	1000                	addi	s0,sp,32
    80003770:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003772:	00021517          	auipc	a0,0x21
    80003776:	cee50513          	addi	a0,a0,-786 # 80024460 <icache>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	4fa080e7          	jalr	1274(ra) # 80000c74 <acquire>
  ip->ref++;
    80003782:	449c                	lw	a5,8(s1)
    80003784:	2785                	addiw	a5,a5,1
    80003786:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003788:	00021517          	auipc	a0,0x21
    8000378c:	cd850513          	addi	a0,a0,-808 # 80024460 <icache>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	598080e7          	jalr	1432(ra) # 80000d28 <release>
}
    80003798:	8526                	mv	a0,s1
    8000379a:	60e2                	ld	ra,24(sp)
    8000379c:	6442                	ld	s0,16(sp)
    8000379e:	64a2                	ld	s1,8(sp)
    800037a0:	6105                	addi	sp,sp,32
    800037a2:	8082                	ret

00000000800037a4 <ilock>:
{
    800037a4:	1101                	addi	sp,sp,-32
    800037a6:	ec06                	sd	ra,24(sp)
    800037a8:	e822                	sd	s0,16(sp)
    800037aa:	e426                	sd	s1,8(sp)
    800037ac:	e04a                	sd	s2,0(sp)
    800037ae:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037b0:	c115                	beqz	a0,800037d4 <ilock+0x30>
    800037b2:	84aa                	mv	s1,a0
    800037b4:	451c                	lw	a5,8(a0)
    800037b6:	00f05f63          	blez	a5,800037d4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037ba:	0541                	addi	a0,a0,16
    800037bc:	00001097          	auipc	ra,0x1
    800037c0:	ca2080e7          	jalr	-862(ra) # 8000445e <acquiresleep>
  if(ip->valid == 0){
    800037c4:	40bc                	lw	a5,64(s1)
    800037c6:	cf99                	beqz	a5,800037e4 <ilock+0x40>
}
    800037c8:	60e2                	ld	ra,24(sp)
    800037ca:	6442                	ld	s0,16(sp)
    800037cc:	64a2                	ld	s1,8(sp)
    800037ce:	6902                	ld	s2,0(sp)
    800037d0:	6105                	addi	sp,sp,32
    800037d2:	8082                	ret
    panic("ilock");
    800037d4:	00005517          	auipc	a0,0x5
    800037d8:	dec50513          	addi	a0,a0,-532 # 800085c0 <syscalls+0x190>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	dfa080e7          	jalr	-518(ra) # 800005d6 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037e4:	40dc                	lw	a5,4(s1)
    800037e6:	0047d79b          	srliw	a5,a5,0x4
    800037ea:	00021597          	auipc	a1,0x21
    800037ee:	c6e5a583          	lw	a1,-914(a1) # 80024458 <sb+0x18>
    800037f2:	9dbd                	addw	a1,a1,a5
    800037f4:	4088                	lw	a0,0(s1)
    800037f6:	fffff097          	auipc	ra,0xfffff
    800037fa:	7ac080e7          	jalr	1964(ra) # 80002fa2 <bread>
    800037fe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003800:	05850593          	addi	a1,a0,88
    80003804:	40dc                	lw	a5,4(s1)
    80003806:	8bbd                	andi	a5,a5,15
    80003808:	079a                	slli	a5,a5,0x6
    8000380a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000380c:	00059783          	lh	a5,0(a1)
    80003810:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003814:	00259783          	lh	a5,2(a1)
    80003818:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000381c:	00459783          	lh	a5,4(a1)
    80003820:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003824:	00659783          	lh	a5,6(a1)
    80003828:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000382c:	459c                	lw	a5,8(a1)
    8000382e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003830:	03400613          	li	a2,52
    80003834:	05b1                	addi	a1,a1,12
    80003836:	05048513          	addi	a0,s1,80
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	596080e7          	jalr	1430(ra) # 80000dd0 <memmove>
    brelse(bp);
    80003842:	854a                	mv	a0,s2
    80003844:	00000097          	auipc	ra,0x0
    80003848:	88e080e7          	jalr	-1906(ra) # 800030d2 <brelse>
    ip->valid = 1;
    8000384c:	4785                	li	a5,1
    8000384e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003850:	04449783          	lh	a5,68(s1)
    80003854:	fbb5                	bnez	a5,800037c8 <ilock+0x24>
      panic("ilock: no type");
    80003856:	00005517          	auipc	a0,0x5
    8000385a:	d7250513          	addi	a0,a0,-654 # 800085c8 <syscalls+0x198>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	d78080e7          	jalr	-648(ra) # 800005d6 <panic>

0000000080003866 <iunlock>:
{
    80003866:	1101                	addi	sp,sp,-32
    80003868:	ec06                	sd	ra,24(sp)
    8000386a:	e822                	sd	s0,16(sp)
    8000386c:	e426                	sd	s1,8(sp)
    8000386e:	e04a                	sd	s2,0(sp)
    80003870:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003872:	c905                	beqz	a0,800038a2 <iunlock+0x3c>
    80003874:	84aa                	mv	s1,a0
    80003876:	01050913          	addi	s2,a0,16
    8000387a:	854a                	mv	a0,s2
    8000387c:	00001097          	auipc	ra,0x1
    80003880:	c7c080e7          	jalr	-900(ra) # 800044f8 <holdingsleep>
    80003884:	cd19                	beqz	a0,800038a2 <iunlock+0x3c>
    80003886:	449c                	lw	a5,8(s1)
    80003888:	00f05d63          	blez	a5,800038a2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000388c:	854a                	mv	a0,s2
    8000388e:	00001097          	auipc	ra,0x1
    80003892:	c26080e7          	jalr	-986(ra) # 800044b4 <releasesleep>
}
    80003896:	60e2                	ld	ra,24(sp)
    80003898:	6442                	ld	s0,16(sp)
    8000389a:	64a2                	ld	s1,8(sp)
    8000389c:	6902                	ld	s2,0(sp)
    8000389e:	6105                	addi	sp,sp,32
    800038a0:	8082                	ret
    panic("iunlock");
    800038a2:	00005517          	auipc	a0,0x5
    800038a6:	d3650513          	addi	a0,a0,-714 # 800085d8 <syscalls+0x1a8>
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	d2c080e7          	jalr	-724(ra) # 800005d6 <panic>

00000000800038b2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038b2:	7179                	addi	sp,sp,-48
    800038b4:	f406                	sd	ra,40(sp)
    800038b6:	f022                	sd	s0,32(sp)
    800038b8:	ec26                	sd	s1,24(sp)
    800038ba:	e84a                	sd	s2,16(sp)
    800038bc:	e44e                	sd	s3,8(sp)
    800038be:	e052                	sd	s4,0(sp)
    800038c0:	1800                	addi	s0,sp,48
    800038c2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038c4:	05050493          	addi	s1,a0,80
    800038c8:	08050913          	addi	s2,a0,128
    800038cc:	a021                	j	800038d4 <itrunc+0x22>
    800038ce:	0491                	addi	s1,s1,4
    800038d0:	01248d63          	beq	s1,s2,800038ea <itrunc+0x38>
    if(ip->addrs[i]){
    800038d4:	408c                	lw	a1,0(s1)
    800038d6:	dde5                	beqz	a1,800038ce <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038d8:	0009a503          	lw	a0,0(s3)
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	90c080e7          	jalr	-1780(ra) # 800031e8 <bfree>
      ip->addrs[i] = 0;
    800038e4:	0004a023          	sw	zero,0(s1)
    800038e8:	b7dd                	j	800038ce <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038ea:	0809a583          	lw	a1,128(s3)
    800038ee:	e185                	bnez	a1,8000390e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038f0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038f4:	854e                	mv	a0,s3
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	de4080e7          	jalr	-540(ra) # 800036da <iupdate>
}
    800038fe:	70a2                	ld	ra,40(sp)
    80003900:	7402                	ld	s0,32(sp)
    80003902:	64e2                	ld	s1,24(sp)
    80003904:	6942                	ld	s2,16(sp)
    80003906:	69a2                	ld	s3,8(sp)
    80003908:	6a02                	ld	s4,0(sp)
    8000390a:	6145                	addi	sp,sp,48
    8000390c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000390e:	0009a503          	lw	a0,0(s3)
    80003912:	fffff097          	auipc	ra,0xfffff
    80003916:	690080e7          	jalr	1680(ra) # 80002fa2 <bread>
    8000391a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000391c:	05850493          	addi	s1,a0,88
    80003920:	45850913          	addi	s2,a0,1112
    80003924:	a811                	j	80003938 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003926:	0009a503          	lw	a0,0(s3)
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	8be080e7          	jalr	-1858(ra) # 800031e8 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003932:	0491                	addi	s1,s1,4
    80003934:	01248563          	beq	s1,s2,8000393e <itrunc+0x8c>
      if(a[j])
    80003938:	408c                	lw	a1,0(s1)
    8000393a:	dde5                	beqz	a1,80003932 <itrunc+0x80>
    8000393c:	b7ed                	j	80003926 <itrunc+0x74>
    brelse(bp);
    8000393e:	8552                	mv	a0,s4
    80003940:	fffff097          	auipc	ra,0xfffff
    80003944:	792080e7          	jalr	1938(ra) # 800030d2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003948:	0809a583          	lw	a1,128(s3)
    8000394c:	0009a503          	lw	a0,0(s3)
    80003950:	00000097          	auipc	ra,0x0
    80003954:	898080e7          	jalr	-1896(ra) # 800031e8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003958:	0809a023          	sw	zero,128(s3)
    8000395c:	bf51                	j	800038f0 <itrunc+0x3e>

000000008000395e <iput>:
{
    8000395e:	1101                	addi	sp,sp,-32
    80003960:	ec06                	sd	ra,24(sp)
    80003962:	e822                	sd	s0,16(sp)
    80003964:	e426                	sd	s1,8(sp)
    80003966:	e04a                	sd	s2,0(sp)
    80003968:	1000                	addi	s0,sp,32
    8000396a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000396c:	00021517          	auipc	a0,0x21
    80003970:	af450513          	addi	a0,a0,-1292 # 80024460 <icache>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	300080e7          	jalr	768(ra) # 80000c74 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000397c:	4498                	lw	a4,8(s1)
    8000397e:	4785                	li	a5,1
    80003980:	02f70363          	beq	a4,a5,800039a6 <iput+0x48>
  ip->ref--;
    80003984:	449c                	lw	a5,8(s1)
    80003986:	37fd                	addiw	a5,a5,-1
    80003988:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000398a:	00021517          	auipc	a0,0x21
    8000398e:	ad650513          	addi	a0,a0,-1322 # 80024460 <icache>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	396080e7          	jalr	918(ra) # 80000d28 <release>
}
    8000399a:	60e2                	ld	ra,24(sp)
    8000399c:	6442                	ld	s0,16(sp)
    8000399e:	64a2                	ld	s1,8(sp)
    800039a0:	6902                	ld	s2,0(sp)
    800039a2:	6105                	addi	sp,sp,32
    800039a4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039a6:	40bc                	lw	a5,64(s1)
    800039a8:	dff1                	beqz	a5,80003984 <iput+0x26>
    800039aa:	04a49783          	lh	a5,74(s1)
    800039ae:	fbf9                	bnez	a5,80003984 <iput+0x26>
    acquiresleep(&ip->lock);
    800039b0:	01048913          	addi	s2,s1,16
    800039b4:	854a                	mv	a0,s2
    800039b6:	00001097          	auipc	ra,0x1
    800039ba:	aa8080e7          	jalr	-1368(ra) # 8000445e <acquiresleep>
    release(&icache.lock);
    800039be:	00021517          	auipc	a0,0x21
    800039c2:	aa250513          	addi	a0,a0,-1374 # 80024460 <icache>
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	362080e7          	jalr	866(ra) # 80000d28 <release>
    itrunc(ip);
    800039ce:	8526                	mv	a0,s1
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	ee2080e7          	jalr	-286(ra) # 800038b2 <itrunc>
    ip->type = 0;
    800039d8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039dc:	8526                	mv	a0,s1
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	cfc080e7          	jalr	-772(ra) # 800036da <iupdate>
    ip->valid = 0;
    800039e6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039ea:	854a                	mv	a0,s2
    800039ec:	00001097          	auipc	ra,0x1
    800039f0:	ac8080e7          	jalr	-1336(ra) # 800044b4 <releasesleep>
    acquire(&icache.lock);
    800039f4:	00021517          	auipc	a0,0x21
    800039f8:	a6c50513          	addi	a0,a0,-1428 # 80024460 <icache>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	278080e7          	jalr	632(ra) # 80000c74 <acquire>
    80003a04:	b741                	j	80003984 <iput+0x26>

0000000080003a06 <iunlockput>:
{
    80003a06:	1101                	addi	sp,sp,-32
    80003a08:	ec06                	sd	ra,24(sp)
    80003a0a:	e822                	sd	s0,16(sp)
    80003a0c:	e426                	sd	s1,8(sp)
    80003a0e:	1000                	addi	s0,sp,32
    80003a10:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	e54080e7          	jalr	-428(ra) # 80003866 <iunlock>
  iput(ip);
    80003a1a:	8526                	mv	a0,s1
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	f42080e7          	jalr	-190(ra) # 8000395e <iput>
}
    80003a24:	60e2                	ld	ra,24(sp)
    80003a26:	6442                	ld	s0,16(sp)
    80003a28:	64a2                	ld	s1,8(sp)
    80003a2a:	6105                	addi	sp,sp,32
    80003a2c:	8082                	ret

0000000080003a2e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a2e:	1141                	addi	sp,sp,-16
    80003a30:	e422                	sd	s0,8(sp)
    80003a32:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a34:	411c                	lw	a5,0(a0)
    80003a36:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a38:	415c                	lw	a5,4(a0)
    80003a3a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a3c:	04451783          	lh	a5,68(a0)
    80003a40:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a44:	04a51783          	lh	a5,74(a0)
    80003a48:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a4c:	04c56783          	lwu	a5,76(a0)
    80003a50:	e99c                	sd	a5,16(a1)
}
    80003a52:	6422                	ld	s0,8(sp)
    80003a54:	0141                	addi	sp,sp,16
    80003a56:	8082                	ret

0000000080003a58 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a58:	457c                	lw	a5,76(a0)
    80003a5a:	0ed7e863          	bltu	a5,a3,80003b4a <readi+0xf2>
{
    80003a5e:	7159                	addi	sp,sp,-112
    80003a60:	f486                	sd	ra,104(sp)
    80003a62:	f0a2                	sd	s0,96(sp)
    80003a64:	eca6                	sd	s1,88(sp)
    80003a66:	e8ca                	sd	s2,80(sp)
    80003a68:	e4ce                	sd	s3,72(sp)
    80003a6a:	e0d2                	sd	s4,64(sp)
    80003a6c:	fc56                	sd	s5,56(sp)
    80003a6e:	f85a                	sd	s6,48(sp)
    80003a70:	f45e                	sd	s7,40(sp)
    80003a72:	f062                	sd	s8,32(sp)
    80003a74:	ec66                	sd	s9,24(sp)
    80003a76:	e86a                	sd	s10,16(sp)
    80003a78:	e46e                	sd	s11,8(sp)
    80003a7a:	1880                	addi	s0,sp,112
    80003a7c:	8baa                	mv	s7,a0
    80003a7e:	8c2e                	mv	s8,a1
    80003a80:	8ab2                	mv	s5,a2
    80003a82:	84b6                	mv	s1,a3
    80003a84:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a86:	9f35                	addw	a4,a4,a3
    return 0;
    80003a88:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a8a:	08d76f63          	bltu	a4,a3,80003b28 <readi+0xd0>
  if(off + n > ip->size)
    80003a8e:	00e7f463          	bgeu	a5,a4,80003a96 <readi+0x3e>
    n = ip->size - off;
    80003a92:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a96:	0a0b0863          	beqz	s6,80003b46 <readi+0xee>
    80003a9a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a9c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aa0:	5cfd                	li	s9,-1
    80003aa2:	a82d                	j	80003adc <readi+0x84>
    80003aa4:	020a1d93          	slli	s11,s4,0x20
    80003aa8:	020ddd93          	srli	s11,s11,0x20
    80003aac:	05890613          	addi	a2,s2,88
    80003ab0:	86ee                	mv	a3,s11
    80003ab2:	963a                	add	a2,a2,a4
    80003ab4:	85d6                	mv	a1,s5
    80003ab6:	8562                	mv	a0,s8
    80003ab8:	fffff097          	auipc	ra,0xfffff
    80003abc:	a0a080e7          	jalr	-1526(ra) # 800024c2 <either_copyout>
    80003ac0:	05950d63          	beq	a0,s9,80003b1a <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003ac4:	854a                	mv	a0,s2
    80003ac6:	fffff097          	auipc	ra,0xfffff
    80003aca:	60c080e7          	jalr	1548(ra) # 800030d2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ace:	013a09bb          	addw	s3,s4,s3
    80003ad2:	009a04bb          	addw	s1,s4,s1
    80003ad6:	9aee                	add	s5,s5,s11
    80003ad8:	0569f663          	bgeu	s3,s6,80003b24 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003adc:	000ba903          	lw	s2,0(s7)
    80003ae0:	00a4d59b          	srliw	a1,s1,0xa
    80003ae4:	855e                	mv	a0,s7
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	8b0080e7          	jalr	-1872(ra) # 80003396 <bmap>
    80003aee:	0005059b          	sext.w	a1,a0
    80003af2:	854a                	mv	a0,s2
    80003af4:	fffff097          	auipc	ra,0xfffff
    80003af8:	4ae080e7          	jalr	1198(ra) # 80002fa2 <bread>
    80003afc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003afe:	3ff4f713          	andi	a4,s1,1023
    80003b02:	40ed07bb          	subw	a5,s10,a4
    80003b06:	413b06bb          	subw	a3,s6,s3
    80003b0a:	8a3e                	mv	s4,a5
    80003b0c:	2781                	sext.w	a5,a5
    80003b0e:	0006861b          	sext.w	a2,a3
    80003b12:	f8f679e3          	bgeu	a2,a5,80003aa4 <readi+0x4c>
    80003b16:	8a36                	mv	s4,a3
    80003b18:	b771                	j	80003aa4 <readi+0x4c>
      brelse(bp);
    80003b1a:	854a                	mv	a0,s2
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	5b6080e7          	jalr	1462(ra) # 800030d2 <brelse>
  }
  return tot;
    80003b24:	0009851b          	sext.w	a0,s3
}
    80003b28:	70a6                	ld	ra,104(sp)
    80003b2a:	7406                	ld	s0,96(sp)
    80003b2c:	64e6                	ld	s1,88(sp)
    80003b2e:	6946                	ld	s2,80(sp)
    80003b30:	69a6                	ld	s3,72(sp)
    80003b32:	6a06                	ld	s4,64(sp)
    80003b34:	7ae2                	ld	s5,56(sp)
    80003b36:	7b42                	ld	s6,48(sp)
    80003b38:	7ba2                	ld	s7,40(sp)
    80003b3a:	7c02                	ld	s8,32(sp)
    80003b3c:	6ce2                	ld	s9,24(sp)
    80003b3e:	6d42                	ld	s10,16(sp)
    80003b40:	6da2                	ld	s11,8(sp)
    80003b42:	6165                	addi	sp,sp,112
    80003b44:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b46:	89da                	mv	s3,s6
    80003b48:	bff1                	j	80003b24 <readi+0xcc>
    return 0;
    80003b4a:	4501                	li	a0,0
}
    80003b4c:	8082                	ret

0000000080003b4e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b4e:	457c                	lw	a5,76(a0)
    80003b50:	10d7e663          	bltu	a5,a3,80003c5c <writei+0x10e>
{
    80003b54:	7159                	addi	sp,sp,-112
    80003b56:	f486                	sd	ra,104(sp)
    80003b58:	f0a2                	sd	s0,96(sp)
    80003b5a:	eca6                	sd	s1,88(sp)
    80003b5c:	e8ca                	sd	s2,80(sp)
    80003b5e:	e4ce                	sd	s3,72(sp)
    80003b60:	e0d2                	sd	s4,64(sp)
    80003b62:	fc56                	sd	s5,56(sp)
    80003b64:	f85a                	sd	s6,48(sp)
    80003b66:	f45e                	sd	s7,40(sp)
    80003b68:	f062                	sd	s8,32(sp)
    80003b6a:	ec66                	sd	s9,24(sp)
    80003b6c:	e86a                	sd	s10,16(sp)
    80003b6e:	e46e                	sd	s11,8(sp)
    80003b70:	1880                	addi	s0,sp,112
    80003b72:	8baa                	mv	s7,a0
    80003b74:	8c2e                	mv	s8,a1
    80003b76:	8ab2                	mv	s5,a2
    80003b78:	8936                	mv	s2,a3
    80003b7a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b7c:	00e687bb          	addw	a5,a3,a4
    80003b80:	0ed7e063          	bltu	a5,a3,80003c60 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b84:	00043737          	lui	a4,0x43
    80003b88:	0cf76e63          	bltu	a4,a5,80003c64 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b8c:	0a0b0763          	beqz	s6,80003c3a <writei+0xec>
    80003b90:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b92:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b96:	5cfd                	li	s9,-1
    80003b98:	a091                	j	80003bdc <writei+0x8e>
    80003b9a:	02099d93          	slli	s11,s3,0x20
    80003b9e:	020ddd93          	srli	s11,s11,0x20
    80003ba2:	05848513          	addi	a0,s1,88
    80003ba6:	86ee                	mv	a3,s11
    80003ba8:	8656                	mv	a2,s5
    80003baa:	85e2                	mv	a1,s8
    80003bac:	953a                	add	a0,a0,a4
    80003bae:	fffff097          	auipc	ra,0xfffff
    80003bb2:	96a080e7          	jalr	-1686(ra) # 80002518 <either_copyin>
    80003bb6:	07950263          	beq	a0,s9,80003c1a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bba:	8526                	mv	a0,s1
    80003bbc:	00000097          	auipc	ra,0x0
    80003bc0:	77a080e7          	jalr	1914(ra) # 80004336 <log_write>
    brelse(bp);
    80003bc4:	8526                	mv	a0,s1
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	50c080e7          	jalr	1292(ra) # 800030d2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bce:	01498a3b          	addw	s4,s3,s4
    80003bd2:	0129893b          	addw	s2,s3,s2
    80003bd6:	9aee                	add	s5,s5,s11
    80003bd8:	056a7663          	bgeu	s4,s6,80003c24 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bdc:	000ba483          	lw	s1,0(s7)
    80003be0:	00a9559b          	srliw	a1,s2,0xa
    80003be4:	855e                	mv	a0,s7
    80003be6:	fffff097          	auipc	ra,0xfffff
    80003bea:	7b0080e7          	jalr	1968(ra) # 80003396 <bmap>
    80003bee:	0005059b          	sext.w	a1,a0
    80003bf2:	8526                	mv	a0,s1
    80003bf4:	fffff097          	auipc	ra,0xfffff
    80003bf8:	3ae080e7          	jalr	942(ra) # 80002fa2 <bread>
    80003bfc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bfe:	3ff97713          	andi	a4,s2,1023
    80003c02:	40ed07bb          	subw	a5,s10,a4
    80003c06:	414b06bb          	subw	a3,s6,s4
    80003c0a:	89be                	mv	s3,a5
    80003c0c:	2781                	sext.w	a5,a5
    80003c0e:	0006861b          	sext.w	a2,a3
    80003c12:	f8f674e3          	bgeu	a2,a5,80003b9a <writei+0x4c>
    80003c16:	89b6                	mv	s3,a3
    80003c18:	b749                	j	80003b9a <writei+0x4c>
      brelse(bp);
    80003c1a:	8526                	mv	a0,s1
    80003c1c:	fffff097          	auipc	ra,0xfffff
    80003c20:	4b6080e7          	jalr	1206(ra) # 800030d2 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c24:	04cba783          	lw	a5,76(s7)
    80003c28:	0127f463          	bgeu	a5,s2,80003c30 <writei+0xe2>
      ip->size = off;
    80003c2c:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c30:	855e                	mv	a0,s7
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	aa8080e7          	jalr	-1368(ra) # 800036da <iupdate>
  }

  return n;
    80003c3a:	000b051b          	sext.w	a0,s6
}
    80003c3e:	70a6                	ld	ra,104(sp)
    80003c40:	7406                	ld	s0,96(sp)
    80003c42:	64e6                	ld	s1,88(sp)
    80003c44:	6946                	ld	s2,80(sp)
    80003c46:	69a6                	ld	s3,72(sp)
    80003c48:	6a06                	ld	s4,64(sp)
    80003c4a:	7ae2                	ld	s5,56(sp)
    80003c4c:	7b42                	ld	s6,48(sp)
    80003c4e:	7ba2                	ld	s7,40(sp)
    80003c50:	7c02                	ld	s8,32(sp)
    80003c52:	6ce2                	ld	s9,24(sp)
    80003c54:	6d42                	ld	s10,16(sp)
    80003c56:	6da2                	ld	s11,8(sp)
    80003c58:	6165                	addi	sp,sp,112
    80003c5a:	8082                	ret
    return -1;
    80003c5c:	557d                	li	a0,-1
}
    80003c5e:	8082                	ret
    return -1;
    80003c60:	557d                	li	a0,-1
    80003c62:	bff1                	j	80003c3e <writei+0xf0>
    return -1;
    80003c64:	557d                	li	a0,-1
    80003c66:	bfe1                	j	80003c3e <writei+0xf0>

0000000080003c68 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c68:	1141                	addi	sp,sp,-16
    80003c6a:	e406                	sd	ra,8(sp)
    80003c6c:	e022                	sd	s0,0(sp)
    80003c6e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c70:	4639                	li	a2,14
    80003c72:	ffffd097          	auipc	ra,0xffffd
    80003c76:	1da080e7          	jalr	474(ra) # 80000e4c <strncmp>
}
    80003c7a:	60a2                	ld	ra,8(sp)
    80003c7c:	6402                	ld	s0,0(sp)
    80003c7e:	0141                	addi	sp,sp,16
    80003c80:	8082                	ret

0000000080003c82 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c82:	7139                	addi	sp,sp,-64
    80003c84:	fc06                	sd	ra,56(sp)
    80003c86:	f822                	sd	s0,48(sp)
    80003c88:	f426                	sd	s1,40(sp)
    80003c8a:	f04a                	sd	s2,32(sp)
    80003c8c:	ec4e                	sd	s3,24(sp)
    80003c8e:	e852                	sd	s4,16(sp)
    80003c90:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c92:	04451703          	lh	a4,68(a0)
    80003c96:	4785                	li	a5,1
    80003c98:	00f71a63          	bne	a4,a5,80003cac <dirlookup+0x2a>
    80003c9c:	892a                	mv	s2,a0
    80003c9e:	89ae                	mv	s3,a1
    80003ca0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca2:	457c                	lw	a5,76(a0)
    80003ca4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ca6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca8:	e79d                	bnez	a5,80003cd6 <dirlookup+0x54>
    80003caa:	a8a5                	j	80003d22 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cac:	00005517          	auipc	a0,0x5
    80003cb0:	93450513          	addi	a0,a0,-1740 # 800085e0 <syscalls+0x1b0>
    80003cb4:	ffffd097          	auipc	ra,0xffffd
    80003cb8:	922080e7          	jalr	-1758(ra) # 800005d6 <panic>
      panic("dirlookup read");
    80003cbc:	00005517          	auipc	a0,0x5
    80003cc0:	93c50513          	addi	a0,a0,-1732 # 800085f8 <syscalls+0x1c8>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	912080e7          	jalr	-1774(ra) # 800005d6 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ccc:	24c1                	addiw	s1,s1,16
    80003cce:	04c92783          	lw	a5,76(s2)
    80003cd2:	04f4f763          	bgeu	s1,a5,80003d20 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cd6:	4741                	li	a4,16
    80003cd8:	86a6                	mv	a3,s1
    80003cda:	fc040613          	addi	a2,s0,-64
    80003cde:	4581                	li	a1,0
    80003ce0:	854a                	mv	a0,s2
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	d76080e7          	jalr	-650(ra) # 80003a58 <readi>
    80003cea:	47c1                	li	a5,16
    80003cec:	fcf518e3          	bne	a0,a5,80003cbc <dirlookup+0x3a>
    if(de.inum == 0)
    80003cf0:	fc045783          	lhu	a5,-64(s0)
    80003cf4:	dfe1                	beqz	a5,80003ccc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cf6:	fc240593          	addi	a1,s0,-62
    80003cfa:	854e                	mv	a0,s3
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	f6c080e7          	jalr	-148(ra) # 80003c68 <namecmp>
    80003d04:	f561                	bnez	a0,80003ccc <dirlookup+0x4a>
      if(poff)
    80003d06:	000a0463          	beqz	s4,80003d0e <dirlookup+0x8c>
        *poff = off;
    80003d0a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d0e:	fc045583          	lhu	a1,-64(s0)
    80003d12:	00092503          	lw	a0,0(s2)
    80003d16:	fffff097          	auipc	ra,0xfffff
    80003d1a:	75a080e7          	jalr	1882(ra) # 80003470 <iget>
    80003d1e:	a011                	j	80003d22 <dirlookup+0xa0>
  return 0;
    80003d20:	4501                	li	a0,0
}
    80003d22:	70e2                	ld	ra,56(sp)
    80003d24:	7442                	ld	s0,48(sp)
    80003d26:	74a2                	ld	s1,40(sp)
    80003d28:	7902                	ld	s2,32(sp)
    80003d2a:	69e2                	ld	s3,24(sp)
    80003d2c:	6a42                	ld	s4,16(sp)
    80003d2e:	6121                	addi	sp,sp,64
    80003d30:	8082                	ret

0000000080003d32 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d32:	711d                	addi	sp,sp,-96
    80003d34:	ec86                	sd	ra,88(sp)
    80003d36:	e8a2                	sd	s0,80(sp)
    80003d38:	e4a6                	sd	s1,72(sp)
    80003d3a:	e0ca                	sd	s2,64(sp)
    80003d3c:	fc4e                	sd	s3,56(sp)
    80003d3e:	f852                	sd	s4,48(sp)
    80003d40:	f456                	sd	s5,40(sp)
    80003d42:	f05a                	sd	s6,32(sp)
    80003d44:	ec5e                	sd	s7,24(sp)
    80003d46:	e862                	sd	s8,16(sp)
    80003d48:	e466                	sd	s9,8(sp)
    80003d4a:	1080                	addi	s0,sp,96
    80003d4c:	84aa                	mv	s1,a0
    80003d4e:	8b2e                	mv	s6,a1
    80003d50:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d52:	00054703          	lbu	a4,0(a0)
    80003d56:	02f00793          	li	a5,47
    80003d5a:	02f70363          	beq	a4,a5,80003d80 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d5e:	ffffe097          	auipc	ra,0xffffe
    80003d62:	ce4080e7          	jalr	-796(ra) # 80001a42 <myproc>
    80003d66:	15053503          	ld	a0,336(a0)
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	9fc080e7          	jalr	-1540(ra) # 80003766 <idup>
    80003d72:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d74:	02f00913          	li	s2,47
  len = path - s;
    80003d78:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d7a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d7c:	4c05                	li	s8,1
    80003d7e:	a865                	j	80003e36 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d80:	4585                	li	a1,1
    80003d82:	4505                	li	a0,1
    80003d84:	fffff097          	auipc	ra,0xfffff
    80003d88:	6ec080e7          	jalr	1772(ra) # 80003470 <iget>
    80003d8c:	89aa                	mv	s3,a0
    80003d8e:	b7dd                	j	80003d74 <namex+0x42>
      iunlockput(ip);
    80003d90:	854e                	mv	a0,s3
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	c74080e7          	jalr	-908(ra) # 80003a06 <iunlockput>
      return 0;
    80003d9a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d9c:	854e                	mv	a0,s3
    80003d9e:	60e6                	ld	ra,88(sp)
    80003da0:	6446                	ld	s0,80(sp)
    80003da2:	64a6                	ld	s1,72(sp)
    80003da4:	6906                	ld	s2,64(sp)
    80003da6:	79e2                	ld	s3,56(sp)
    80003da8:	7a42                	ld	s4,48(sp)
    80003daa:	7aa2                	ld	s5,40(sp)
    80003dac:	7b02                	ld	s6,32(sp)
    80003dae:	6be2                	ld	s7,24(sp)
    80003db0:	6c42                	ld	s8,16(sp)
    80003db2:	6ca2                	ld	s9,8(sp)
    80003db4:	6125                	addi	sp,sp,96
    80003db6:	8082                	ret
      iunlock(ip);
    80003db8:	854e                	mv	a0,s3
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	aac080e7          	jalr	-1364(ra) # 80003866 <iunlock>
      return ip;
    80003dc2:	bfe9                	j	80003d9c <namex+0x6a>
      iunlockput(ip);
    80003dc4:	854e                	mv	a0,s3
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	c40080e7          	jalr	-960(ra) # 80003a06 <iunlockput>
      return 0;
    80003dce:	89d2                	mv	s3,s4
    80003dd0:	b7f1                	j	80003d9c <namex+0x6a>
  len = path - s;
    80003dd2:	40b48633          	sub	a2,s1,a1
    80003dd6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dda:	094cd463          	bge	s9,s4,80003e62 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dde:	4639                	li	a2,14
    80003de0:	8556                	mv	a0,s5
    80003de2:	ffffd097          	auipc	ra,0xffffd
    80003de6:	fee080e7          	jalr	-18(ra) # 80000dd0 <memmove>
  while(*path == '/')
    80003dea:	0004c783          	lbu	a5,0(s1)
    80003dee:	01279763          	bne	a5,s2,80003dfc <namex+0xca>
    path++;
    80003df2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003df4:	0004c783          	lbu	a5,0(s1)
    80003df8:	ff278de3          	beq	a5,s2,80003df2 <namex+0xc0>
    ilock(ip);
    80003dfc:	854e                	mv	a0,s3
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	9a6080e7          	jalr	-1626(ra) # 800037a4 <ilock>
    if(ip->type != T_DIR){
    80003e06:	04499783          	lh	a5,68(s3)
    80003e0a:	f98793e3          	bne	a5,s8,80003d90 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e0e:	000b0563          	beqz	s6,80003e18 <namex+0xe6>
    80003e12:	0004c783          	lbu	a5,0(s1)
    80003e16:	d3cd                	beqz	a5,80003db8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e18:	865e                	mv	a2,s7
    80003e1a:	85d6                	mv	a1,s5
    80003e1c:	854e                	mv	a0,s3
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	e64080e7          	jalr	-412(ra) # 80003c82 <dirlookup>
    80003e26:	8a2a                	mv	s4,a0
    80003e28:	dd51                	beqz	a0,80003dc4 <namex+0x92>
    iunlockput(ip);
    80003e2a:	854e                	mv	a0,s3
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	bda080e7          	jalr	-1062(ra) # 80003a06 <iunlockput>
    ip = next;
    80003e34:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e36:	0004c783          	lbu	a5,0(s1)
    80003e3a:	05279763          	bne	a5,s2,80003e88 <namex+0x156>
    path++;
    80003e3e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e40:	0004c783          	lbu	a5,0(s1)
    80003e44:	ff278de3          	beq	a5,s2,80003e3e <namex+0x10c>
  if(*path == 0)
    80003e48:	c79d                	beqz	a5,80003e76 <namex+0x144>
    path++;
    80003e4a:	85a6                	mv	a1,s1
  len = path - s;
    80003e4c:	8a5e                	mv	s4,s7
    80003e4e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e50:	01278963          	beq	a5,s2,80003e62 <namex+0x130>
    80003e54:	dfbd                	beqz	a5,80003dd2 <namex+0xa0>
    path++;
    80003e56:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e58:	0004c783          	lbu	a5,0(s1)
    80003e5c:	ff279ce3          	bne	a5,s2,80003e54 <namex+0x122>
    80003e60:	bf8d                	j	80003dd2 <namex+0xa0>
    memmove(name, s, len);
    80003e62:	2601                	sext.w	a2,a2
    80003e64:	8556                	mv	a0,s5
    80003e66:	ffffd097          	auipc	ra,0xffffd
    80003e6a:	f6a080e7          	jalr	-150(ra) # 80000dd0 <memmove>
    name[len] = 0;
    80003e6e:	9a56                	add	s4,s4,s5
    80003e70:	000a0023          	sb	zero,0(s4)
    80003e74:	bf9d                	j	80003dea <namex+0xb8>
  if(nameiparent){
    80003e76:	f20b03e3          	beqz	s6,80003d9c <namex+0x6a>
    iput(ip);
    80003e7a:	854e                	mv	a0,s3
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	ae2080e7          	jalr	-1310(ra) # 8000395e <iput>
    return 0;
    80003e84:	4981                	li	s3,0
    80003e86:	bf19                	j	80003d9c <namex+0x6a>
  if(*path == 0)
    80003e88:	d7fd                	beqz	a5,80003e76 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e8a:	0004c783          	lbu	a5,0(s1)
    80003e8e:	85a6                	mv	a1,s1
    80003e90:	b7d1                	j	80003e54 <namex+0x122>

0000000080003e92 <dirlink>:
{
    80003e92:	7139                	addi	sp,sp,-64
    80003e94:	fc06                	sd	ra,56(sp)
    80003e96:	f822                	sd	s0,48(sp)
    80003e98:	f426                	sd	s1,40(sp)
    80003e9a:	f04a                	sd	s2,32(sp)
    80003e9c:	ec4e                	sd	s3,24(sp)
    80003e9e:	e852                	sd	s4,16(sp)
    80003ea0:	0080                	addi	s0,sp,64
    80003ea2:	892a                	mv	s2,a0
    80003ea4:	8a2e                	mv	s4,a1
    80003ea6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ea8:	4601                	li	a2,0
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	dd8080e7          	jalr	-552(ra) # 80003c82 <dirlookup>
    80003eb2:	e93d                	bnez	a0,80003f28 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb4:	04c92483          	lw	s1,76(s2)
    80003eb8:	c49d                	beqz	s1,80003ee6 <dirlink+0x54>
    80003eba:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ebc:	4741                	li	a4,16
    80003ebe:	86a6                	mv	a3,s1
    80003ec0:	fc040613          	addi	a2,s0,-64
    80003ec4:	4581                	li	a1,0
    80003ec6:	854a                	mv	a0,s2
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	b90080e7          	jalr	-1136(ra) # 80003a58 <readi>
    80003ed0:	47c1                	li	a5,16
    80003ed2:	06f51163          	bne	a0,a5,80003f34 <dirlink+0xa2>
    if(de.inum == 0)
    80003ed6:	fc045783          	lhu	a5,-64(s0)
    80003eda:	c791                	beqz	a5,80003ee6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003edc:	24c1                	addiw	s1,s1,16
    80003ede:	04c92783          	lw	a5,76(s2)
    80003ee2:	fcf4ede3          	bltu	s1,a5,80003ebc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ee6:	4639                	li	a2,14
    80003ee8:	85d2                	mv	a1,s4
    80003eea:	fc240513          	addi	a0,s0,-62
    80003eee:	ffffd097          	auipc	ra,0xffffd
    80003ef2:	f9a080e7          	jalr	-102(ra) # 80000e88 <strncpy>
  de.inum = inum;
    80003ef6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003efa:	4741                	li	a4,16
    80003efc:	86a6                	mv	a3,s1
    80003efe:	fc040613          	addi	a2,s0,-64
    80003f02:	4581                	li	a1,0
    80003f04:	854a                	mv	a0,s2
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	c48080e7          	jalr	-952(ra) # 80003b4e <writei>
    80003f0e:	872a                	mv	a4,a0
    80003f10:	47c1                	li	a5,16
  return 0;
    80003f12:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f14:	02f71863          	bne	a4,a5,80003f44 <dirlink+0xb2>
}
    80003f18:	70e2                	ld	ra,56(sp)
    80003f1a:	7442                	ld	s0,48(sp)
    80003f1c:	74a2                	ld	s1,40(sp)
    80003f1e:	7902                	ld	s2,32(sp)
    80003f20:	69e2                	ld	s3,24(sp)
    80003f22:	6a42                	ld	s4,16(sp)
    80003f24:	6121                	addi	sp,sp,64
    80003f26:	8082                	ret
    iput(ip);
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	a36080e7          	jalr	-1482(ra) # 8000395e <iput>
    return -1;
    80003f30:	557d                	li	a0,-1
    80003f32:	b7dd                	j	80003f18 <dirlink+0x86>
      panic("dirlink read");
    80003f34:	00004517          	auipc	a0,0x4
    80003f38:	6d450513          	addi	a0,a0,1748 # 80008608 <syscalls+0x1d8>
    80003f3c:	ffffc097          	auipc	ra,0xffffc
    80003f40:	69a080e7          	jalr	1690(ra) # 800005d6 <panic>
    panic("dirlink");
    80003f44:	00004517          	auipc	a0,0x4
    80003f48:	7e450513          	addi	a0,a0,2020 # 80008728 <syscalls+0x2f8>
    80003f4c:	ffffc097          	auipc	ra,0xffffc
    80003f50:	68a080e7          	jalr	1674(ra) # 800005d6 <panic>

0000000080003f54 <namei>:

struct inode*
namei(char *path)
{
    80003f54:	1101                	addi	sp,sp,-32
    80003f56:	ec06                	sd	ra,24(sp)
    80003f58:	e822                	sd	s0,16(sp)
    80003f5a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f5c:	fe040613          	addi	a2,s0,-32
    80003f60:	4581                	li	a1,0
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	dd0080e7          	jalr	-560(ra) # 80003d32 <namex>
}
    80003f6a:	60e2                	ld	ra,24(sp)
    80003f6c:	6442                	ld	s0,16(sp)
    80003f6e:	6105                	addi	sp,sp,32
    80003f70:	8082                	ret

0000000080003f72 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f72:	1141                	addi	sp,sp,-16
    80003f74:	e406                	sd	ra,8(sp)
    80003f76:	e022                	sd	s0,0(sp)
    80003f78:	0800                	addi	s0,sp,16
    80003f7a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f7c:	4585                	li	a1,1
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	db4080e7          	jalr	-588(ra) # 80003d32 <namex>
}
    80003f86:	60a2                	ld	ra,8(sp)
    80003f88:	6402                	ld	s0,0(sp)
    80003f8a:	0141                	addi	sp,sp,16
    80003f8c:	8082                	ret

0000000080003f8e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f8e:	1101                	addi	sp,sp,-32
    80003f90:	ec06                	sd	ra,24(sp)
    80003f92:	e822                	sd	s0,16(sp)
    80003f94:	e426                	sd	s1,8(sp)
    80003f96:	e04a                	sd	s2,0(sp)
    80003f98:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f9a:	00022917          	auipc	s2,0x22
    80003f9e:	f6e90913          	addi	s2,s2,-146 # 80025f08 <log>
    80003fa2:	01892583          	lw	a1,24(s2)
    80003fa6:	02892503          	lw	a0,40(s2)
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	ff8080e7          	jalr	-8(ra) # 80002fa2 <bread>
    80003fb2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fb4:	02c92683          	lw	a3,44(s2)
    80003fb8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fba:	02d05763          	blez	a3,80003fe8 <write_head+0x5a>
    80003fbe:	00022797          	auipc	a5,0x22
    80003fc2:	f7a78793          	addi	a5,a5,-134 # 80025f38 <log+0x30>
    80003fc6:	05c50713          	addi	a4,a0,92
    80003fca:	36fd                	addiw	a3,a3,-1
    80003fcc:	1682                	slli	a3,a3,0x20
    80003fce:	9281                	srli	a3,a3,0x20
    80003fd0:	068a                	slli	a3,a3,0x2
    80003fd2:	00022617          	auipc	a2,0x22
    80003fd6:	f6a60613          	addi	a2,a2,-150 # 80025f3c <log+0x34>
    80003fda:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fdc:	4390                	lw	a2,0(a5)
    80003fde:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe0:	0791                	addi	a5,a5,4
    80003fe2:	0711                	addi	a4,a4,4
    80003fe4:	fed79ce3          	bne	a5,a3,80003fdc <write_head+0x4e>
  }
  bwrite(buf);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	0aa080e7          	jalr	170(ra) # 80003094 <bwrite>
  brelse(buf);
    80003ff2:	8526                	mv	a0,s1
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	0de080e7          	jalr	222(ra) # 800030d2 <brelse>
}
    80003ffc:	60e2                	ld	ra,24(sp)
    80003ffe:	6442                	ld	s0,16(sp)
    80004000:	64a2                	ld	s1,8(sp)
    80004002:	6902                	ld	s2,0(sp)
    80004004:	6105                	addi	sp,sp,32
    80004006:	8082                	ret

0000000080004008 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004008:	00022797          	auipc	a5,0x22
    8000400c:	f2c7a783          	lw	a5,-212(a5) # 80025f34 <log+0x2c>
    80004010:	0af05663          	blez	a5,800040bc <install_trans+0xb4>
{
    80004014:	7139                	addi	sp,sp,-64
    80004016:	fc06                	sd	ra,56(sp)
    80004018:	f822                	sd	s0,48(sp)
    8000401a:	f426                	sd	s1,40(sp)
    8000401c:	f04a                	sd	s2,32(sp)
    8000401e:	ec4e                	sd	s3,24(sp)
    80004020:	e852                	sd	s4,16(sp)
    80004022:	e456                	sd	s5,8(sp)
    80004024:	0080                	addi	s0,sp,64
    80004026:	00022a97          	auipc	s5,0x22
    8000402a:	f12a8a93          	addi	s5,s5,-238 # 80025f38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000402e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004030:	00022997          	auipc	s3,0x22
    80004034:	ed898993          	addi	s3,s3,-296 # 80025f08 <log>
    80004038:	0189a583          	lw	a1,24(s3)
    8000403c:	014585bb          	addw	a1,a1,s4
    80004040:	2585                	addiw	a1,a1,1
    80004042:	0289a503          	lw	a0,40(s3)
    80004046:	fffff097          	auipc	ra,0xfffff
    8000404a:	f5c080e7          	jalr	-164(ra) # 80002fa2 <bread>
    8000404e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004050:	000aa583          	lw	a1,0(s5)
    80004054:	0289a503          	lw	a0,40(s3)
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	f4a080e7          	jalr	-182(ra) # 80002fa2 <bread>
    80004060:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004062:	40000613          	li	a2,1024
    80004066:	05890593          	addi	a1,s2,88
    8000406a:	05850513          	addi	a0,a0,88
    8000406e:	ffffd097          	auipc	ra,0xffffd
    80004072:	d62080e7          	jalr	-670(ra) # 80000dd0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004076:	8526                	mv	a0,s1
    80004078:	fffff097          	auipc	ra,0xfffff
    8000407c:	01c080e7          	jalr	28(ra) # 80003094 <bwrite>
    bunpin(dbuf);
    80004080:	8526                	mv	a0,s1
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	12a080e7          	jalr	298(ra) # 800031ac <bunpin>
    brelse(lbuf);
    8000408a:	854a                	mv	a0,s2
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	046080e7          	jalr	70(ra) # 800030d2 <brelse>
    brelse(dbuf);
    80004094:	8526                	mv	a0,s1
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	03c080e7          	jalr	60(ra) # 800030d2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000409e:	2a05                	addiw	s4,s4,1
    800040a0:	0a91                	addi	s5,s5,4
    800040a2:	02c9a783          	lw	a5,44(s3)
    800040a6:	f8fa49e3          	blt	s4,a5,80004038 <install_trans+0x30>
}
    800040aa:	70e2                	ld	ra,56(sp)
    800040ac:	7442                	ld	s0,48(sp)
    800040ae:	74a2                	ld	s1,40(sp)
    800040b0:	7902                	ld	s2,32(sp)
    800040b2:	69e2                	ld	s3,24(sp)
    800040b4:	6a42                	ld	s4,16(sp)
    800040b6:	6aa2                	ld	s5,8(sp)
    800040b8:	6121                	addi	sp,sp,64
    800040ba:	8082                	ret
    800040bc:	8082                	ret

00000000800040be <initlog>:
{
    800040be:	7179                	addi	sp,sp,-48
    800040c0:	f406                	sd	ra,40(sp)
    800040c2:	f022                	sd	s0,32(sp)
    800040c4:	ec26                	sd	s1,24(sp)
    800040c6:	e84a                	sd	s2,16(sp)
    800040c8:	e44e                	sd	s3,8(sp)
    800040ca:	1800                	addi	s0,sp,48
    800040cc:	892a                	mv	s2,a0
    800040ce:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040d0:	00022497          	auipc	s1,0x22
    800040d4:	e3848493          	addi	s1,s1,-456 # 80025f08 <log>
    800040d8:	00004597          	auipc	a1,0x4
    800040dc:	54058593          	addi	a1,a1,1344 # 80008618 <syscalls+0x1e8>
    800040e0:	8526                	mv	a0,s1
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	b02080e7          	jalr	-1278(ra) # 80000be4 <initlock>
  log.start = sb->logstart;
    800040ea:	0149a583          	lw	a1,20(s3)
    800040ee:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040f0:	0109a783          	lw	a5,16(s3)
    800040f4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040f6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040fa:	854a                	mv	a0,s2
    800040fc:	fffff097          	auipc	ra,0xfffff
    80004100:	ea6080e7          	jalr	-346(ra) # 80002fa2 <bread>
  log.lh.n = lh->n;
    80004104:	4d3c                	lw	a5,88(a0)
    80004106:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004108:	02f05563          	blez	a5,80004132 <initlog+0x74>
    8000410c:	05c50713          	addi	a4,a0,92
    80004110:	00022697          	auipc	a3,0x22
    80004114:	e2868693          	addi	a3,a3,-472 # 80025f38 <log+0x30>
    80004118:	37fd                	addiw	a5,a5,-1
    8000411a:	1782                	slli	a5,a5,0x20
    8000411c:	9381                	srli	a5,a5,0x20
    8000411e:	078a                	slli	a5,a5,0x2
    80004120:	06050613          	addi	a2,a0,96
    80004124:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004126:	4310                	lw	a2,0(a4)
    80004128:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000412a:	0711                	addi	a4,a4,4
    8000412c:	0691                	addi	a3,a3,4
    8000412e:	fef71ce3          	bne	a4,a5,80004126 <initlog+0x68>
  brelse(buf);
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	fa0080e7          	jalr	-96(ra) # 800030d2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	ece080e7          	jalr	-306(ra) # 80004008 <install_trans>
  log.lh.n = 0;
    80004142:	00022797          	auipc	a5,0x22
    80004146:	de07a923          	sw	zero,-526(a5) # 80025f34 <log+0x2c>
  write_head(); // clear the log
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	e44080e7          	jalr	-444(ra) # 80003f8e <write_head>
}
    80004152:	70a2                	ld	ra,40(sp)
    80004154:	7402                	ld	s0,32(sp)
    80004156:	64e2                	ld	s1,24(sp)
    80004158:	6942                	ld	s2,16(sp)
    8000415a:	69a2                	ld	s3,8(sp)
    8000415c:	6145                	addi	sp,sp,48
    8000415e:	8082                	ret

0000000080004160 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004160:	1101                	addi	sp,sp,-32
    80004162:	ec06                	sd	ra,24(sp)
    80004164:	e822                	sd	s0,16(sp)
    80004166:	e426                	sd	s1,8(sp)
    80004168:	e04a                	sd	s2,0(sp)
    8000416a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000416c:	00022517          	auipc	a0,0x22
    80004170:	d9c50513          	addi	a0,a0,-612 # 80025f08 <log>
    80004174:	ffffd097          	auipc	ra,0xffffd
    80004178:	b00080e7          	jalr	-1280(ra) # 80000c74 <acquire>
  while(1){
    if(log.committing){
    8000417c:	00022497          	auipc	s1,0x22
    80004180:	d8c48493          	addi	s1,s1,-628 # 80025f08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004184:	4979                	li	s2,30
    80004186:	a039                	j	80004194 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004188:	85a6                	mv	a1,s1
    8000418a:	8526                	mv	a0,s1
    8000418c:	ffffe097          	auipc	ra,0xffffe
    80004190:	0d4080e7          	jalr	212(ra) # 80002260 <sleep>
    if(log.committing){
    80004194:	50dc                	lw	a5,36(s1)
    80004196:	fbed                	bnez	a5,80004188 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004198:	509c                	lw	a5,32(s1)
    8000419a:	0017871b          	addiw	a4,a5,1
    8000419e:	0007069b          	sext.w	a3,a4
    800041a2:	0027179b          	slliw	a5,a4,0x2
    800041a6:	9fb9                	addw	a5,a5,a4
    800041a8:	0017979b          	slliw	a5,a5,0x1
    800041ac:	54d8                	lw	a4,44(s1)
    800041ae:	9fb9                	addw	a5,a5,a4
    800041b0:	00f95963          	bge	s2,a5,800041c2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041b4:	85a6                	mv	a1,s1
    800041b6:	8526                	mv	a0,s1
    800041b8:	ffffe097          	auipc	ra,0xffffe
    800041bc:	0a8080e7          	jalr	168(ra) # 80002260 <sleep>
    800041c0:	bfd1                	j	80004194 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041c2:	00022517          	auipc	a0,0x22
    800041c6:	d4650513          	addi	a0,a0,-698 # 80025f08 <log>
    800041ca:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	b5c080e7          	jalr	-1188(ra) # 80000d28 <release>
      break;
    }
  }
}
    800041d4:	60e2                	ld	ra,24(sp)
    800041d6:	6442                	ld	s0,16(sp)
    800041d8:	64a2                	ld	s1,8(sp)
    800041da:	6902                	ld	s2,0(sp)
    800041dc:	6105                	addi	sp,sp,32
    800041de:	8082                	ret

00000000800041e0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041e0:	7139                	addi	sp,sp,-64
    800041e2:	fc06                	sd	ra,56(sp)
    800041e4:	f822                	sd	s0,48(sp)
    800041e6:	f426                	sd	s1,40(sp)
    800041e8:	f04a                	sd	s2,32(sp)
    800041ea:	ec4e                	sd	s3,24(sp)
    800041ec:	e852                	sd	s4,16(sp)
    800041ee:	e456                	sd	s5,8(sp)
    800041f0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041f2:	00022497          	auipc	s1,0x22
    800041f6:	d1648493          	addi	s1,s1,-746 # 80025f08 <log>
    800041fa:	8526                	mv	a0,s1
    800041fc:	ffffd097          	auipc	ra,0xffffd
    80004200:	a78080e7          	jalr	-1416(ra) # 80000c74 <acquire>
  log.outstanding -= 1;
    80004204:	509c                	lw	a5,32(s1)
    80004206:	37fd                	addiw	a5,a5,-1
    80004208:	0007891b          	sext.w	s2,a5
    8000420c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000420e:	50dc                	lw	a5,36(s1)
    80004210:	efb9                	bnez	a5,8000426e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004212:	06091663          	bnez	s2,8000427e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004216:	00022497          	auipc	s1,0x22
    8000421a:	cf248493          	addi	s1,s1,-782 # 80025f08 <log>
    8000421e:	4785                	li	a5,1
    80004220:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004222:	8526                	mv	a0,s1
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	b04080e7          	jalr	-1276(ra) # 80000d28 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000422c:	54dc                	lw	a5,44(s1)
    8000422e:	06f04763          	bgtz	a5,8000429c <end_op+0xbc>
    acquire(&log.lock);
    80004232:	00022497          	auipc	s1,0x22
    80004236:	cd648493          	addi	s1,s1,-810 # 80025f08 <log>
    8000423a:	8526                	mv	a0,s1
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	a38080e7          	jalr	-1480(ra) # 80000c74 <acquire>
    log.committing = 0;
    80004244:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004248:	8526                	mv	a0,s1
    8000424a:	ffffe097          	auipc	ra,0xffffe
    8000424e:	19c080e7          	jalr	412(ra) # 800023e6 <wakeup>
    release(&log.lock);
    80004252:	8526                	mv	a0,s1
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	ad4080e7          	jalr	-1324(ra) # 80000d28 <release>
}
    8000425c:	70e2                	ld	ra,56(sp)
    8000425e:	7442                	ld	s0,48(sp)
    80004260:	74a2                	ld	s1,40(sp)
    80004262:	7902                	ld	s2,32(sp)
    80004264:	69e2                	ld	s3,24(sp)
    80004266:	6a42                	ld	s4,16(sp)
    80004268:	6aa2                	ld	s5,8(sp)
    8000426a:	6121                	addi	sp,sp,64
    8000426c:	8082                	ret
    panic("log.committing");
    8000426e:	00004517          	auipc	a0,0x4
    80004272:	3b250513          	addi	a0,a0,946 # 80008620 <syscalls+0x1f0>
    80004276:	ffffc097          	auipc	ra,0xffffc
    8000427a:	360080e7          	jalr	864(ra) # 800005d6 <panic>
    wakeup(&log);
    8000427e:	00022497          	auipc	s1,0x22
    80004282:	c8a48493          	addi	s1,s1,-886 # 80025f08 <log>
    80004286:	8526                	mv	a0,s1
    80004288:	ffffe097          	auipc	ra,0xffffe
    8000428c:	15e080e7          	jalr	350(ra) # 800023e6 <wakeup>
  release(&log.lock);
    80004290:	8526                	mv	a0,s1
    80004292:	ffffd097          	auipc	ra,0xffffd
    80004296:	a96080e7          	jalr	-1386(ra) # 80000d28 <release>
  if(do_commit){
    8000429a:	b7c9                	j	8000425c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429c:	00022a97          	auipc	s5,0x22
    800042a0:	c9ca8a93          	addi	s5,s5,-868 # 80025f38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042a4:	00022a17          	auipc	s4,0x22
    800042a8:	c64a0a13          	addi	s4,s4,-924 # 80025f08 <log>
    800042ac:	018a2583          	lw	a1,24(s4)
    800042b0:	012585bb          	addw	a1,a1,s2
    800042b4:	2585                	addiw	a1,a1,1
    800042b6:	028a2503          	lw	a0,40(s4)
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	ce8080e7          	jalr	-792(ra) # 80002fa2 <bread>
    800042c2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042c4:	000aa583          	lw	a1,0(s5)
    800042c8:	028a2503          	lw	a0,40(s4)
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	cd6080e7          	jalr	-810(ra) # 80002fa2 <bread>
    800042d4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042d6:	40000613          	li	a2,1024
    800042da:	05850593          	addi	a1,a0,88
    800042de:	05848513          	addi	a0,s1,88
    800042e2:	ffffd097          	auipc	ra,0xffffd
    800042e6:	aee080e7          	jalr	-1298(ra) # 80000dd0 <memmove>
    bwrite(to);  // write the log
    800042ea:	8526                	mv	a0,s1
    800042ec:	fffff097          	auipc	ra,0xfffff
    800042f0:	da8080e7          	jalr	-600(ra) # 80003094 <bwrite>
    brelse(from);
    800042f4:	854e                	mv	a0,s3
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	ddc080e7          	jalr	-548(ra) # 800030d2 <brelse>
    brelse(to);
    800042fe:	8526                	mv	a0,s1
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	dd2080e7          	jalr	-558(ra) # 800030d2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004308:	2905                	addiw	s2,s2,1
    8000430a:	0a91                	addi	s5,s5,4
    8000430c:	02ca2783          	lw	a5,44(s4)
    80004310:	f8f94ee3          	blt	s2,a5,800042ac <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004314:	00000097          	auipc	ra,0x0
    80004318:	c7a080e7          	jalr	-902(ra) # 80003f8e <write_head>
    install_trans(); // Now install writes to home locations
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	cec080e7          	jalr	-788(ra) # 80004008 <install_trans>
    log.lh.n = 0;
    80004324:	00022797          	auipc	a5,0x22
    80004328:	c007a823          	sw	zero,-1008(a5) # 80025f34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	c62080e7          	jalr	-926(ra) # 80003f8e <write_head>
    80004334:	bdfd                	j	80004232 <end_op+0x52>

0000000080004336 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004336:	1101                	addi	sp,sp,-32
    80004338:	ec06                	sd	ra,24(sp)
    8000433a:	e822                	sd	s0,16(sp)
    8000433c:	e426                	sd	s1,8(sp)
    8000433e:	e04a                	sd	s2,0(sp)
    80004340:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004342:	00022717          	auipc	a4,0x22
    80004346:	bf272703          	lw	a4,-1038(a4) # 80025f34 <log+0x2c>
    8000434a:	47f5                	li	a5,29
    8000434c:	08e7c063          	blt	a5,a4,800043cc <log_write+0x96>
    80004350:	84aa                	mv	s1,a0
    80004352:	00022797          	auipc	a5,0x22
    80004356:	bd27a783          	lw	a5,-1070(a5) # 80025f24 <log+0x1c>
    8000435a:	37fd                	addiw	a5,a5,-1
    8000435c:	06f75863          	bge	a4,a5,800043cc <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004360:	00022797          	auipc	a5,0x22
    80004364:	bc87a783          	lw	a5,-1080(a5) # 80025f28 <log+0x20>
    80004368:	06f05a63          	blez	a5,800043dc <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000436c:	00022917          	auipc	s2,0x22
    80004370:	b9c90913          	addi	s2,s2,-1124 # 80025f08 <log>
    80004374:	854a                	mv	a0,s2
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	8fe080e7          	jalr	-1794(ra) # 80000c74 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000437e:	02c92603          	lw	a2,44(s2)
    80004382:	06c05563          	blez	a2,800043ec <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004386:	44cc                	lw	a1,12(s1)
    80004388:	00022717          	auipc	a4,0x22
    8000438c:	bb070713          	addi	a4,a4,-1104 # 80025f38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004390:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004392:	4314                	lw	a3,0(a4)
    80004394:	04b68d63          	beq	a3,a1,800043ee <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004398:	2785                	addiw	a5,a5,1
    8000439a:	0711                	addi	a4,a4,4
    8000439c:	fec79be3          	bne	a5,a2,80004392 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043a0:	0621                	addi	a2,a2,8
    800043a2:	060a                	slli	a2,a2,0x2
    800043a4:	00022797          	auipc	a5,0x22
    800043a8:	b6478793          	addi	a5,a5,-1180 # 80025f08 <log>
    800043ac:	963e                	add	a2,a2,a5
    800043ae:	44dc                	lw	a5,12(s1)
    800043b0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043b2:	8526                	mv	a0,s1
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	dbc080e7          	jalr	-580(ra) # 80003170 <bpin>
    log.lh.n++;
    800043bc:	00022717          	auipc	a4,0x22
    800043c0:	b4c70713          	addi	a4,a4,-1204 # 80025f08 <log>
    800043c4:	575c                	lw	a5,44(a4)
    800043c6:	2785                	addiw	a5,a5,1
    800043c8:	d75c                	sw	a5,44(a4)
    800043ca:	a83d                	j	80004408 <log_write+0xd2>
    panic("too big a transaction");
    800043cc:	00004517          	auipc	a0,0x4
    800043d0:	26450513          	addi	a0,a0,612 # 80008630 <syscalls+0x200>
    800043d4:	ffffc097          	auipc	ra,0xffffc
    800043d8:	202080e7          	jalr	514(ra) # 800005d6 <panic>
    panic("log_write outside of trans");
    800043dc:	00004517          	auipc	a0,0x4
    800043e0:	26c50513          	addi	a0,a0,620 # 80008648 <syscalls+0x218>
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	1f2080e7          	jalr	498(ra) # 800005d6 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800043ec:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800043ee:	00878713          	addi	a4,a5,8
    800043f2:	00271693          	slli	a3,a4,0x2
    800043f6:	00022717          	auipc	a4,0x22
    800043fa:	b1270713          	addi	a4,a4,-1262 # 80025f08 <log>
    800043fe:	9736                	add	a4,a4,a3
    80004400:	44d4                	lw	a3,12(s1)
    80004402:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004404:	faf607e3          	beq	a2,a5,800043b2 <log_write+0x7c>
  }
  release(&log.lock);
    80004408:	00022517          	auipc	a0,0x22
    8000440c:	b0050513          	addi	a0,a0,-1280 # 80025f08 <log>
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	918080e7          	jalr	-1768(ra) # 80000d28 <release>
}
    80004418:	60e2                	ld	ra,24(sp)
    8000441a:	6442                	ld	s0,16(sp)
    8000441c:	64a2                	ld	s1,8(sp)
    8000441e:	6902                	ld	s2,0(sp)
    80004420:	6105                	addi	sp,sp,32
    80004422:	8082                	ret

0000000080004424 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004424:	1101                	addi	sp,sp,-32
    80004426:	ec06                	sd	ra,24(sp)
    80004428:	e822                	sd	s0,16(sp)
    8000442a:	e426                	sd	s1,8(sp)
    8000442c:	e04a                	sd	s2,0(sp)
    8000442e:	1000                	addi	s0,sp,32
    80004430:	84aa                	mv	s1,a0
    80004432:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004434:	00004597          	auipc	a1,0x4
    80004438:	23458593          	addi	a1,a1,564 # 80008668 <syscalls+0x238>
    8000443c:	0521                	addi	a0,a0,8
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	7a6080e7          	jalr	1958(ra) # 80000be4 <initlock>
  lk->name = name;
    80004446:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000444a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000444e:	0204a423          	sw	zero,40(s1)
}
    80004452:	60e2                	ld	ra,24(sp)
    80004454:	6442                	ld	s0,16(sp)
    80004456:	64a2                	ld	s1,8(sp)
    80004458:	6902                	ld	s2,0(sp)
    8000445a:	6105                	addi	sp,sp,32
    8000445c:	8082                	ret

000000008000445e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000445e:	1101                	addi	sp,sp,-32
    80004460:	ec06                	sd	ra,24(sp)
    80004462:	e822                	sd	s0,16(sp)
    80004464:	e426                	sd	s1,8(sp)
    80004466:	e04a                	sd	s2,0(sp)
    80004468:	1000                	addi	s0,sp,32
    8000446a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000446c:	00850913          	addi	s2,a0,8
    80004470:	854a                	mv	a0,s2
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	802080e7          	jalr	-2046(ra) # 80000c74 <acquire>
  while (lk->locked) {
    8000447a:	409c                	lw	a5,0(s1)
    8000447c:	cb89                	beqz	a5,8000448e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000447e:	85ca                	mv	a1,s2
    80004480:	8526                	mv	a0,s1
    80004482:	ffffe097          	auipc	ra,0xffffe
    80004486:	dde080e7          	jalr	-546(ra) # 80002260 <sleep>
  while (lk->locked) {
    8000448a:	409c                	lw	a5,0(s1)
    8000448c:	fbed                	bnez	a5,8000447e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000448e:	4785                	li	a5,1
    80004490:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	5b0080e7          	jalr	1456(ra) # 80001a42 <myproc>
    8000449a:	5d1c                	lw	a5,56(a0)
    8000449c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000449e:	854a                	mv	a0,s2
    800044a0:	ffffd097          	auipc	ra,0xffffd
    800044a4:	888080e7          	jalr	-1912(ra) # 80000d28 <release>
}
    800044a8:	60e2                	ld	ra,24(sp)
    800044aa:	6442                	ld	s0,16(sp)
    800044ac:	64a2                	ld	s1,8(sp)
    800044ae:	6902                	ld	s2,0(sp)
    800044b0:	6105                	addi	sp,sp,32
    800044b2:	8082                	ret

00000000800044b4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044b4:	1101                	addi	sp,sp,-32
    800044b6:	ec06                	sd	ra,24(sp)
    800044b8:	e822                	sd	s0,16(sp)
    800044ba:	e426                	sd	s1,8(sp)
    800044bc:	e04a                	sd	s2,0(sp)
    800044be:	1000                	addi	s0,sp,32
    800044c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044c2:	00850913          	addi	s2,a0,8
    800044c6:	854a                	mv	a0,s2
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	7ac080e7          	jalr	1964(ra) # 80000c74 <acquire>
  lk->locked = 0;
    800044d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044d4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044d8:	8526                	mv	a0,s1
    800044da:	ffffe097          	auipc	ra,0xffffe
    800044de:	f0c080e7          	jalr	-244(ra) # 800023e6 <wakeup>
  release(&lk->lk);
    800044e2:	854a                	mv	a0,s2
    800044e4:	ffffd097          	auipc	ra,0xffffd
    800044e8:	844080e7          	jalr	-1980(ra) # 80000d28 <release>
}
    800044ec:	60e2                	ld	ra,24(sp)
    800044ee:	6442                	ld	s0,16(sp)
    800044f0:	64a2                	ld	s1,8(sp)
    800044f2:	6902                	ld	s2,0(sp)
    800044f4:	6105                	addi	sp,sp,32
    800044f6:	8082                	ret

00000000800044f8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044f8:	7179                	addi	sp,sp,-48
    800044fa:	f406                	sd	ra,40(sp)
    800044fc:	f022                	sd	s0,32(sp)
    800044fe:	ec26                	sd	s1,24(sp)
    80004500:	e84a                	sd	s2,16(sp)
    80004502:	e44e                	sd	s3,8(sp)
    80004504:	1800                	addi	s0,sp,48
    80004506:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004508:	00850913          	addi	s2,a0,8
    8000450c:	854a                	mv	a0,s2
    8000450e:	ffffc097          	auipc	ra,0xffffc
    80004512:	766080e7          	jalr	1894(ra) # 80000c74 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004516:	409c                	lw	a5,0(s1)
    80004518:	ef99                	bnez	a5,80004536 <holdingsleep+0x3e>
    8000451a:	4481                	li	s1,0
  release(&lk->lk);
    8000451c:	854a                	mv	a0,s2
    8000451e:	ffffd097          	auipc	ra,0xffffd
    80004522:	80a080e7          	jalr	-2038(ra) # 80000d28 <release>
  return r;
}
    80004526:	8526                	mv	a0,s1
    80004528:	70a2                	ld	ra,40(sp)
    8000452a:	7402                	ld	s0,32(sp)
    8000452c:	64e2                	ld	s1,24(sp)
    8000452e:	6942                	ld	s2,16(sp)
    80004530:	69a2                	ld	s3,8(sp)
    80004532:	6145                	addi	sp,sp,48
    80004534:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004536:	0284a983          	lw	s3,40(s1)
    8000453a:	ffffd097          	auipc	ra,0xffffd
    8000453e:	508080e7          	jalr	1288(ra) # 80001a42 <myproc>
    80004542:	5d04                	lw	s1,56(a0)
    80004544:	413484b3          	sub	s1,s1,s3
    80004548:	0014b493          	seqz	s1,s1
    8000454c:	bfc1                	j	8000451c <holdingsleep+0x24>

000000008000454e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000454e:	1141                	addi	sp,sp,-16
    80004550:	e406                	sd	ra,8(sp)
    80004552:	e022                	sd	s0,0(sp)
    80004554:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004556:	00004597          	auipc	a1,0x4
    8000455a:	12258593          	addi	a1,a1,290 # 80008678 <syscalls+0x248>
    8000455e:	00022517          	auipc	a0,0x22
    80004562:	af250513          	addi	a0,a0,-1294 # 80026050 <ftable>
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	67e080e7          	jalr	1662(ra) # 80000be4 <initlock>
}
    8000456e:	60a2                	ld	ra,8(sp)
    80004570:	6402                	ld	s0,0(sp)
    80004572:	0141                	addi	sp,sp,16
    80004574:	8082                	ret

0000000080004576 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004576:	1101                	addi	sp,sp,-32
    80004578:	ec06                	sd	ra,24(sp)
    8000457a:	e822                	sd	s0,16(sp)
    8000457c:	e426                	sd	s1,8(sp)
    8000457e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004580:	00022517          	auipc	a0,0x22
    80004584:	ad050513          	addi	a0,a0,-1328 # 80026050 <ftable>
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	6ec080e7          	jalr	1772(ra) # 80000c74 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004590:	00022497          	auipc	s1,0x22
    80004594:	ad848493          	addi	s1,s1,-1320 # 80026068 <ftable+0x18>
    80004598:	00023717          	auipc	a4,0x23
    8000459c:	a7070713          	addi	a4,a4,-1424 # 80027008 <ftable+0xfb8>
    if(f->ref == 0){
    800045a0:	40dc                	lw	a5,4(s1)
    800045a2:	cf99                	beqz	a5,800045c0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a4:	02848493          	addi	s1,s1,40
    800045a8:	fee49ce3          	bne	s1,a4,800045a0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045ac:	00022517          	auipc	a0,0x22
    800045b0:	aa450513          	addi	a0,a0,-1372 # 80026050 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	774080e7          	jalr	1908(ra) # 80000d28 <release>
  return 0;
    800045bc:	4481                	li	s1,0
    800045be:	a819                	j	800045d4 <filealloc+0x5e>
      f->ref = 1;
    800045c0:	4785                	li	a5,1
    800045c2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045c4:	00022517          	auipc	a0,0x22
    800045c8:	a8c50513          	addi	a0,a0,-1396 # 80026050 <ftable>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	75c080e7          	jalr	1884(ra) # 80000d28 <release>
}
    800045d4:	8526                	mv	a0,s1
    800045d6:	60e2                	ld	ra,24(sp)
    800045d8:	6442                	ld	s0,16(sp)
    800045da:	64a2                	ld	s1,8(sp)
    800045dc:	6105                	addi	sp,sp,32
    800045de:	8082                	ret

00000000800045e0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045e0:	1101                	addi	sp,sp,-32
    800045e2:	ec06                	sd	ra,24(sp)
    800045e4:	e822                	sd	s0,16(sp)
    800045e6:	e426                	sd	s1,8(sp)
    800045e8:	1000                	addi	s0,sp,32
    800045ea:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045ec:	00022517          	auipc	a0,0x22
    800045f0:	a6450513          	addi	a0,a0,-1436 # 80026050 <ftable>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	680080e7          	jalr	1664(ra) # 80000c74 <acquire>
  if(f->ref < 1)
    800045fc:	40dc                	lw	a5,4(s1)
    800045fe:	02f05263          	blez	a5,80004622 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004602:	2785                	addiw	a5,a5,1
    80004604:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004606:	00022517          	auipc	a0,0x22
    8000460a:	a4a50513          	addi	a0,a0,-1462 # 80026050 <ftable>
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	71a080e7          	jalr	1818(ra) # 80000d28 <release>
  return f;
}
    80004616:	8526                	mv	a0,s1
    80004618:	60e2                	ld	ra,24(sp)
    8000461a:	6442                	ld	s0,16(sp)
    8000461c:	64a2                	ld	s1,8(sp)
    8000461e:	6105                	addi	sp,sp,32
    80004620:	8082                	ret
    panic("filedup");
    80004622:	00004517          	auipc	a0,0x4
    80004626:	05e50513          	addi	a0,a0,94 # 80008680 <syscalls+0x250>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	fac080e7          	jalr	-84(ra) # 800005d6 <panic>

0000000080004632 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004632:	7139                	addi	sp,sp,-64
    80004634:	fc06                	sd	ra,56(sp)
    80004636:	f822                	sd	s0,48(sp)
    80004638:	f426                	sd	s1,40(sp)
    8000463a:	f04a                	sd	s2,32(sp)
    8000463c:	ec4e                	sd	s3,24(sp)
    8000463e:	e852                	sd	s4,16(sp)
    80004640:	e456                	sd	s5,8(sp)
    80004642:	0080                	addi	s0,sp,64
    80004644:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004646:	00022517          	auipc	a0,0x22
    8000464a:	a0a50513          	addi	a0,a0,-1526 # 80026050 <ftable>
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	626080e7          	jalr	1574(ra) # 80000c74 <acquire>
  if(f->ref < 1)
    80004656:	40dc                	lw	a5,4(s1)
    80004658:	06f05163          	blez	a5,800046ba <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000465c:	37fd                	addiw	a5,a5,-1
    8000465e:	0007871b          	sext.w	a4,a5
    80004662:	c0dc                	sw	a5,4(s1)
    80004664:	06e04363          	bgtz	a4,800046ca <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004668:	0004a903          	lw	s2,0(s1)
    8000466c:	0094ca83          	lbu	s5,9(s1)
    80004670:	0104ba03          	ld	s4,16(s1)
    80004674:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004678:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000467c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004680:	00022517          	auipc	a0,0x22
    80004684:	9d050513          	addi	a0,a0,-1584 # 80026050 <ftable>
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	6a0080e7          	jalr	1696(ra) # 80000d28 <release>

  if(ff.type == FD_PIPE){
    80004690:	4785                	li	a5,1
    80004692:	04f90d63          	beq	s2,a5,800046ec <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004696:	3979                	addiw	s2,s2,-2
    80004698:	4785                	li	a5,1
    8000469a:	0527e063          	bltu	a5,s2,800046da <fileclose+0xa8>
    begin_op();
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	ac2080e7          	jalr	-1342(ra) # 80004160 <begin_op>
    iput(ff.ip);
    800046a6:	854e                	mv	a0,s3
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	2b6080e7          	jalr	694(ra) # 8000395e <iput>
    end_op();
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	b30080e7          	jalr	-1232(ra) # 800041e0 <end_op>
    800046b8:	a00d                	j	800046da <fileclose+0xa8>
    panic("fileclose");
    800046ba:	00004517          	auipc	a0,0x4
    800046be:	fce50513          	addi	a0,a0,-50 # 80008688 <syscalls+0x258>
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	f14080e7          	jalr	-236(ra) # 800005d6 <panic>
    release(&ftable.lock);
    800046ca:	00022517          	auipc	a0,0x22
    800046ce:	98650513          	addi	a0,a0,-1658 # 80026050 <ftable>
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	656080e7          	jalr	1622(ra) # 80000d28 <release>
  }
}
    800046da:	70e2                	ld	ra,56(sp)
    800046dc:	7442                	ld	s0,48(sp)
    800046de:	74a2                	ld	s1,40(sp)
    800046e0:	7902                	ld	s2,32(sp)
    800046e2:	69e2                	ld	s3,24(sp)
    800046e4:	6a42                	ld	s4,16(sp)
    800046e6:	6aa2                	ld	s5,8(sp)
    800046e8:	6121                	addi	sp,sp,64
    800046ea:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046ec:	85d6                	mv	a1,s5
    800046ee:	8552                	mv	a0,s4
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	372080e7          	jalr	882(ra) # 80004a62 <pipeclose>
    800046f8:	b7cd                	j	800046da <fileclose+0xa8>

00000000800046fa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046fa:	715d                	addi	sp,sp,-80
    800046fc:	e486                	sd	ra,72(sp)
    800046fe:	e0a2                	sd	s0,64(sp)
    80004700:	fc26                	sd	s1,56(sp)
    80004702:	f84a                	sd	s2,48(sp)
    80004704:	f44e                	sd	s3,40(sp)
    80004706:	0880                	addi	s0,sp,80
    80004708:	84aa                	mv	s1,a0
    8000470a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000470c:	ffffd097          	auipc	ra,0xffffd
    80004710:	336080e7          	jalr	822(ra) # 80001a42 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004714:	409c                	lw	a5,0(s1)
    80004716:	37f9                	addiw	a5,a5,-2
    80004718:	4705                	li	a4,1
    8000471a:	04f76763          	bltu	a4,a5,80004768 <filestat+0x6e>
    8000471e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004720:	6c88                	ld	a0,24(s1)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	082080e7          	jalr	130(ra) # 800037a4 <ilock>
    stati(f->ip, &st);
    8000472a:	fb840593          	addi	a1,s0,-72
    8000472e:	6c88                	ld	a0,24(s1)
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	2fe080e7          	jalr	766(ra) # 80003a2e <stati>
    iunlock(f->ip);
    80004738:	6c88                	ld	a0,24(s1)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	12c080e7          	jalr	300(ra) # 80003866 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004742:	46e1                	li	a3,24
    80004744:	fb840613          	addi	a2,s0,-72
    80004748:	85ce                	mv	a1,s3
    8000474a:	05093503          	ld	a0,80(s2)
    8000474e:	ffffd097          	auipc	ra,0xffffd
    80004752:	fe8080e7          	jalr	-24(ra) # 80001736 <copyout>
    80004756:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000475a:	60a6                	ld	ra,72(sp)
    8000475c:	6406                	ld	s0,64(sp)
    8000475e:	74e2                	ld	s1,56(sp)
    80004760:	7942                	ld	s2,48(sp)
    80004762:	79a2                	ld	s3,40(sp)
    80004764:	6161                	addi	sp,sp,80
    80004766:	8082                	ret
  return -1;
    80004768:	557d                	li	a0,-1
    8000476a:	bfc5                	j	8000475a <filestat+0x60>

000000008000476c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000476c:	7179                	addi	sp,sp,-48
    8000476e:	f406                	sd	ra,40(sp)
    80004770:	f022                	sd	s0,32(sp)
    80004772:	ec26                	sd	s1,24(sp)
    80004774:	e84a                	sd	s2,16(sp)
    80004776:	e44e                	sd	s3,8(sp)
    80004778:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000477a:	00854783          	lbu	a5,8(a0)
    8000477e:	c3d5                	beqz	a5,80004822 <fileread+0xb6>
    80004780:	84aa                	mv	s1,a0
    80004782:	89ae                	mv	s3,a1
    80004784:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004786:	411c                	lw	a5,0(a0)
    80004788:	4705                	li	a4,1
    8000478a:	04e78963          	beq	a5,a4,800047dc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000478e:	470d                	li	a4,3
    80004790:	04e78d63          	beq	a5,a4,800047ea <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004794:	4709                	li	a4,2
    80004796:	06e79e63          	bne	a5,a4,80004812 <fileread+0xa6>
    ilock(f->ip);
    8000479a:	6d08                	ld	a0,24(a0)
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	008080e7          	jalr	8(ra) # 800037a4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047a4:	874a                	mv	a4,s2
    800047a6:	5094                	lw	a3,32(s1)
    800047a8:	864e                	mv	a2,s3
    800047aa:	4585                	li	a1,1
    800047ac:	6c88                	ld	a0,24(s1)
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	2aa080e7          	jalr	682(ra) # 80003a58 <readi>
    800047b6:	892a                	mv	s2,a0
    800047b8:	00a05563          	blez	a0,800047c2 <fileread+0x56>
      f->off += r;
    800047bc:	509c                	lw	a5,32(s1)
    800047be:	9fa9                	addw	a5,a5,a0
    800047c0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047c2:	6c88                	ld	a0,24(s1)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	0a2080e7          	jalr	162(ra) # 80003866 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047cc:	854a                	mv	a0,s2
    800047ce:	70a2                	ld	ra,40(sp)
    800047d0:	7402                	ld	s0,32(sp)
    800047d2:	64e2                	ld	s1,24(sp)
    800047d4:	6942                	ld	s2,16(sp)
    800047d6:	69a2                	ld	s3,8(sp)
    800047d8:	6145                	addi	sp,sp,48
    800047da:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047dc:	6908                	ld	a0,16(a0)
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	418080e7          	jalr	1048(ra) # 80004bf6 <piperead>
    800047e6:	892a                	mv	s2,a0
    800047e8:	b7d5                	j	800047cc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047ea:	02451783          	lh	a5,36(a0)
    800047ee:	03079693          	slli	a3,a5,0x30
    800047f2:	92c1                	srli	a3,a3,0x30
    800047f4:	4725                	li	a4,9
    800047f6:	02d76863          	bltu	a4,a3,80004826 <fileread+0xba>
    800047fa:	0792                	slli	a5,a5,0x4
    800047fc:	00021717          	auipc	a4,0x21
    80004800:	7b470713          	addi	a4,a4,1972 # 80025fb0 <devsw>
    80004804:	97ba                	add	a5,a5,a4
    80004806:	639c                	ld	a5,0(a5)
    80004808:	c38d                	beqz	a5,8000482a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000480a:	4505                	li	a0,1
    8000480c:	9782                	jalr	a5
    8000480e:	892a                	mv	s2,a0
    80004810:	bf75                	j	800047cc <fileread+0x60>
    panic("fileread");
    80004812:	00004517          	auipc	a0,0x4
    80004816:	e8650513          	addi	a0,a0,-378 # 80008698 <syscalls+0x268>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	dbc080e7          	jalr	-580(ra) # 800005d6 <panic>
    return -1;
    80004822:	597d                	li	s2,-1
    80004824:	b765                	j	800047cc <fileread+0x60>
      return -1;
    80004826:	597d                	li	s2,-1
    80004828:	b755                	j	800047cc <fileread+0x60>
    8000482a:	597d                	li	s2,-1
    8000482c:	b745                	j	800047cc <fileread+0x60>

000000008000482e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000482e:	00954783          	lbu	a5,9(a0)
    80004832:	14078563          	beqz	a5,8000497c <filewrite+0x14e>
{
    80004836:	715d                	addi	sp,sp,-80
    80004838:	e486                	sd	ra,72(sp)
    8000483a:	e0a2                	sd	s0,64(sp)
    8000483c:	fc26                	sd	s1,56(sp)
    8000483e:	f84a                	sd	s2,48(sp)
    80004840:	f44e                	sd	s3,40(sp)
    80004842:	f052                	sd	s4,32(sp)
    80004844:	ec56                	sd	s5,24(sp)
    80004846:	e85a                	sd	s6,16(sp)
    80004848:	e45e                	sd	s7,8(sp)
    8000484a:	e062                	sd	s8,0(sp)
    8000484c:	0880                	addi	s0,sp,80
    8000484e:	892a                	mv	s2,a0
    80004850:	8aae                	mv	s5,a1
    80004852:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004854:	411c                	lw	a5,0(a0)
    80004856:	4705                	li	a4,1
    80004858:	02e78263          	beq	a5,a4,8000487c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000485c:	470d                	li	a4,3
    8000485e:	02e78563          	beq	a5,a4,80004888 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004862:	4709                	li	a4,2
    80004864:	10e79463          	bne	a5,a4,8000496c <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004868:	0ec05e63          	blez	a2,80004964 <filewrite+0x136>
    int i = 0;
    8000486c:	4981                	li	s3,0
    8000486e:	6b05                	lui	s6,0x1
    80004870:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004874:	6b85                	lui	s7,0x1
    80004876:	c00b8b9b          	addiw	s7,s7,-1024
    8000487a:	a851                	j	8000490e <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000487c:	6908                	ld	a0,16(a0)
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	254080e7          	jalr	596(ra) # 80004ad2 <pipewrite>
    80004886:	a85d                	j	8000493c <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004888:	02451783          	lh	a5,36(a0)
    8000488c:	03079693          	slli	a3,a5,0x30
    80004890:	92c1                	srli	a3,a3,0x30
    80004892:	4725                	li	a4,9
    80004894:	0ed76663          	bltu	a4,a3,80004980 <filewrite+0x152>
    80004898:	0792                	slli	a5,a5,0x4
    8000489a:	00021717          	auipc	a4,0x21
    8000489e:	71670713          	addi	a4,a4,1814 # 80025fb0 <devsw>
    800048a2:	97ba                	add	a5,a5,a4
    800048a4:	679c                	ld	a5,8(a5)
    800048a6:	cff9                	beqz	a5,80004984 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800048a8:	4505                	li	a0,1
    800048aa:	9782                	jalr	a5
    800048ac:	a841                	j	8000493c <filewrite+0x10e>
    800048ae:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	8ae080e7          	jalr	-1874(ra) # 80004160 <begin_op>
      ilock(f->ip);
    800048ba:	01893503          	ld	a0,24(s2)
    800048be:	fffff097          	auipc	ra,0xfffff
    800048c2:	ee6080e7          	jalr	-282(ra) # 800037a4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048c6:	8762                	mv	a4,s8
    800048c8:	02092683          	lw	a3,32(s2)
    800048cc:	01598633          	add	a2,s3,s5
    800048d0:	4585                	li	a1,1
    800048d2:	01893503          	ld	a0,24(s2)
    800048d6:	fffff097          	auipc	ra,0xfffff
    800048da:	278080e7          	jalr	632(ra) # 80003b4e <writei>
    800048de:	84aa                	mv	s1,a0
    800048e0:	02a05f63          	blez	a0,8000491e <filewrite+0xf0>
        f->off += r;
    800048e4:	02092783          	lw	a5,32(s2)
    800048e8:	9fa9                	addw	a5,a5,a0
    800048ea:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048ee:	01893503          	ld	a0,24(s2)
    800048f2:	fffff097          	auipc	ra,0xfffff
    800048f6:	f74080e7          	jalr	-140(ra) # 80003866 <iunlock>
      end_op();
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	8e6080e7          	jalr	-1818(ra) # 800041e0 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004902:	049c1963          	bne	s8,s1,80004954 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004906:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000490a:	0349d663          	bge	s3,s4,80004936 <filewrite+0x108>
      int n1 = n - i;
    8000490e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004912:	84be                	mv	s1,a5
    80004914:	2781                	sext.w	a5,a5
    80004916:	f8fb5ce3          	bge	s6,a5,800048ae <filewrite+0x80>
    8000491a:	84de                	mv	s1,s7
    8000491c:	bf49                	j	800048ae <filewrite+0x80>
      iunlock(f->ip);
    8000491e:	01893503          	ld	a0,24(s2)
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	f44080e7          	jalr	-188(ra) # 80003866 <iunlock>
      end_op();
    8000492a:	00000097          	auipc	ra,0x0
    8000492e:	8b6080e7          	jalr	-1866(ra) # 800041e0 <end_op>
      if(r < 0)
    80004932:	fc04d8e3          	bgez	s1,80004902 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004936:	8552                	mv	a0,s4
    80004938:	033a1863          	bne	s4,s3,80004968 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000493c:	60a6                	ld	ra,72(sp)
    8000493e:	6406                	ld	s0,64(sp)
    80004940:	74e2                	ld	s1,56(sp)
    80004942:	7942                	ld	s2,48(sp)
    80004944:	79a2                	ld	s3,40(sp)
    80004946:	7a02                	ld	s4,32(sp)
    80004948:	6ae2                	ld	s5,24(sp)
    8000494a:	6b42                	ld	s6,16(sp)
    8000494c:	6ba2                	ld	s7,8(sp)
    8000494e:	6c02                	ld	s8,0(sp)
    80004950:	6161                	addi	sp,sp,80
    80004952:	8082                	ret
        panic("short filewrite");
    80004954:	00004517          	auipc	a0,0x4
    80004958:	d5450513          	addi	a0,a0,-684 # 800086a8 <syscalls+0x278>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	c7a080e7          	jalr	-902(ra) # 800005d6 <panic>
    int i = 0;
    80004964:	4981                	li	s3,0
    80004966:	bfc1                	j	80004936 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004968:	557d                	li	a0,-1
    8000496a:	bfc9                	j	8000493c <filewrite+0x10e>
    panic("filewrite");
    8000496c:	00004517          	auipc	a0,0x4
    80004970:	d4c50513          	addi	a0,a0,-692 # 800086b8 <syscalls+0x288>
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	c62080e7          	jalr	-926(ra) # 800005d6 <panic>
    return -1;
    8000497c:	557d                	li	a0,-1
}
    8000497e:	8082                	ret
      return -1;
    80004980:	557d                	li	a0,-1
    80004982:	bf6d                	j	8000493c <filewrite+0x10e>
    80004984:	557d                	li	a0,-1
    80004986:	bf5d                	j	8000493c <filewrite+0x10e>

0000000080004988 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004988:	7179                	addi	sp,sp,-48
    8000498a:	f406                	sd	ra,40(sp)
    8000498c:	f022                	sd	s0,32(sp)
    8000498e:	ec26                	sd	s1,24(sp)
    80004990:	e84a                	sd	s2,16(sp)
    80004992:	e44e                	sd	s3,8(sp)
    80004994:	e052                	sd	s4,0(sp)
    80004996:	1800                	addi	s0,sp,48
    80004998:	84aa                	mv	s1,a0
    8000499a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000499c:	0005b023          	sd	zero,0(a1)
    800049a0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049a4:	00000097          	auipc	ra,0x0
    800049a8:	bd2080e7          	jalr	-1070(ra) # 80004576 <filealloc>
    800049ac:	e088                	sd	a0,0(s1)
    800049ae:	c551                	beqz	a0,80004a3a <pipealloc+0xb2>
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	bc6080e7          	jalr	-1082(ra) # 80004576 <filealloc>
    800049b8:	00aa3023          	sd	a0,0(s4)
    800049bc:	c92d                	beqz	a0,80004a2e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	1c6080e7          	jalr	454(ra) # 80000b84 <kalloc>
    800049c6:	892a                	mv	s2,a0
    800049c8:	c125                	beqz	a0,80004a28 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049ca:	4985                	li	s3,1
    800049cc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049d0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049d4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049d8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049dc:	00004597          	auipc	a1,0x4
    800049e0:	cec58593          	addi	a1,a1,-788 # 800086c8 <syscalls+0x298>
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	200080e7          	jalr	512(ra) # 80000be4 <initlock>
  (*f0)->type = FD_PIPE;
    800049ec:	609c                	ld	a5,0(s1)
    800049ee:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049f2:	609c                	ld	a5,0(s1)
    800049f4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049f8:	609c                	ld	a5,0(s1)
    800049fa:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049fe:	609c                	ld	a5,0(s1)
    80004a00:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a04:	000a3783          	ld	a5,0(s4)
    80004a08:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a0c:	000a3783          	ld	a5,0(s4)
    80004a10:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a14:	000a3783          	ld	a5,0(s4)
    80004a18:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a1c:	000a3783          	ld	a5,0(s4)
    80004a20:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a24:	4501                	li	a0,0
    80004a26:	a025                	j	80004a4e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a28:	6088                	ld	a0,0(s1)
    80004a2a:	e501                	bnez	a0,80004a32 <pipealloc+0xaa>
    80004a2c:	a039                	j	80004a3a <pipealloc+0xb2>
    80004a2e:	6088                	ld	a0,0(s1)
    80004a30:	c51d                	beqz	a0,80004a5e <pipealloc+0xd6>
    fileclose(*f0);
    80004a32:	00000097          	auipc	ra,0x0
    80004a36:	c00080e7          	jalr	-1024(ra) # 80004632 <fileclose>
  if(*f1)
    80004a3a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a3e:	557d                	li	a0,-1
  if(*f1)
    80004a40:	c799                	beqz	a5,80004a4e <pipealloc+0xc6>
    fileclose(*f1);
    80004a42:	853e                	mv	a0,a5
    80004a44:	00000097          	auipc	ra,0x0
    80004a48:	bee080e7          	jalr	-1042(ra) # 80004632 <fileclose>
  return -1;
    80004a4c:	557d                	li	a0,-1
}
    80004a4e:	70a2                	ld	ra,40(sp)
    80004a50:	7402                	ld	s0,32(sp)
    80004a52:	64e2                	ld	s1,24(sp)
    80004a54:	6942                	ld	s2,16(sp)
    80004a56:	69a2                	ld	s3,8(sp)
    80004a58:	6a02                	ld	s4,0(sp)
    80004a5a:	6145                	addi	sp,sp,48
    80004a5c:	8082                	ret
  return -1;
    80004a5e:	557d                	li	a0,-1
    80004a60:	b7fd                	j	80004a4e <pipealloc+0xc6>

0000000080004a62 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a62:	1101                	addi	sp,sp,-32
    80004a64:	ec06                	sd	ra,24(sp)
    80004a66:	e822                	sd	s0,16(sp)
    80004a68:	e426                	sd	s1,8(sp)
    80004a6a:	e04a                	sd	s2,0(sp)
    80004a6c:	1000                	addi	s0,sp,32
    80004a6e:	84aa                	mv	s1,a0
    80004a70:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	202080e7          	jalr	514(ra) # 80000c74 <acquire>
  if(writable){
    80004a7a:	02090d63          	beqz	s2,80004ab4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a7e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a82:	21848513          	addi	a0,s1,536
    80004a86:	ffffe097          	auipc	ra,0xffffe
    80004a8a:	960080e7          	jalr	-1696(ra) # 800023e6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a8e:	2204b783          	ld	a5,544(s1)
    80004a92:	eb95                	bnez	a5,80004ac6 <pipeclose+0x64>
    release(&pi->lock);
    80004a94:	8526                	mv	a0,s1
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	292080e7          	jalr	658(ra) # 80000d28 <release>
    kfree((char*)pi);
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	fe8080e7          	jalr	-24(ra) # 80000a88 <kfree>
  } else
    release(&pi->lock);
}
    80004aa8:	60e2                	ld	ra,24(sp)
    80004aaa:	6442                	ld	s0,16(sp)
    80004aac:	64a2                	ld	s1,8(sp)
    80004aae:	6902                	ld	s2,0(sp)
    80004ab0:	6105                	addi	sp,sp,32
    80004ab2:	8082                	ret
    pi->readopen = 0;
    80004ab4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ab8:	21c48513          	addi	a0,s1,540
    80004abc:	ffffe097          	auipc	ra,0xffffe
    80004ac0:	92a080e7          	jalr	-1750(ra) # 800023e6 <wakeup>
    80004ac4:	b7e9                	j	80004a8e <pipeclose+0x2c>
    release(&pi->lock);
    80004ac6:	8526                	mv	a0,s1
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	260080e7          	jalr	608(ra) # 80000d28 <release>
}
    80004ad0:	bfe1                	j	80004aa8 <pipeclose+0x46>

0000000080004ad2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ad2:	7119                	addi	sp,sp,-128
    80004ad4:	fc86                	sd	ra,120(sp)
    80004ad6:	f8a2                	sd	s0,112(sp)
    80004ad8:	f4a6                	sd	s1,104(sp)
    80004ada:	f0ca                	sd	s2,96(sp)
    80004adc:	ecce                	sd	s3,88(sp)
    80004ade:	e8d2                	sd	s4,80(sp)
    80004ae0:	e4d6                	sd	s5,72(sp)
    80004ae2:	e0da                	sd	s6,64(sp)
    80004ae4:	fc5e                	sd	s7,56(sp)
    80004ae6:	f862                	sd	s8,48(sp)
    80004ae8:	f466                	sd	s9,40(sp)
    80004aea:	f06a                	sd	s10,32(sp)
    80004aec:	ec6e                	sd	s11,24(sp)
    80004aee:	0100                	addi	s0,sp,128
    80004af0:	84aa                	mv	s1,a0
    80004af2:	8cae                	mv	s9,a1
    80004af4:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	f4c080e7          	jalr	-180(ra) # 80001a42 <myproc>
    80004afe:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	172080e7          	jalr	370(ra) # 80000c74 <acquire>
  for(i = 0; i < n; i++){
    80004b0a:	0d605963          	blez	s6,80004bdc <pipewrite+0x10a>
    80004b0e:	89a6                	mv	s3,s1
    80004b10:	3b7d                	addiw	s6,s6,-1
    80004b12:	1b02                	slli	s6,s6,0x20
    80004b14:	020b5b13          	srli	s6,s6,0x20
    80004b18:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b1a:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b1e:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b22:	5dfd                	li	s11,-1
    80004b24:	000b8d1b          	sext.w	s10,s7
    80004b28:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b2a:	2184a783          	lw	a5,536(s1)
    80004b2e:	21c4a703          	lw	a4,540(s1)
    80004b32:	2007879b          	addiw	a5,a5,512
    80004b36:	02f71b63          	bne	a4,a5,80004b6c <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b3a:	2204a783          	lw	a5,544(s1)
    80004b3e:	cbad                	beqz	a5,80004bb0 <pipewrite+0xde>
    80004b40:	03092783          	lw	a5,48(s2)
    80004b44:	e7b5                	bnez	a5,80004bb0 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b46:	8556                	mv	a0,s5
    80004b48:	ffffe097          	auipc	ra,0xffffe
    80004b4c:	89e080e7          	jalr	-1890(ra) # 800023e6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b50:	85ce                	mv	a1,s3
    80004b52:	8552                	mv	a0,s4
    80004b54:	ffffd097          	auipc	ra,0xffffd
    80004b58:	70c080e7          	jalr	1804(ra) # 80002260 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b5c:	2184a783          	lw	a5,536(s1)
    80004b60:	21c4a703          	lw	a4,540(s1)
    80004b64:	2007879b          	addiw	a5,a5,512
    80004b68:	fcf709e3          	beq	a4,a5,80004b3a <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b6c:	4685                	li	a3,1
    80004b6e:	019b8633          	add	a2,s7,s9
    80004b72:	f8f40593          	addi	a1,s0,-113
    80004b76:	05093503          	ld	a0,80(s2)
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	c48080e7          	jalr	-952(ra) # 800017c2 <copyin>
    80004b82:	05b50e63          	beq	a0,s11,80004bde <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b86:	21c4a783          	lw	a5,540(s1)
    80004b8a:	0017871b          	addiw	a4,a5,1
    80004b8e:	20e4ae23          	sw	a4,540(s1)
    80004b92:	1ff7f793          	andi	a5,a5,511
    80004b96:	97a6                	add	a5,a5,s1
    80004b98:	f8f44703          	lbu	a4,-113(s0)
    80004b9c:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004ba0:	001d0c1b          	addiw	s8,s10,1
    80004ba4:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004ba8:	036b8b63          	beq	s7,s6,80004bde <pipewrite+0x10c>
    80004bac:	8bbe                	mv	s7,a5
    80004bae:	bf9d                	j	80004b24 <pipewrite+0x52>
        release(&pi->lock);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	176080e7          	jalr	374(ra) # 80000d28 <release>
        return -1;
    80004bba:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004bbc:	8562                	mv	a0,s8
    80004bbe:	70e6                	ld	ra,120(sp)
    80004bc0:	7446                	ld	s0,112(sp)
    80004bc2:	74a6                	ld	s1,104(sp)
    80004bc4:	7906                	ld	s2,96(sp)
    80004bc6:	69e6                	ld	s3,88(sp)
    80004bc8:	6a46                	ld	s4,80(sp)
    80004bca:	6aa6                	ld	s5,72(sp)
    80004bcc:	6b06                	ld	s6,64(sp)
    80004bce:	7be2                	ld	s7,56(sp)
    80004bd0:	7c42                	ld	s8,48(sp)
    80004bd2:	7ca2                	ld	s9,40(sp)
    80004bd4:	7d02                	ld	s10,32(sp)
    80004bd6:	6de2                	ld	s11,24(sp)
    80004bd8:	6109                	addi	sp,sp,128
    80004bda:	8082                	ret
  for(i = 0; i < n; i++){
    80004bdc:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004bde:	21848513          	addi	a0,s1,536
    80004be2:	ffffe097          	auipc	ra,0xffffe
    80004be6:	804080e7          	jalr	-2044(ra) # 800023e6 <wakeup>
  release(&pi->lock);
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	13c080e7          	jalr	316(ra) # 80000d28 <release>
  return i;
    80004bf4:	b7e1                	j	80004bbc <pipewrite+0xea>

0000000080004bf6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bf6:	715d                	addi	sp,sp,-80
    80004bf8:	e486                	sd	ra,72(sp)
    80004bfa:	e0a2                	sd	s0,64(sp)
    80004bfc:	fc26                	sd	s1,56(sp)
    80004bfe:	f84a                	sd	s2,48(sp)
    80004c00:	f44e                	sd	s3,40(sp)
    80004c02:	f052                	sd	s4,32(sp)
    80004c04:	ec56                	sd	s5,24(sp)
    80004c06:	e85a                	sd	s6,16(sp)
    80004c08:	0880                	addi	s0,sp,80
    80004c0a:	84aa                	mv	s1,a0
    80004c0c:	892e                	mv	s2,a1
    80004c0e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	e32080e7          	jalr	-462(ra) # 80001a42 <myproc>
    80004c18:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c1a:	8b26                	mv	s6,s1
    80004c1c:	8526                	mv	a0,s1
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	056080e7          	jalr	86(ra) # 80000c74 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c26:	2184a703          	lw	a4,536(s1)
    80004c2a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c2e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c32:	02f71463          	bne	a4,a5,80004c5a <piperead+0x64>
    80004c36:	2244a783          	lw	a5,548(s1)
    80004c3a:	c385                	beqz	a5,80004c5a <piperead+0x64>
    if(pr->killed){
    80004c3c:	030a2783          	lw	a5,48(s4)
    80004c40:	ebc1                	bnez	a5,80004cd0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c42:	85da                	mv	a1,s6
    80004c44:	854e                	mv	a0,s3
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	61a080e7          	jalr	1562(ra) # 80002260 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c4e:	2184a703          	lw	a4,536(s1)
    80004c52:	21c4a783          	lw	a5,540(s1)
    80004c56:	fef700e3          	beq	a4,a5,80004c36 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c5a:	09505263          	blez	s5,80004cde <piperead+0xe8>
    80004c5e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c60:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c62:	2184a783          	lw	a5,536(s1)
    80004c66:	21c4a703          	lw	a4,540(s1)
    80004c6a:	02f70d63          	beq	a4,a5,80004ca4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c6e:	0017871b          	addiw	a4,a5,1
    80004c72:	20e4ac23          	sw	a4,536(s1)
    80004c76:	1ff7f793          	andi	a5,a5,511
    80004c7a:	97a6                	add	a5,a5,s1
    80004c7c:	0187c783          	lbu	a5,24(a5)
    80004c80:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c84:	4685                	li	a3,1
    80004c86:	fbf40613          	addi	a2,s0,-65
    80004c8a:	85ca                	mv	a1,s2
    80004c8c:	050a3503          	ld	a0,80(s4)
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	aa6080e7          	jalr	-1370(ra) # 80001736 <copyout>
    80004c98:	01650663          	beq	a0,s6,80004ca4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c9c:	2985                	addiw	s3,s3,1
    80004c9e:	0905                	addi	s2,s2,1
    80004ca0:	fd3a91e3          	bne	s5,s3,80004c62 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ca4:	21c48513          	addi	a0,s1,540
    80004ca8:	ffffd097          	auipc	ra,0xffffd
    80004cac:	73e080e7          	jalr	1854(ra) # 800023e6 <wakeup>
  release(&pi->lock);
    80004cb0:	8526                	mv	a0,s1
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	076080e7          	jalr	118(ra) # 80000d28 <release>
  return i;
}
    80004cba:	854e                	mv	a0,s3
    80004cbc:	60a6                	ld	ra,72(sp)
    80004cbe:	6406                	ld	s0,64(sp)
    80004cc0:	74e2                	ld	s1,56(sp)
    80004cc2:	7942                	ld	s2,48(sp)
    80004cc4:	79a2                	ld	s3,40(sp)
    80004cc6:	7a02                	ld	s4,32(sp)
    80004cc8:	6ae2                	ld	s5,24(sp)
    80004cca:	6b42                	ld	s6,16(sp)
    80004ccc:	6161                	addi	sp,sp,80
    80004cce:	8082                	ret
      release(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	056080e7          	jalr	86(ra) # 80000d28 <release>
      return -1;
    80004cda:	59fd                	li	s3,-1
    80004cdc:	bff9                	j	80004cba <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cde:	4981                	li	s3,0
    80004ce0:	b7d1                	j	80004ca4 <piperead+0xae>

0000000080004ce2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ce2:	df010113          	addi	sp,sp,-528
    80004ce6:	20113423          	sd	ra,520(sp)
    80004cea:	20813023          	sd	s0,512(sp)
    80004cee:	ffa6                	sd	s1,504(sp)
    80004cf0:	fbca                	sd	s2,496(sp)
    80004cf2:	f7ce                	sd	s3,488(sp)
    80004cf4:	f3d2                	sd	s4,480(sp)
    80004cf6:	efd6                	sd	s5,472(sp)
    80004cf8:	ebda                	sd	s6,464(sp)
    80004cfa:	e7de                	sd	s7,456(sp)
    80004cfc:	e3e2                	sd	s8,448(sp)
    80004cfe:	ff66                	sd	s9,440(sp)
    80004d00:	fb6a                	sd	s10,432(sp)
    80004d02:	f76e                	sd	s11,424(sp)
    80004d04:	0c00                	addi	s0,sp,528
    80004d06:	84aa                	mv	s1,a0
    80004d08:	dea43c23          	sd	a0,-520(s0)
    80004d0c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	d32080e7          	jalr	-718(ra) # 80001a42 <myproc>
    80004d18:	892a                	mv	s2,a0

  begin_op();
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	446080e7          	jalr	1094(ra) # 80004160 <begin_op>

  if((ip = namei(path)) == 0){
    80004d22:	8526                	mv	a0,s1
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	230080e7          	jalr	560(ra) # 80003f54 <namei>
    80004d2c:	c92d                	beqz	a0,80004d9e <exec+0xbc>
    80004d2e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	a74080e7          	jalr	-1420(ra) # 800037a4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d38:	04000713          	li	a4,64
    80004d3c:	4681                	li	a3,0
    80004d3e:	e4840613          	addi	a2,s0,-440
    80004d42:	4581                	li	a1,0
    80004d44:	8526                	mv	a0,s1
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	d12080e7          	jalr	-750(ra) # 80003a58 <readi>
    80004d4e:	04000793          	li	a5,64
    80004d52:	00f51a63          	bne	a0,a5,80004d66 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d56:	e4842703          	lw	a4,-440(s0)
    80004d5a:	464c47b7          	lui	a5,0x464c4
    80004d5e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d62:	04f70463          	beq	a4,a5,80004daa <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d66:	8526                	mv	a0,s1
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	c9e080e7          	jalr	-866(ra) # 80003a06 <iunlockput>
    end_op();
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	470080e7          	jalr	1136(ra) # 800041e0 <end_op>
  }
  return -1;
    80004d78:	557d                	li	a0,-1
}
    80004d7a:	20813083          	ld	ra,520(sp)
    80004d7e:	20013403          	ld	s0,512(sp)
    80004d82:	74fe                	ld	s1,504(sp)
    80004d84:	795e                	ld	s2,496(sp)
    80004d86:	79be                	ld	s3,488(sp)
    80004d88:	7a1e                	ld	s4,480(sp)
    80004d8a:	6afe                	ld	s5,472(sp)
    80004d8c:	6b5e                	ld	s6,464(sp)
    80004d8e:	6bbe                	ld	s7,456(sp)
    80004d90:	6c1e                	ld	s8,448(sp)
    80004d92:	7cfa                	ld	s9,440(sp)
    80004d94:	7d5a                	ld	s10,432(sp)
    80004d96:	7dba                	ld	s11,424(sp)
    80004d98:	21010113          	addi	sp,sp,528
    80004d9c:	8082                	ret
    end_op();
    80004d9e:	fffff097          	auipc	ra,0xfffff
    80004da2:	442080e7          	jalr	1090(ra) # 800041e0 <end_op>
    return -1;
    80004da6:	557d                	li	a0,-1
    80004da8:	bfc9                	j	80004d7a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004daa:	854a                	mv	a0,s2
    80004dac:	ffffd097          	auipc	ra,0xffffd
    80004db0:	d5a080e7          	jalr	-678(ra) # 80001b06 <proc_pagetable>
    80004db4:	8baa                	mv	s7,a0
    80004db6:	d945                	beqz	a0,80004d66 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004db8:	e6842983          	lw	s3,-408(s0)
    80004dbc:	e8045783          	lhu	a5,-384(s0)
    80004dc0:	c7ad                	beqz	a5,80004e2a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dc2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dc4:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004dc6:	6c85                	lui	s9,0x1
    80004dc8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dcc:	def43823          	sd	a5,-528(s0)
    80004dd0:	a42d                	j	80004ffa <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dd2:	00004517          	auipc	a0,0x4
    80004dd6:	8fe50513          	addi	a0,a0,-1794 # 800086d0 <syscalls+0x2a0>
    80004dda:	ffffb097          	auipc	ra,0xffffb
    80004dde:	7fc080e7          	jalr	2044(ra) # 800005d6 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004de2:	8756                	mv	a4,s5
    80004de4:	012d86bb          	addw	a3,s11,s2
    80004de8:	4581                	li	a1,0
    80004dea:	8526                	mv	a0,s1
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	c6c080e7          	jalr	-916(ra) # 80003a58 <readi>
    80004df4:	2501                	sext.w	a0,a0
    80004df6:	1aaa9963          	bne	s5,a0,80004fa8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dfa:	6785                	lui	a5,0x1
    80004dfc:	0127893b          	addw	s2,a5,s2
    80004e00:	77fd                	lui	a5,0xfffff
    80004e02:	01478a3b          	addw	s4,a5,s4
    80004e06:	1f897163          	bgeu	s2,s8,80004fe8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e0a:	02091593          	slli	a1,s2,0x20
    80004e0e:	9181                	srli	a1,a1,0x20
    80004e10:	95ea                	add	a1,a1,s10
    80004e12:	855e                	mv	a0,s7
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	2ee080e7          	jalr	750(ra) # 80001102 <walkaddr>
    80004e1c:	862a                	mv	a2,a0
    if(pa == 0)
    80004e1e:	d955                	beqz	a0,80004dd2 <exec+0xf0>
      n = PGSIZE;
    80004e20:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e22:	fd9a70e3          	bgeu	s4,s9,80004de2 <exec+0x100>
      n = sz - i;
    80004e26:	8ad2                	mv	s5,s4
    80004e28:	bf6d                	j	80004de2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e2a:	4901                	li	s2,0
  iunlockput(ip);
    80004e2c:	8526                	mv	a0,s1
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	bd8080e7          	jalr	-1064(ra) # 80003a06 <iunlockput>
  end_op();
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	3aa080e7          	jalr	938(ra) # 800041e0 <end_op>
  p = myproc();
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	c04080e7          	jalr	-1020(ra) # 80001a42 <myproc>
    80004e46:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e48:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e4c:	6785                	lui	a5,0x1
    80004e4e:	17fd                	addi	a5,a5,-1
    80004e50:	993e                	add	s2,s2,a5
    80004e52:	757d                	lui	a0,0xfffff
    80004e54:	00a977b3          	and	a5,s2,a0
    80004e58:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e5c:	6609                	lui	a2,0x2
    80004e5e:	963e                	add	a2,a2,a5
    80004e60:	85be                	mv	a1,a5
    80004e62:	855e                	mv	a0,s7
    80004e64:	ffffc097          	auipc	ra,0xffffc
    80004e68:	682080e7          	jalr	1666(ra) # 800014e6 <uvmalloc>
    80004e6c:	8b2a                	mv	s6,a0
  ip = 0;
    80004e6e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e70:	12050c63          	beqz	a0,80004fa8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e74:	75f9                	lui	a1,0xffffe
    80004e76:	95aa                	add	a1,a1,a0
    80004e78:	855e                	mv	a0,s7
    80004e7a:	ffffd097          	auipc	ra,0xffffd
    80004e7e:	88a080e7          	jalr	-1910(ra) # 80001704 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e82:	7c7d                	lui	s8,0xfffff
    80004e84:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e86:	e0043783          	ld	a5,-512(s0)
    80004e8a:	6388                	ld	a0,0(a5)
    80004e8c:	c535                	beqz	a0,80004ef8 <exec+0x216>
    80004e8e:	e8840993          	addi	s3,s0,-376
    80004e92:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e96:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	060080e7          	jalr	96(ra) # 80000ef8 <strlen>
    80004ea0:	2505                	addiw	a0,a0,1
    80004ea2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ea6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004eaa:	13896363          	bltu	s2,s8,80004fd0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eae:	e0043d83          	ld	s11,-512(s0)
    80004eb2:	000dba03          	ld	s4,0(s11)
    80004eb6:	8552                	mv	a0,s4
    80004eb8:	ffffc097          	auipc	ra,0xffffc
    80004ebc:	040080e7          	jalr	64(ra) # 80000ef8 <strlen>
    80004ec0:	0015069b          	addiw	a3,a0,1
    80004ec4:	8652                	mv	a2,s4
    80004ec6:	85ca                	mv	a1,s2
    80004ec8:	855e                	mv	a0,s7
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	86c080e7          	jalr	-1940(ra) # 80001736 <copyout>
    80004ed2:	10054363          	bltz	a0,80004fd8 <exec+0x2f6>
    ustack[argc] = sp;
    80004ed6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eda:	0485                	addi	s1,s1,1
    80004edc:	008d8793          	addi	a5,s11,8
    80004ee0:	e0f43023          	sd	a5,-512(s0)
    80004ee4:	008db503          	ld	a0,8(s11)
    80004ee8:	c911                	beqz	a0,80004efc <exec+0x21a>
    if(argc >= MAXARG)
    80004eea:	09a1                	addi	s3,s3,8
    80004eec:	fb3c96e3          	bne	s9,s3,80004e98 <exec+0x1b6>
  sz = sz1;
    80004ef0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef4:	4481                	li	s1,0
    80004ef6:	a84d                	j	80004fa8 <exec+0x2c6>
  sp = sz;
    80004ef8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004efa:	4481                	li	s1,0
  ustack[argc] = 0;
    80004efc:	00349793          	slli	a5,s1,0x3
    80004f00:	f9040713          	addi	a4,s0,-112
    80004f04:	97ba                	add	a5,a5,a4
    80004f06:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004f0a:	00148693          	addi	a3,s1,1
    80004f0e:	068e                	slli	a3,a3,0x3
    80004f10:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f14:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f18:	01897663          	bgeu	s2,s8,80004f24 <exec+0x242>
  sz = sz1;
    80004f1c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f20:	4481                	li	s1,0
    80004f22:	a059                	j	80004fa8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f24:	e8840613          	addi	a2,s0,-376
    80004f28:	85ca                	mv	a1,s2
    80004f2a:	855e                	mv	a0,s7
    80004f2c:	ffffd097          	auipc	ra,0xffffd
    80004f30:	80a080e7          	jalr	-2038(ra) # 80001736 <copyout>
    80004f34:	0a054663          	bltz	a0,80004fe0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f38:	058ab783          	ld	a5,88(s5)
    80004f3c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f40:	df843783          	ld	a5,-520(s0)
    80004f44:	0007c703          	lbu	a4,0(a5)
    80004f48:	cf11                	beqz	a4,80004f64 <exec+0x282>
    80004f4a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f4c:	02f00693          	li	a3,47
    80004f50:	a029                	j	80004f5a <exec+0x278>
  for(last=s=path; *s; s++)
    80004f52:	0785                	addi	a5,a5,1
    80004f54:	fff7c703          	lbu	a4,-1(a5)
    80004f58:	c711                	beqz	a4,80004f64 <exec+0x282>
    if(*s == '/')
    80004f5a:	fed71ce3          	bne	a4,a3,80004f52 <exec+0x270>
      last = s+1;
    80004f5e:	def43c23          	sd	a5,-520(s0)
    80004f62:	bfc5                	j	80004f52 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f64:	4641                	li	a2,16
    80004f66:	df843583          	ld	a1,-520(s0)
    80004f6a:	158a8513          	addi	a0,s5,344
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	f58080e7          	jalr	-168(ra) # 80000ec6 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f76:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f7a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f7e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f82:	058ab783          	ld	a5,88(s5)
    80004f86:	e6043703          	ld	a4,-416(s0)
    80004f8a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f8c:	058ab783          	ld	a5,88(s5)
    80004f90:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f94:	85ea                	mv	a1,s10
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	c0c080e7          	jalr	-1012(ra) # 80001ba2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f9e:	0004851b          	sext.w	a0,s1
    80004fa2:	bbe1                	j	80004d7a <exec+0x98>
    80004fa4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fa8:	e0843583          	ld	a1,-504(s0)
    80004fac:	855e                	mv	a0,s7
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	bf4080e7          	jalr	-1036(ra) # 80001ba2 <proc_freepagetable>
  if(ip){
    80004fb6:	da0498e3          	bnez	s1,80004d66 <exec+0x84>
  return -1;
    80004fba:	557d                	li	a0,-1
    80004fbc:	bb7d                	j	80004d7a <exec+0x98>
    80004fbe:	e1243423          	sd	s2,-504(s0)
    80004fc2:	b7dd                	j	80004fa8 <exec+0x2c6>
    80004fc4:	e1243423          	sd	s2,-504(s0)
    80004fc8:	b7c5                	j	80004fa8 <exec+0x2c6>
    80004fca:	e1243423          	sd	s2,-504(s0)
    80004fce:	bfe9                	j	80004fa8 <exec+0x2c6>
  sz = sz1;
    80004fd0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fd4:	4481                	li	s1,0
    80004fd6:	bfc9                	j	80004fa8 <exec+0x2c6>
  sz = sz1;
    80004fd8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fdc:	4481                	li	s1,0
    80004fde:	b7e9                	j	80004fa8 <exec+0x2c6>
  sz = sz1;
    80004fe0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe4:	4481                	li	s1,0
    80004fe6:	b7c9                	j	80004fa8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fe8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fec:	2b05                	addiw	s6,s6,1
    80004fee:	0389899b          	addiw	s3,s3,56
    80004ff2:	e8045783          	lhu	a5,-384(s0)
    80004ff6:	e2fb5be3          	bge	s6,a5,80004e2c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ffa:	2981                	sext.w	s3,s3
    80004ffc:	03800713          	li	a4,56
    80005000:	86ce                	mv	a3,s3
    80005002:	e1040613          	addi	a2,s0,-496
    80005006:	4581                	li	a1,0
    80005008:	8526                	mv	a0,s1
    8000500a:	fffff097          	auipc	ra,0xfffff
    8000500e:	a4e080e7          	jalr	-1458(ra) # 80003a58 <readi>
    80005012:	03800793          	li	a5,56
    80005016:	f8f517e3          	bne	a0,a5,80004fa4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000501a:	e1042783          	lw	a5,-496(s0)
    8000501e:	4705                	li	a4,1
    80005020:	fce796e3          	bne	a5,a4,80004fec <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005024:	e3843603          	ld	a2,-456(s0)
    80005028:	e3043783          	ld	a5,-464(s0)
    8000502c:	f8f669e3          	bltu	a2,a5,80004fbe <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005030:	e2043783          	ld	a5,-480(s0)
    80005034:	963e                	add	a2,a2,a5
    80005036:	f8f667e3          	bltu	a2,a5,80004fc4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000503a:	85ca                	mv	a1,s2
    8000503c:	855e                	mv	a0,s7
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	4a8080e7          	jalr	1192(ra) # 800014e6 <uvmalloc>
    80005046:	e0a43423          	sd	a0,-504(s0)
    8000504a:	d141                	beqz	a0,80004fca <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    8000504c:	e2043d03          	ld	s10,-480(s0)
    80005050:	df043783          	ld	a5,-528(s0)
    80005054:	00fd77b3          	and	a5,s10,a5
    80005058:	fba1                	bnez	a5,80004fa8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000505a:	e1842d83          	lw	s11,-488(s0)
    8000505e:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005062:	f80c03e3          	beqz	s8,80004fe8 <exec+0x306>
    80005066:	8a62                	mv	s4,s8
    80005068:	4901                	li	s2,0
    8000506a:	b345                	j	80004e0a <exec+0x128>

000000008000506c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000506c:	7179                	addi	sp,sp,-48
    8000506e:	f406                	sd	ra,40(sp)
    80005070:	f022                	sd	s0,32(sp)
    80005072:	ec26                	sd	s1,24(sp)
    80005074:	e84a                	sd	s2,16(sp)
    80005076:	1800                	addi	s0,sp,48
    80005078:	892e                	mv	s2,a1
    8000507a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000507c:	fdc40593          	addi	a1,s0,-36
    80005080:	ffffe097          	auipc	ra,0xffffe
    80005084:	baa080e7          	jalr	-1110(ra) # 80002c2a <argint>
    80005088:	04054063          	bltz	a0,800050c8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000508c:	fdc42703          	lw	a4,-36(s0)
    80005090:	47bd                	li	a5,15
    80005092:	02e7ed63          	bltu	a5,a4,800050cc <argfd+0x60>
    80005096:	ffffd097          	auipc	ra,0xffffd
    8000509a:	9ac080e7          	jalr	-1620(ra) # 80001a42 <myproc>
    8000509e:	fdc42703          	lw	a4,-36(s0)
    800050a2:	01a70793          	addi	a5,a4,26
    800050a6:	078e                	slli	a5,a5,0x3
    800050a8:	953e                	add	a0,a0,a5
    800050aa:	611c                	ld	a5,0(a0)
    800050ac:	c395                	beqz	a5,800050d0 <argfd+0x64>
    return -1;
  if(pfd)
    800050ae:	00090463          	beqz	s2,800050b6 <argfd+0x4a>
    *pfd = fd;
    800050b2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050b6:	4501                	li	a0,0
  if(pf)
    800050b8:	c091                	beqz	s1,800050bc <argfd+0x50>
    *pf = f;
    800050ba:	e09c                	sd	a5,0(s1)
}
    800050bc:	70a2                	ld	ra,40(sp)
    800050be:	7402                	ld	s0,32(sp)
    800050c0:	64e2                	ld	s1,24(sp)
    800050c2:	6942                	ld	s2,16(sp)
    800050c4:	6145                	addi	sp,sp,48
    800050c6:	8082                	ret
    return -1;
    800050c8:	557d                	li	a0,-1
    800050ca:	bfcd                	j	800050bc <argfd+0x50>
    return -1;
    800050cc:	557d                	li	a0,-1
    800050ce:	b7fd                	j	800050bc <argfd+0x50>
    800050d0:	557d                	li	a0,-1
    800050d2:	b7ed                	j	800050bc <argfd+0x50>

00000000800050d4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050d4:	1101                	addi	sp,sp,-32
    800050d6:	ec06                	sd	ra,24(sp)
    800050d8:	e822                	sd	s0,16(sp)
    800050da:	e426                	sd	s1,8(sp)
    800050dc:	1000                	addi	s0,sp,32
    800050de:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050e0:	ffffd097          	auipc	ra,0xffffd
    800050e4:	962080e7          	jalr	-1694(ra) # 80001a42 <myproc>
    800050e8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050ea:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd40d0>
    800050ee:	4501                	li	a0,0
    800050f0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050f2:	6398                	ld	a4,0(a5)
    800050f4:	cb19                	beqz	a4,8000510a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050f6:	2505                	addiw	a0,a0,1
    800050f8:	07a1                	addi	a5,a5,8
    800050fa:	fed51ce3          	bne	a0,a3,800050f2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050fe:	557d                	li	a0,-1
}
    80005100:	60e2                	ld	ra,24(sp)
    80005102:	6442                	ld	s0,16(sp)
    80005104:	64a2                	ld	s1,8(sp)
    80005106:	6105                	addi	sp,sp,32
    80005108:	8082                	ret
      p->ofile[fd] = f;
    8000510a:	01a50793          	addi	a5,a0,26
    8000510e:	078e                	slli	a5,a5,0x3
    80005110:	963e                	add	a2,a2,a5
    80005112:	e204                	sd	s1,0(a2)
      return fd;
    80005114:	b7f5                	j	80005100 <fdalloc+0x2c>

0000000080005116 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005116:	715d                	addi	sp,sp,-80
    80005118:	e486                	sd	ra,72(sp)
    8000511a:	e0a2                	sd	s0,64(sp)
    8000511c:	fc26                	sd	s1,56(sp)
    8000511e:	f84a                	sd	s2,48(sp)
    80005120:	f44e                	sd	s3,40(sp)
    80005122:	f052                	sd	s4,32(sp)
    80005124:	ec56                	sd	s5,24(sp)
    80005126:	0880                	addi	s0,sp,80
    80005128:	89ae                	mv	s3,a1
    8000512a:	8ab2                	mv	s5,a2
    8000512c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000512e:	fb040593          	addi	a1,s0,-80
    80005132:	fffff097          	auipc	ra,0xfffff
    80005136:	e40080e7          	jalr	-448(ra) # 80003f72 <nameiparent>
    8000513a:	892a                	mv	s2,a0
    8000513c:	12050f63          	beqz	a0,8000527a <create+0x164>
    return 0;

  ilock(dp);
    80005140:	ffffe097          	auipc	ra,0xffffe
    80005144:	664080e7          	jalr	1636(ra) # 800037a4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005148:	4601                	li	a2,0
    8000514a:	fb040593          	addi	a1,s0,-80
    8000514e:	854a                	mv	a0,s2
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	b32080e7          	jalr	-1230(ra) # 80003c82 <dirlookup>
    80005158:	84aa                	mv	s1,a0
    8000515a:	c921                	beqz	a0,800051aa <create+0x94>
    iunlockput(dp);
    8000515c:	854a                	mv	a0,s2
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	8a8080e7          	jalr	-1880(ra) # 80003a06 <iunlockput>
    ilock(ip);
    80005166:	8526                	mv	a0,s1
    80005168:	ffffe097          	auipc	ra,0xffffe
    8000516c:	63c080e7          	jalr	1596(ra) # 800037a4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005170:	2981                	sext.w	s3,s3
    80005172:	4789                	li	a5,2
    80005174:	02f99463          	bne	s3,a5,8000519c <create+0x86>
    80005178:	0444d783          	lhu	a5,68(s1)
    8000517c:	37f9                	addiw	a5,a5,-2
    8000517e:	17c2                	slli	a5,a5,0x30
    80005180:	93c1                	srli	a5,a5,0x30
    80005182:	4705                	li	a4,1
    80005184:	00f76c63          	bltu	a4,a5,8000519c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005188:	8526                	mv	a0,s1
    8000518a:	60a6                	ld	ra,72(sp)
    8000518c:	6406                	ld	s0,64(sp)
    8000518e:	74e2                	ld	s1,56(sp)
    80005190:	7942                	ld	s2,48(sp)
    80005192:	79a2                	ld	s3,40(sp)
    80005194:	7a02                	ld	s4,32(sp)
    80005196:	6ae2                	ld	s5,24(sp)
    80005198:	6161                	addi	sp,sp,80
    8000519a:	8082                	ret
    iunlockput(ip);
    8000519c:	8526                	mv	a0,s1
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	868080e7          	jalr	-1944(ra) # 80003a06 <iunlockput>
    return 0;
    800051a6:	4481                	li	s1,0
    800051a8:	b7c5                	j	80005188 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051aa:	85ce                	mv	a1,s3
    800051ac:	00092503          	lw	a0,0(s2)
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	45c080e7          	jalr	1116(ra) # 8000360c <ialloc>
    800051b8:	84aa                	mv	s1,a0
    800051ba:	c529                	beqz	a0,80005204 <create+0xee>
  ilock(ip);
    800051bc:	ffffe097          	auipc	ra,0xffffe
    800051c0:	5e8080e7          	jalr	1512(ra) # 800037a4 <ilock>
  ip->major = major;
    800051c4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051c8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051cc:	4785                	li	a5,1
    800051ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051d2:	8526                	mv	a0,s1
    800051d4:	ffffe097          	auipc	ra,0xffffe
    800051d8:	506080e7          	jalr	1286(ra) # 800036da <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051dc:	2981                	sext.w	s3,s3
    800051de:	4785                	li	a5,1
    800051e0:	02f98a63          	beq	s3,a5,80005214 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051e4:	40d0                	lw	a2,4(s1)
    800051e6:	fb040593          	addi	a1,s0,-80
    800051ea:	854a                	mv	a0,s2
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	ca6080e7          	jalr	-858(ra) # 80003e92 <dirlink>
    800051f4:	06054b63          	bltz	a0,8000526a <create+0x154>
  iunlockput(dp);
    800051f8:	854a                	mv	a0,s2
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	80c080e7          	jalr	-2036(ra) # 80003a06 <iunlockput>
  return ip;
    80005202:	b759                	j	80005188 <create+0x72>
    panic("create: ialloc");
    80005204:	00003517          	auipc	a0,0x3
    80005208:	4ec50513          	addi	a0,a0,1260 # 800086f0 <syscalls+0x2c0>
    8000520c:	ffffb097          	auipc	ra,0xffffb
    80005210:	3ca080e7          	jalr	970(ra) # 800005d6 <panic>
    dp->nlink++;  // for ".."
    80005214:	04a95783          	lhu	a5,74(s2)
    80005218:	2785                	addiw	a5,a5,1
    8000521a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000521e:	854a                	mv	a0,s2
    80005220:	ffffe097          	auipc	ra,0xffffe
    80005224:	4ba080e7          	jalr	1210(ra) # 800036da <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005228:	40d0                	lw	a2,4(s1)
    8000522a:	00003597          	auipc	a1,0x3
    8000522e:	4d658593          	addi	a1,a1,1238 # 80008700 <syscalls+0x2d0>
    80005232:	8526                	mv	a0,s1
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	c5e080e7          	jalr	-930(ra) # 80003e92 <dirlink>
    8000523c:	00054f63          	bltz	a0,8000525a <create+0x144>
    80005240:	00492603          	lw	a2,4(s2)
    80005244:	00003597          	auipc	a1,0x3
    80005248:	4c458593          	addi	a1,a1,1220 # 80008708 <syscalls+0x2d8>
    8000524c:	8526                	mv	a0,s1
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	c44080e7          	jalr	-956(ra) # 80003e92 <dirlink>
    80005256:	f80557e3          	bgez	a0,800051e4 <create+0xce>
      panic("create dots");
    8000525a:	00003517          	auipc	a0,0x3
    8000525e:	4b650513          	addi	a0,a0,1206 # 80008710 <syscalls+0x2e0>
    80005262:	ffffb097          	auipc	ra,0xffffb
    80005266:	374080e7          	jalr	884(ra) # 800005d6 <panic>
    panic("create: dirlink");
    8000526a:	00003517          	auipc	a0,0x3
    8000526e:	4b650513          	addi	a0,a0,1206 # 80008720 <syscalls+0x2f0>
    80005272:	ffffb097          	auipc	ra,0xffffb
    80005276:	364080e7          	jalr	868(ra) # 800005d6 <panic>
    return 0;
    8000527a:	84aa                	mv	s1,a0
    8000527c:	b731                	j	80005188 <create+0x72>

000000008000527e <sys_dup>:
{
    8000527e:	7179                	addi	sp,sp,-48
    80005280:	f406                	sd	ra,40(sp)
    80005282:	f022                	sd	s0,32(sp)
    80005284:	ec26                	sd	s1,24(sp)
    80005286:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005288:	fd840613          	addi	a2,s0,-40
    8000528c:	4581                	li	a1,0
    8000528e:	4501                	li	a0,0
    80005290:	00000097          	auipc	ra,0x0
    80005294:	ddc080e7          	jalr	-548(ra) # 8000506c <argfd>
    return -1;
    80005298:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000529a:	02054363          	bltz	a0,800052c0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000529e:	fd843503          	ld	a0,-40(s0)
    800052a2:	00000097          	auipc	ra,0x0
    800052a6:	e32080e7          	jalr	-462(ra) # 800050d4 <fdalloc>
    800052aa:	84aa                	mv	s1,a0
    return -1;
    800052ac:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052ae:	00054963          	bltz	a0,800052c0 <sys_dup+0x42>
  filedup(f);
    800052b2:	fd843503          	ld	a0,-40(s0)
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	32a080e7          	jalr	810(ra) # 800045e0 <filedup>
  return fd;
    800052be:	87a6                	mv	a5,s1
}
    800052c0:	853e                	mv	a0,a5
    800052c2:	70a2                	ld	ra,40(sp)
    800052c4:	7402                	ld	s0,32(sp)
    800052c6:	64e2                	ld	s1,24(sp)
    800052c8:	6145                	addi	sp,sp,48
    800052ca:	8082                	ret

00000000800052cc <sys_read>:
{
    800052cc:	7179                	addi	sp,sp,-48
    800052ce:	f406                	sd	ra,40(sp)
    800052d0:	f022                	sd	s0,32(sp)
    800052d2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d4:	fe840613          	addi	a2,s0,-24
    800052d8:	4581                	li	a1,0
    800052da:	4501                	li	a0,0
    800052dc:	00000097          	auipc	ra,0x0
    800052e0:	d90080e7          	jalr	-624(ra) # 8000506c <argfd>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e6:	04054163          	bltz	a0,80005328 <sys_read+0x5c>
    800052ea:	fe440593          	addi	a1,s0,-28
    800052ee:	4509                	li	a0,2
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	93a080e7          	jalr	-1734(ra) # 80002c2a <argint>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fa:	02054763          	bltz	a0,80005328 <sys_read+0x5c>
    800052fe:	fd840593          	addi	a1,s0,-40
    80005302:	4505                	li	a0,1
    80005304:	ffffe097          	auipc	ra,0xffffe
    80005308:	948080e7          	jalr	-1720(ra) # 80002c4c <argaddr>
    return -1;
    8000530c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530e:	00054d63          	bltz	a0,80005328 <sys_read+0x5c>
  return fileread(f, p, n);
    80005312:	fe442603          	lw	a2,-28(s0)
    80005316:	fd843583          	ld	a1,-40(s0)
    8000531a:	fe843503          	ld	a0,-24(s0)
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	44e080e7          	jalr	1102(ra) # 8000476c <fileread>
    80005326:	87aa                	mv	a5,a0
}
    80005328:	853e                	mv	a0,a5
    8000532a:	70a2                	ld	ra,40(sp)
    8000532c:	7402                	ld	s0,32(sp)
    8000532e:	6145                	addi	sp,sp,48
    80005330:	8082                	ret

0000000080005332 <sys_write>:
{
    80005332:	7179                	addi	sp,sp,-48
    80005334:	f406                	sd	ra,40(sp)
    80005336:	f022                	sd	s0,32(sp)
    80005338:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533a:	fe840613          	addi	a2,s0,-24
    8000533e:	4581                	li	a1,0
    80005340:	4501                	li	a0,0
    80005342:	00000097          	auipc	ra,0x0
    80005346:	d2a080e7          	jalr	-726(ra) # 8000506c <argfd>
    return -1;
    8000534a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534c:	04054163          	bltz	a0,8000538e <sys_write+0x5c>
    80005350:	fe440593          	addi	a1,s0,-28
    80005354:	4509                	li	a0,2
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	8d4080e7          	jalr	-1836(ra) # 80002c2a <argint>
    return -1;
    8000535e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005360:	02054763          	bltz	a0,8000538e <sys_write+0x5c>
    80005364:	fd840593          	addi	a1,s0,-40
    80005368:	4505                	li	a0,1
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	8e2080e7          	jalr	-1822(ra) # 80002c4c <argaddr>
    return -1;
    80005372:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005374:	00054d63          	bltz	a0,8000538e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005378:	fe442603          	lw	a2,-28(s0)
    8000537c:	fd843583          	ld	a1,-40(s0)
    80005380:	fe843503          	ld	a0,-24(s0)
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	4aa080e7          	jalr	1194(ra) # 8000482e <filewrite>
    8000538c:	87aa                	mv	a5,a0
}
    8000538e:	853e                	mv	a0,a5
    80005390:	70a2                	ld	ra,40(sp)
    80005392:	7402                	ld	s0,32(sp)
    80005394:	6145                	addi	sp,sp,48
    80005396:	8082                	ret

0000000080005398 <sys_close>:
{
    80005398:	1101                	addi	sp,sp,-32
    8000539a:	ec06                	sd	ra,24(sp)
    8000539c:	e822                	sd	s0,16(sp)
    8000539e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053a0:	fe040613          	addi	a2,s0,-32
    800053a4:	fec40593          	addi	a1,s0,-20
    800053a8:	4501                	li	a0,0
    800053aa:	00000097          	auipc	ra,0x0
    800053ae:	cc2080e7          	jalr	-830(ra) # 8000506c <argfd>
    return -1;
    800053b2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053b4:	02054463          	bltz	a0,800053dc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053b8:	ffffc097          	auipc	ra,0xffffc
    800053bc:	68a080e7          	jalr	1674(ra) # 80001a42 <myproc>
    800053c0:	fec42783          	lw	a5,-20(s0)
    800053c4:	07e9                	addi	a5,a5,26
    800053c6:	078e                	slli	a5,a5,0x3
    800053c8:	97aa                	add	a5,a5,a0
    800053ca:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053ce:	fe043503          	ld	a0,-32(s0)
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	260080e7          	jalr	608(ra) # 80004632 <fileclose>
  return 0;
    800053da:	4781                	li	a5,0
}
    800053dc:	853e                	mv	a0,a5
    800053de:	60e2                	ld	ra,24(sp)
    800053e0:	6442                	ld	s0,16(sp)
    800053e2:	6105                	addi	sp,sp,32
    800053e4:	8082                	ret

00000000800053e6 <sys_fstat>:
{
    800053e6:	1101                	addi	sp,sp,-32
    800053e8:	ec06                	sd	ra,24(sp)
    800053ea:	e822                	sd	s0,16(sp)
    800053ec:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ee:	fe840613          	addi	a2,s0,-24
    800053f2:	4581                	li	a1,0
    800053f4:	4501                	li	a0,0
    800053f6:	00000097          	auipc	ra,0x0
    800053fa:	c76080e7          	jalr	-906(ra) # 8000506c <argfd>
    return -1;
    800053fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005400:	02054563          	bltz	a0,8000542a <sys_fstat+0x44>
    80005404:	fe040593          	addi	a1,s0,-32
    80005408:	4505                	li	a0,1
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	842080e7          	jalr	-1982(ra) # 80002c4c <argaddr>
    return -1;
    80005412:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005414:	00054b63          	bltz	a0,8000542a <sys_fstat+0x44>
  return filestat(f, st);
    80005418:	fe043583          	ld	a1,-32(s0)
    8000541c:	fe843503          	ld	a0,-24(s0)
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	2da080e7          	jalr	730(ra) # 800046fa <filestat>
    80005428:	87aa                	mv	a5,a0
}
    8000542a:	853e                	mv	a0,a5
    8000542c:	60e2                	ld	ra,24(sp)
    8000542e:	6442                	ld	s0,16(sp)
    80005430:	6105                	addi	sp,sp,32
    80005432:	8082                	ret

0000000080005434 <sys_link>:
{
    80005434:	7169                	addi	sp,sp,-304
    80005436:	f606                	sd	ra,296(sp)
    80005438:	f222                	sd	s0,288(sp)
    8000543a:	ee26                	sd	s1,280(sp)
    8000543c:	ea4a                	sd	s2,272(sp)
    8000543e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005440:	08000613          	li	a2,128
    80005444:	ed040593          	addi	a1,s0,-304
    80005448:	4501                	li	a0,0
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	824080e7          	jalr	-2012(ra) # 80002c6e <argstr>
    return -1;
    80005452:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005454:	10054e63          	bltz	a0,80005570 <sys_link+0x13c>
    80005458:	08000613          	li	a2,128
    8000545c:	f5040593          	addi	a1,s0,-176
    80005460:	4505                	li	a0,1
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	80c080e7          	jalr	-2036(ra) # 80002c6e <argstr>
    return -1;
    8000546a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000546c:	10054263          	bltz	a0,80005570 <sys_link+0x13c>
  begin_op();
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	cf0080e7          	jalr	-784(ra) # 80004160 <begin_op>
  if((ip = namei(old)) == 0){
    80005478:	ed040513          	addi	a0,s0,-304
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	ad8080e7          	jalr	-1320(ra) # 80003f54 <namei>
    80005484:	84aa                	mv	s1,a0
    80005486:	c551                	beqz	a0,80005512 <sys_link+0xde>
  ilock(ip);
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	31c080e7          	jalr	796(ra) # 800037a4 <ilock>
  if(ip->type == T_DIR){
    80005490:	04449703          	lh	a4,68(s1)
    80005494:	4785                	li	a5,1
    80005496:	08f70463          	beq	a4,a5,8000551e <sys_link+0xea>
  ip->nlink++;
    8000549a:	04a4d783          	lhu	a5,74(s1)
    8000549e:	2785                	addiw	a5,a5,1
    800054a0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054a4:	8526                	mv	a0,s1
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	234080e7          	jalr	564(ra) # 800036da <iupdate>
  iunlock(ip);
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	3b6080e7          	jalr	950(ra) # 80003866 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054b8:	fd040593          	addi	a1,s0,-48
    800054bc:	f5040513          	addi	a0,s0,-176
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	ab2080e7          	jalr	-1358(ra) # 80003f72 <nameiparent>
    800054c8:	892a                	mv	s2,a0
    800054ca:	c935                	beqz	a0,8000553e <sys_link+0x10a>
  ilock(dp);
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	2d8080e7          	jalr	728(ra) # 800037a4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054d4:	00092703          	lw	a4,0(s2)
    800054d8:	409c                	lw	a5,0(s1)
    800054da:	04f71d63          	bne	a4,a5,80005534 <sys_link+0x100>
    800054de:	40d0                	lw	a2,4(s1)
    800054e0:	fd040593          	addi	a1,s0,-48
    800054e4:	854a                	mv	a0,s2
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	9ac080e7          	jalr	-1620(ra) # 80003e92 <dirlink>
    800054ee:	04054363          	bltz	a0,80005534 <sys_link+0x100>
  iunlockput(dp);
    800054f2:	854a                	mv	a0,s2
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	512080e7          	jalr	1298(ra) # 80003a06 <iunlockput>
  iput(ip);
    800054fc:	8526                	mv	a0,s1
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	460080e7          	jalr	1120(ra) # 8000395e <iput>
  end_op();
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	cda080e7          	jalr	-806(ra) # 800041e0 <end_op>
  return 0;
    8000550e:	4781                	li	a5,0
    80005510:	a085                	j	80005570 <sys_link+0x13c>
    end_op();
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	cce080e7          	jalr	-818(ra) # 800041e0 <end_op>
    return -1;
    8000551a:	57fd                	li	a5,-1
    8000551c:	a891                	j	80005570 <sys_link+0x13c>
    iunlockput(ip);
    8000551e:	8526                	mv	a0,s1
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	4e6080e7          	jalr	1254(ra) # 80003a06 <iunlockput>
    end_op();
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	cb8080e7          	jalr	-840(ra) # 800041e0 <end_op>
    return -1;
    80005530:	57fd                	li	a5,-1
    80005532:	a83d                	j	80005570 <sys_link+0x13c>
    iunlockput(dp);
    80005534:	854a                	mv	a0,s2
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	4d0080e7          	jalr	1232(ra) # 80003a06 <iunlockput>
  ilock(ip);
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	264080e7          	jalr	612(ra) # 800037a4 <ilock>
  ip->nlink--;
    80005548:	04a4d783          	lhu	a5,74(s1)
    8000554c:	37fd                	addiw	a5,a5,-1
    8000554e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005552:	8526                	mv	a0,s1
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	186080e7          	jalr	390(ra) # 800036da <iupdate>
  iunlockput(ip);
    8000555c:	8526                	mv	a0,s1
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	4a8080e7          	jalr	1192(ra) # 80003a06 <iunlockput>
  end_op();
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	c7a080e7          	jalr	-902(ra) # 800041e0 <end_op>
  return -1;
    8000556e:	57fd                	li	a5,-1
}
    80005570:	853e                	mv	a0,a5
    80005572:	70b2                	ld	ra,296(sp)
    80005574:	7412                	ld	s0,288(sp)
    80005576:	64f2                	ld	s1,280(sp)
    80005578:	6952                	ld	s2,272(sp)
    8000557a:	6155                	addi	sp,sp,304
    8000557c:	8082                	ret

000000008000557e <sys_unlink>:
{
    8000557e:	7151                	addi	sp,sp,-240
    80005580:	f586                	sd	ra,232(sp)
    80005582:	f1a2                	sd	s0,224(sp)
    80005584:	eda6                	sd	s1,216(sp)
    80005586:	e9ca                	sd	s2,208(sp)
    80005588:	e5ce                	sd	s3,200(sp)
    8000558a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000558c:	08000613          	li	a2,128
    80005590:	f3040593          	addi	a1,s0,-208
    80005594:	4501                	li	a0,0
    80005596:	ffffd097          	auipc	ra,0xffffd
    8000559a:	6d8080e7          	jalr	1752(ra) # 80002c6e <argstr>
    8000559e:	18054163          	bltz	a0,80005720 <sys_unlink+0x1a2>
  begin_op();
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	bbe080e7          	jalr	-1090(ra) # 80004160 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055aa:	fb040593          	addi	a1,s0,-80
    800055ae:	f3040513          	addi	a0,s0,-208
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	9c0080e7          	jalr	-1600(ra) # 80003f72 <nameiparent>
    800055ba:	84aa                	mv	s1,a0
    800055bc:	c979                	beqz	a0,80005692 <sys_unlink+0x114>
  ilock(dp);
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	1e6080e7          	jalr	486(ra) # 800037a4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055c6:	00003597          	auipc	a1,0x3
    800055ca:	13a58593          	addi	a1,a1,314 # 80008700 <syscalls+0x2d0>
    800055ce:	fb040513          	addi	a0,s0,-80
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	696080e7          	jalr	1686(ra) # 80003c68 <namecmp>
    800055da:	14050a63          	beqz	a0,8000572e <sys_unlink+0x1b0>
    800055de:	00003597          	auipc	a1,0x3
    800055e2:	12a58593          	addi	a1,a1,298 # 80008708 <syscalls+0x2d8>
    800055e6:	fb040513          	addi	a0,s0,-80
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	67e080e7          	jalr	1662(ra) # 80003c68 <namecmp>
    800055f2:	12050e63          	beqz	a0,8000572e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055f6:	f2c40613          	addi	a2,s0,-212
    800055fa:	fb040593          	addi	a1,s0,-80
    800055fe:	8526                	mv	a0,s1
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	682080e7          	jalr	1666(ra) # 80003c82 <dirlookup>
    80005608:	892a                	mv	s2,a0
    8000560a:	12050263          	beqz	a0,8000572e <sys_unlink+0x1b0>
  ilock(ip);
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	196080e7          	jalr	406(ra) # 800037a4 <ilock>
  if(ip->nlink < 1)
    80005616:	04a91783          	lh	a5,74(s2)
    8000561a:	08f05263          	blez	a5,8000569e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000561e:	04491703          	lh	a4,68(s2)
    80005622:	4785                	li	a5,1
    80005624:	08f70563          	beq	a4,a5,800056ae <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005628:	4641                	li	a2,16
    8000562a:	4581                	li	a1,0
    8000562c:	fc040513          	addi	a0,s0,-64
    80005630:	ffffb097          	auipc	ra,0xffffb
    80005634:	740080e7          	jalr	1856(ra) # 80000d70 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005638:	4741                	li	a4,16
    8000563a:	f2c42683          	lw	a3,-212(s0)
    8000563e:	fc040613          	addi	a2,s0,-64
    80005642:	4581                	li	a1,0
    80005644:	8526                	mv	a0,s1
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	508080e7          	jalr	1288(ra) # 80003b4e <writei>
    8000564e:	47c1                	li	a5,16
    80005650:	0af51563          	bne	a0,a5,800056fa <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005654:	04491703          	lh	a4,68(s2)
    80005658:	4785                	li	a5,1
    8000565a:	0af70863          	beq	a4,a5,8000570a <sys_unlink+0x18c>
  iunlockput(dp);
    8000565e:	8526                	mv	a0,s1
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	3a6080e7          	jalr	934(ra) # 80003a06 <iunlockput>
  ip->nlink--;
    80005668:	04a95783          	lhu	a5,74(s2)
    8000566c:	37fd                	addiw	a5,a5,-1
    8000566e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005672:	854a                	mv	a0,s2
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	066080e7          	jalr	102(ra) # 800036da <iupdate>
  iunlockput(ip);
    8000567c:	854a                	mv	a0,s2
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	388080e7          	jalr	904(ra) # 80003a06 <iunlockput>
  end_op();
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	b5a080e7          	jalr	-1190(ra) # 800041e0 <end_op>
  return 0;
    8000568e:	4501                	li	a0,0
    80005690:	a84d                	j	80005742 <sys_unlink+0x1c4>
    end_op();
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	b4e080e7          	jalr	-1202(ra) # 800041e0 <end_op>
    return -1;
    8000569a:	557d                	li	a0,-1
    8000569c:	a05d                	j	80005742 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000569e:	00003517          	auipc	a0,0x3
    800056a2:	09250513          	addi	a0,a0,146 # 80008730 <syscalls+0x300>
    800056a6:	ffffb097          	auipc	ra,0xffffb
    800056aa:	f30080e7          	jalr	-208(ra) # 800005d6 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ae:	04c92703          	lw	a4,76(s2)
    800056b2:	02000793          	li	a5,32
    800056b6:	f6e7f9e3          	bgeu	a5,a4,80005628 <sys_unlink+0xaa>
    800056ba:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056be:	4741                	li	a4,16
    800056c0:	86ce                	mv	a3,s3
    800056c2:	f1840613          	addi	a2,s0,-232
    800056c6:	4581                	li	a1,0
    800056c8:	854a                	mv	a0,s2
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	38e080e7          	jalr	910(ra) # 80003a58 <readi>
    800056d2:	47c1                	li	a5,16
    800056d4:	00f51b63          	bne	a0,a5,800056ea <sys_unlink+0x16c>
    if(de.inum != 0)
    800056d8:	f1845783          	lhu	a5,-232(s0)
    800056dc:	e7a1                	bnez	a5,80005724 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056de:	29c1                	addiw	s3,s3,16
    800056e0:	04c92783          	lw	a5,76(s2)
    800056e4:	fcf9ede3          	bltu	s3,a5,800056be <sys_unlink+0x140>
    800056e8:	b781                	j	80005628 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056ea:	00003517          	auipc	a0,0x3
    800056ee:	05e50513          	addi	a0,a0,94 # 80008748 <syscalls+0x318>
    800056f2:	ffffb097          	auipc	ra,0xffffb
    800056f6:	ee4080e7          	jalr	-284(ra) # 800005d6 <panic>
    panic("unlink: writei");
    800056fa:	00003517          	auipc	a0,0x3
    800056fe:	06650513          	addi	a0,a0,102 # 80008760 <syscalls+0x330>
    80005702:	ffffb097          	auipc	ra,0xffffb
    80005706:	ed4080e7          	jalr	-300(ra) # 800005d6 <panic>
    dp->nlink--;
    8000570a:	04a4d783          	lhu	a5,74(s1)
    8000570e:	37fd                	addiw	a5,a5,-1
    80005710:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	fc4080e7          	jalr	-60(ra) # 800036da <iupdate>
    8000571e:	b781                	j	8000565e <sys_unlink+0xe0>
    return -1;
    80005720:	557d                	li	a0,-1
    80005722:	a005                	j	80005742 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005724:	854a                	mv	a0,s2
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	2e0080e7          	jalr	736(ra) # 80003a06 <iunlockput>
  iunlockput(dp);
    8000572e:	8526                	mv	a0,s1
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	2d6080e7          	jalr	726(ra) # 80003a06 <iunlockput>
  end_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	aa8080e7          	jalr	-1368(ra) # 800041e0 <end_op>
  return -1;
    80005740:	557d                	li	a0,-1
}
    80005742:	70ae                	ld	ra,232(sp)
    80005744:	740e                	ld	s0,224(sp)
    80005746:	64ee                	ld	s1,216(sp)
    80005748:	694e                	ld	s2,208(sp)
    8000574a:	69ae                	ld	s3,200(sp)
    8000574c:	616d                	addi	sp,sp,240
    8000574e:	8082                	ret

0000000080005750 <sys_open>:

uint64
sys_open(void)
{
    80005750:	7131                	addi	sp,sp,-192
    80005752:	fd06                	sd	ra,184(sp)
    80005754:	f922                	sd	s0,176(sp)
    80005756:	f526                	sd	s1,168(sp)
    80005758:	f14a                	sd	s2,160(sp)
    8000575a:	ed4e                	sd	s3,152(sp)
    8000575c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000575e:	08000613          	li	a2,128
    80005762:	f5040593          	addi	a1,s0,-176
    80005766:	4501                	li	a0,0
    80005768:	ffffd097          	auipc	ra,0xffffd
    8000576c:	506080e7          	jalr	1286(ra) # 80002c6e <argstr>
    return -1;
    80005770:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005772:	0c054163          	bltz	a0,80005834 <sys_open+0xe4>
    80005776:	f4c40593          	addi	a1,s0,-180
    8000577a:	4505                	li	a0,1
    8000577c:	ffffd097          	auipc	ra,0xffffd
    80005780:	4ae080e7          	jalr	1198(ra) # 80002c2a <argint>
    80005784:	0a054863          	bltz	a0,80005834 <sys_open+0xe4>

  begin_op();
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	9d8080e7          	jalr	-1576(ra) # 80004160 <begin_op>

  if(omode & O_CREATE){
    80005790:	f4c42783          	lw	a5,-180(s0)
    80005794:	2007f793          	andi	a5,a5,512
    80005798:	cbdd                	beqz	a5,8000584e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000579a:	4681                	li	a3,0
    8000579c:	4601                	li	a2,0
    8000579e:	4589                	li	a1,2
    800057a0:	f5040513          	addi	a0,s0,-176
    800057a4:	00000097          	auipc	ra,0x0
    800057a8:	972080e7          	jalr	-1678(ra) # 80005116 <create>
    800057ac:	892a                	mv	s2,a0
    if(ip == 0){
    800057ae:	c959                	beqz	a0,80005844 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057b0:	04491703          	lh	a4,68(s2)
    800057b4:	478d                	li	a5,3
    800057b6:	00f71763          	bne	a4,a5,800057c4 <sys_open+0x74>
    800057ba:	04695703          	lhu	a4,70(s2)
    800057be:	47a5                	li	a5,9
    800057c0:	0ce7ec63          	bltu	a5,a4,80005898 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	db2080e7          	jalr	-590(ra) # 80004576 <filealloc>
    800057cc:	89aa                	mv	s3,a0
    800057ce:	10050263          	beqz	a0,800058d2 <sys_open+0x182>
    800057d2:	00000097          	auipc	ra,0x0
    800057d6:	902080e7          	jalr	-1790(ra) # 800050d4 <fdalloc>
    800057da:	84aa                	mv	s1,a0
    800057dc:	0e054663          	bltz	a0,800058c8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057e0:	04491703          	lh	a4,68(s2)
    800057e4:	478d                	li	a5,3
    800057e6:	0cf70463          	beq	a4,a5,800058ae <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057ea:	4789                	li	a5,2
    800057ec:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057f0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057f4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057f8:	f4c42783          	lw	a5,-180(s0)
    800057fc:	0017c713          	xori	a4,a5,1
    80005800:	8b05                	andi	a4,a4,1
    80005802:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005806:	0037f713          	andi	a4,a5,3
    8000580a:	00e03733          	snez	a4,a4
    8000580e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005812:	4007f793          	andi	a5,a5,1024
    80005816:	c791                	beqz	a5,80005822 <sys_open+0xd2>
    80005818:	04491703          	lh	a4,68(s2)
    8000581c:	4789                	li	a5,2
    8000581e:	08f70f63          	beq	a4,a5,800058bc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005822:	854a                	mv	a0,s2
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	042080e7          	jalr	66(ra) # 80003866 <iunlock>
  end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	9b4080e7          	jalr	-1612(ra) # 800041e0 <end_op>

  return fd;
}
    80005834:	8526                	mv	a0,s1
    80005836:	70ea                	ld	ra,184(sp)
    80005838:	744a                	ld	s0,176(sp)
    8000583a:	74aa                	ld	s1,168(sp)
    8000583c:	790a                	ld	s2,160(sp)
    8000583e:	69ea                	ld	s3,152(sp)
    80005840:	6129                	addi	sp,sp,192
    80005842:	8082                	ret
      end_op();
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	99c080e7          	jalr	-1636(ra) # 800041e0 <end_op>
      return -1;
    8000584c:	b7e5                	j	80005834 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000584e:	f5040513          	addi	a0,s0,-176
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	702080e7          	jalr	1794(ra) # 80003f54 <namei>
    8000585a:	892a                	mv	s2,a0
    8000585c:	c905                	beqz	a0,8000588c <sys_open+0x13c>
    ilock(ip);
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	f46080e7          	jalr	-186(ra) # 800037a4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005866:	04491703          	lh	a4,68(s2)
    8000586a:	4785                	li	a5,1
    8000586c:	f4f712e3          	bne	a4,a5,800057b0 <sys_open+0x60>
    80005870:	f4c42783          	lw	a5,-180(s0)
    80005874:	dba1                	beqz	a5,800057c4 <sys_open+0x74>
      iunlockput(ip);
    80005876:	854a                	mv	a0,s2
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	18e080e7          	jalr	398(ra) # 80003a06 <iunlockput>
      end_op();
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	960080e7          	jalr	-1696(ra) # 800041e0 <end_op>
      return -1;
    80005888:	54fd                	li	s1,-1
    8000588a:	b76d                	j	80005834 <sys_open+0xe4>
      end_op();
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	954080e7          	jalr	-1708(ra) # 800041e0 <end_op>
      return -1;
    80005894:	54fd                	li	s1,-1
    80005896:	bf79                	j	80005834 <sys_open+0xe4>
    iunlockput(ip);
    80005898:	854a                	mv	a0,s2
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	16c080e7          	jalr	364(ra) # 80003a06 <iunlockput>
    end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	93e080e7          	jalr	-1730(ra) # 800041e0 <end_op>
    return -1;
    800058aa:	54fd                	li	s1,-1
    800058ac:	b761                	j	80005834 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058ae:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058b2:	04691783          	lh	a5,70(s2)
    800058b6:	02f99223          	sh	a5,36(s3)
    800058ba:	bf2d                	j	800057f4 <sys_open+0xa4>
    itrunc(ip);
    800058bc:	854a                	mv	a0,s2
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	ff4080e7          	jalr	-12(ra) # 800038b2 <itrunc>
    800058c6:	bfb1                	j	80005822 <sys_open+0xd2>
      fileclose(f);
    800058c8:	854e                	mv	a0,s3
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	d68080e7          	jalr	-664(ra) # 80004632 <fileclose>
    iunlockput(ip);
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	132080e7          	jalr	306(ra) # 80003a06 <iunlockput>
    end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	904080e7          	jalr	-1788(ra) # 800041e0 <end_op>
    return -1;
    800058e4:	54fd                	li	s1,-1
    800058e6:	b7b9                	j	80005834 <sys_open+0xe4>

00000000800058e8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058e8:	7175                	addi	sp,sp,-144
    800058ea:	e506                	sd	ra,136(sp)
    800058ec:	e122                	sd	s0,128(sp)
    800058ee:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	870080e7          	jalr	-1936(ra) # 80004160 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058f8:	08000613          	li	a2,128
    800058fc:	f7040593          	addi	a1,s0,-144
    80005900:	4501                	li	a0,0
    80005902:	ffffd097          	auipc	ra,0xffffd
    80005906:	36c080e7          	jalr	876(ra) # 80002c6e <argstr>
    8000590a:	02054963          	bltz	a0,8000593c <sys_mkdir+0x54>
    8000590e:	4681                	li	a3,0
    80005910:	4601                	li	a2,0
    80005912:	4585                	li	a1,1
    80005914:	f7040513          	addi	a0,s0,-144
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	7fe080e7          	jalr	2046(ra) # 80005116 <create>
    80005920:	cd11                	beqz	a0,8000593c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	0e4080e7          	jalr	228(ra) # 80003a06 <iunlockput>
  end_op();
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	8b6080e7          	jalr	-1866(ra) # 800041e0 <end_op>
  return 0;
    80005932:	4501                	li	a0,0
}
    80005934:	60aa                	ld	ra,136(sp)
    80005936:	640a                	ld	s0,128(sp)
    80005938:	6149                	addi	sp,sp,144
    8000593a:	8082                	ret
    end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	8a4080e7          	jalr	-1884(ra) # 800041e0 <end_op>
    return -1;
    80005944:	557d                	li	a0,-1
    80005946:	b7fd                	j	80005934 <sys_mkdir+0x4c>

0000000080005948 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005948:	7135                	addi	sp,sp,-160
    8000594a:	ed06                	sd	ra,152(sp)
    8000594c:	e922                	sd	s0,144(sp)
    8000594e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	810080e7          	jalr	-2032(ra) # 80004160 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005958:	08000613          	li	a2,128
    8000595c:	f7040593          	addi	a1,s0,-144
    80005960:	4501                	li	a0,0
    80005962:	ffffd097          	auipc	ra,0xffffd
    80005966:	30c080e7          	jalr	780(ra) # 80002c6e <argstr>
    8000596a:	04054a63          	bltz	a0,800059be <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000596e:	f6c40593          	addi	a1,s0,-148
    80005972:	4505                	li	a0,1
    80005974:	ffffd097          	auipc	ra,0xffffd
    80005978:	2b6080e7          	jalr	694(ra) # 80002c2a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000597c:	04054163          	bltz	a0,800059be <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005980:	f6840593          	addi	a1,s0,-152
    80005984:	4509                	li	a0,2
    80005986:	ffffd097          	auipc	ra,0xffffd
    8000598a:	2a4080e7          	jalr	676(ra) # 80002c2a <argint>
     argint(1, &major) < 0 ||
    8000598e:	02054863          	bltz	a0,800059be <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005992:	f6841683          	lh	a3,-152(s0)
    80005996:	f6c41603          	lh	a2,-148(s0)
    8000599a:	458d                	li	a1,3
    8000599c:	f7040513          	addi	a0,s0,-144
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	776080e7          	jalr	1910(ra) # 80005116 <create>
     argint(2, &minor) < 0 ||
    800059a8:	c919                	beqz	a0,800059be <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	05c080e7          	jalr	92(ra) # 80003a06 <iunlockput>
  end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	82e080e7          	jalr	-2002(ra) # 800041e0 <end_op>
  return 0;
    800059ba:	4501                	li	a0,0
    800059bc:	a031                	j	800059c8 <sys_mknod+0x80>
    end_op();
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	822080e7          	jalr	-2014(ra) # 800041e0 <end_op>
    return -1;
    800059c6:	557d                	li	a0,-1
}
    800059c8:	60ea                	ld	ra,152(sp)
    800059ca:	644a                	ld	s0,144(sp)
    800059cc:	610d                	addi	sp,sp,160
    800059ce:	8082                	ret

00000000800059d0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059d0:	7135                	addi	sp,sp,-160
    800059d2:	ed06                	sd	ra,152(sp)
    800059d4:	e922                	sd	s0,144(sp)
    800059d6:	e526                	sd	s1,136(sp)
    800059d8:	e14a                	sd	s2,128(sp)
    800059da:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059dc:	ffffc097          	auipc	ra,0xffffc
    800059e0:	066080e7          	jalr	102(ra) # 80001a42 <myproc>
    800059e4:	892a                	mv	s2,a0
  
  begin_op();
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	77a080e7          	jalr	1914(ra) # 80004160 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059ee:	08000613          	li	a2,128
    800059f2:	f6040593          	addi	a1,s0,-160
    800059f6:	4501                	li	a0,0
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	276080e7          	jalr	630(ra) # 80002c6e <argstr>
    80005a00:	04054b63          	bltz	a0,80005a56 <sys_chdir+0x86>
    80005a04:	f6040513          	addi	a0,s0,-160
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	54c080e7          	jalr	1356(ra) # 80003f54 <namei>
    80005a10:	84aa                	mv	s1,a0
    80005a12:	c131                	beqz	a0,80005a56 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	d90080e7          	jalr	-624(ra) # 800037a4 <ilock>
  if(ip->type != T_DIR){
    80005a1c:	04449703          	lh	a4,68(s1)
    80005a20:	4785                	li	a5,1
    80005a22:	04f71063          	bne	a4,a5,80005a62 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	e3e080e7          	jalr	-450(ra) # 80003866 <iunlock>
  iput(p->cwd);
    80005a30:	15093503          	ld	a0,336(s2)
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	f2a080e7          	jalr	-214(ra) # 8000395e <iput>
  end_op();
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	7a4080e7          	jalr	1956(ra) # 800041e0 <end_op>
  p->cwd = ip;
    80005a44:	14993823          	sd	s1,336(s2)
  return 0;
    80005a48:	4501                	li	a0,0
}
    80005a4a:	60ea                	ld	ra,152(sp)
    80005a4c:	644a                	ld	s0,144(sp)
    80005a4e:	64aa                	ld	s1,136(sp)
    80005a50:	690a                	ld	s2,128(sp)
    80005a52:	610d                	addi	sp,sp,160
    80005a54:	8082                	ret
    end_op();
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	78a080e7          	jalr	1930(ra) # 800041e0 <end_op>
    return -1;
    80005a5e:	557d                	li	a0,-1
    80005a60:	b7ed                	j	80005a4a <sys_chdir+0x7a>
    iunlockput(ip);
    80005a62:	8526                	mv	a0,s1
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	fa2080e7          	jalr	-94(ra) # 80003a06 <iunlockput>
    end_op();
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	774080e7          	jalr	1908(ra) # 800041e0 <end_op>
    return -1;
    80005a74:	557d                	li	a0,-1
    80005a76:	bfd1                	j	80005a4a <sys_chdir+0x7a>

0000000080005a78 <sys_exec>:

uint64
sys_exec(void)
{
    80005a78:	7145                	addi	sp,sp,-464
    80005a7a:	e786                	sd	ra,456(sp)
    80005a7c:	e3a2                	sd	s0,448(sp)
    80005a7e:	ff26                	sd	s1,440(sp)
    80005a80:	fb4a                	sd	s2,432(sp)
    80005a82:	f74e                	sd	s3,424(sp)
    80005a84:	f352                	sd	s4,416(sp)
    80005a86:	ef56                	sd	s5,408(sp)
    80005a88:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a8a:	08000613          	li	a2,128
    80005a8e:	f4040593          	addi	a1,s0,-192
    80005a92:	4501                	li	a0,0
    80005a94:	ffffd097          	auipc	ra,0xffffd
    80005a98:	1da080e7          	jalr	474(ra) # 80002c6e <argstr>
    return -1;
    80005a9c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a9e:	0c054a63          	bltz	a0,80005b72 <sys_exec+0xfa>
    80005aa2:	e3840593          	addi	a1,s0,-456
    80005aa6:	4505                	li	a0,1
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	1a4080e7          	jalr	420(ra) # 80002c4c <argaddr>
    80005ab0:	0c054163          	bltz	a0,80005b72 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ab4:	10000613          	li	a2,256
    80005ab8:	4581                	li	a1,0
    80005aba:	e4040513          	addi	a0,s0,-448
    80005abe:	ffffb097          	auipc	ra,0xffffb
    80005ac2:	2b2080e7          	jalr	690(ra) # 80000d70 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ac6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005aca:	89a6                	mv	s3,s1
    80005acc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ace:	02000a13          	li	s4,32
    80005ad2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ad6:	00391513          	slli	a0,s2,0x3
    80005ada:	e3040593          	addi	a1,s0,-464
    80005ade:	e3843783          	ld	a5,-456(s0)
    80005ae2:	953e                	add	a0,a0,a5
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	0ac080e7          	jalr	172(ra) # 80002b90 <fetchaddr>
    80005aec:	02054a63          	bltz	a0,80005b20 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005af0:	e3043783          	ld	a5,-464(s0)
    80005af4:	c3b9                	beqz	a5,80005b3a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005af6:	ffffb097          	auipc	ra,0xffffb
    80005afa:	08e080e7          	jalr	142(ra) # 80000b84 <kalloc>
    80005afe:	85aa                	mv	a1,a0
    80005b00:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b04:	cd11                	beqz	a0,80005b20 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b06:	6605                	lui	a2,0x1
    80005b08:	e3043503          	ld	a0,-464(s0)
    80005b0c:	ffffd097          	auipc	ra,0xffffd
    80005b10:	0d6080e7          	jalr	214(ra) # 80002be2 <fetchstr>
    80005b14:	00054663          	bltz	a0,80005b20 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b18:	0905                	addi	s2,s2,1
    80005b1a:	09a1                	addi	s3,s3,8
    80005b1c:	fb491be3          	bne	s2,s4,80005ad2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b20:	10048913          	addi	s2,s1,256
    80005b24:	6088                	ld	a0,0(s1)
    80005b26:	c529                	beqz	a0,80005b70 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b28:	ffffb097          	auipc	ra,0xffffb
    80005b2c:	f60080e7          	jalr	-160(ra) # 80000a88 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b30:	04a1                	addi	s1,s1,8
    80005b32:	ff2499e3          	bne	s1,s2,80005b24 <sys_exec+0xac>
  return -1;
    80005b36:	597d                	li	s2,-1
    80005b38:	a82d                	j	80005b72 <sys_exec+0xfa>
      argv[i] = 0;
    80005b3a:	0a8e                	slli	s5,s5,0x3
    80005b3c:	fc040793          	addi	a5,s0,-64
    80005b40:	9abe                	add	s5,s5,a5
    80005b42:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b46:	e4040593          	addi	a1,s0,-448
    80005b4a:	f4040513          	addi	a0,s0,-192
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	194080e7          	jalr	404(ra) # 80004ce2 <exec>
    80005b56:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b58:	10048993          	addi	s3,s1,256
    80005b5c:	6088                	ld	a0,0(s1)
    80005b5e:	c911                	beqz	a0,80005b72 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b60:	ffffb097          	auipc	ra,0xffffb
    80005b64:	f28080e7          	jalr	-216(ra) # 80000a88 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b68:	04a1                	addi	s1,s1,8
    80005b6a:	ff3499e3          	bne	s1,s3,80005b5c <sys_exec+0xe4>
    80005b6e:	a011                	j	80005b72 <sys_exec+0xfa>
  return -1;
    80005b70:	597d                	li	s2,-1
}
    80005b72:	854a                	mv	a0,s2
    80005b74:	60be                	ld	ra,456(sp)
    80005b76:	641e                	ld	s0,448(sp)
    80005b78:	74fa                	ld	s1,440(sp)
    80005b7a:	795a                	ld	s2,432(sp)
    80005b7c:	79ba                	ld	s3,424(sp)
    80005b7e:	7a1a                	ld	s4,416(sp)
    80005b80:	6afa                	ld	s5,408(sp)
    80005b82:	6179                	addi	sp,sp,464
    80005b84:	8082                	ret

0000000080005b86 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b86:	7139                	addi	sp,sp,-64
    80005b88:	fc06                	sd	ra,56(sp)
    80005b8a:	f822                	sd	s0,48(sp)
    80005b8c:	f426                	sd	s1,40(sp)
    80005b8e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b90:	ffffc097          	auipc	ra,0xffffc
    80005b94:	eb2080e7          	jalr	-334(ra) # 80001a42 <myproc>
    80005b98:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b9a:	fd840593          	addi	a1,s0,-40
    80005b9e:	4501                	li	a0,0
    80005ba0:	ffffd097          	auipc	ra,0xffffd
    80005ba4:	0ac080e7          	jalr	172(ra) # 80002c4c <argaddr>
    return -1;
    80005ba8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005baa:	0e054063          	bltz	a0,80005c8a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bae:	fc840593          	addi	a1,s0,-56
    80005bb2:	fd040513          	addi	a0,s0,-48
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	dd2080e7          	jalr	-558(ra) # 80004988 <pipealloc>
    return -1;
    80005bbe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bc0:	0c054563          	bltz	a0,80005c8a <sys_pipe+0x104>
  fd0 = -1;
    80005bc4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bc8:	fd043503          	ld	a0,-48(s0)
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	508080e7          	jalr	1288(ra) # 800050d4 <fdalloc>
    80005bd4:	fca42223          	sw	a0,-60(s0)
    80005bd8:	08054c63          	bltz	a0,80005c70 <sys_pipe+0xea>
    80005bdc:	fc843503          	ld	a0,-56(s0)
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	4f4080e7          	jalr	1268(ra) # 800050d4 <fdalloc>
    80005be8:	fca42023          	sw	a0,-64(s0)
    80005bec:	06054863          	bltz	a0,80005c5c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf0:	4691                	li	a3,4
    80005bf2:	fc440613          	addi	a2,s0,-60
    80005bf6:	fd843583          	ld	a1,-40(s0)
    80005bfa:	68a8                	ld	a0,80(s1)
    80005bfc:	ffffc097          	auipc	ra,0xffffc
    80005c00:	b3a080e7          	jalr	-1222(ra) # 80001736 <copyout>
    80005c04:	02054063          	bltz	a0,80005c24 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c08:	4691                	li	a3,4
    80005c0a:	fc040613          	addi	a2,s0,-64
    80005c0e:	fd843583          	ld	a1,-40(s0)
    80005c12:	0591                	addi	a1,a1,4
    80005c14:	68a8                	ld	a0,80(s1)
    80005c16:	ffffc097          	auipc	ra,0xffffc
    80005c1a:	b20080e7          	jalr	-1248(ra) # 80001736 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c1e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c20:	06055563          	bgez	a0,80005c8a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c24:	fc442783          	lw	a5,-60(s0)
    80005c28:	07e9                	addi	a5,a5,26
    80005c2a:	078e                	slli	a5,a5,0x3
    80005c2c:	97a6                	add	a5,a5,s1
    80005c2e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c32:	fc042503          	lw	a0,-64(s0)
    80005c36:	0569                	addi	a0,a0,26
    80005c38:	050e                	slli	a0,a0,0x3
    80005c3a:	9526                	add	a0,a0,s1
    80005c3c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c40:	fd043503          	ld	a0,-48(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	9ee080e7          	jalr	-1554(ra) # 80004632 <fileclose>
    fileclose(wf);
    80005c4c:	fc843503          	ld	a0,-56(s0)
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	9e2080e7          	jalr	-1566(ra) # 80004632 <fileclose>
    return -1;
    80005c58:	57fd                	li	a5,-1
    80005c5a:	a805                	j	80005c8a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c5c:	fc442783          	lw	a5,-60(s0)
    80005c60:	0007c863          	bltz	a5,80005c70 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c64:	01a78513          	addi	a0,a5,26
    80005c68:	050e                	slli	a0,a0,0x3
    80005c6a:	9526                	add	a0,a0,s1
    80005c6c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c70:	fd043503          	ld	a0,-48(s0)
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	9be080e7          	jalr	-1602(ra) # 80004632 <fileclose>
    fileclose(wf);
    80005c7c:	fc843503          	ld	a0,-56(s0)
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	9b2080e7          	jalr	-1614(ra) # 80004632 <fileclose>
    return -1;
    80005c88:	57fd                	li	a5,-1
}
    80005c8a:	853e                	mv	a0,a5
    80005c8c:	70e2                	ld	ra,56(sp)
    80005c8e:	7442                	ld	s0,48(sp)
    80005c90:	74a2                	ld	s1,40(sp)
    80005c92:	6121                	addi	sp,sp,64
    80005c94:	8082                	ret

0000000080005c96 <sigalarm>:

int 
sigalarm(int ticks, void (*handler)())
{
    80005c96:	1101                	addi	sp,sp,-32
    80005c98:	ec06                	sd	ra,24(sp)
    80005c9a:	e822                	sd	s0,16(sp)
    80005c9c:	e426                	sd	s1,8(sp)
    80005c9e:	e04a                	sd	s2,0(sp)
    80005ca0:	1000                	addi	s0,sp,32
    80005ca2:	892a                	mv	s2,a0
    80005ca4:	84ae                	mv	s1,a1
  struct proc* p = myproc();
    80005ca6:	ffffc097          	auipc	ra,0xffffc
    80005caa:	d9c080e7          	jalr	-612(ra) # 80001a42 <myproc>
  p->ticked = 0;
    80005cae:	16052623          	sw	zero,364(a0)
  p->ticks = ticks;
    80005cb2:	17252423          	sw	s2,360(a0)
  p->handler = handler;
    80005cb6:	16953823          	sd	s1,368(a0)
  return 0;
}
    80005cba:	4501                	li	a0,0
    80005cbc:	60e2                	ld	ra,24(sp)
    80005cbe:	6442                	ld	s0,16(sp)
    80005cc0:	64a2                	ld	s1,8(sp)
    80005cc2:	6902                	ld	s2,0(sp)
    80005cc4:	6105                	addi	sp,sp,32
    80005cc6:	8082                	ret

0000000080005cc8 <sigreturn>:
    
int 
sigreturn(void)
{
    80005cc8:	1141                	addi	sp,sp,-16
    80005cca:	e406                	sd	ra,8(sp)
    80005ccc:	e022                	sd	s0,0(sp)
    80005cce:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    80005cd0:	ffffc097          	auipc	ra,0xffffc
    80005cd4:	d72080e7          	jalr	-654(ra) # 80001a42 <myproc>
  p->trapframe->epc = p->last_epc;
    80005cd8:	6d3c                	ld	a5,88(a0)
    80005cda:	17853703          	ld	a4,376(a0)
    80005cde:	ef98                	sd	a4,24(a5)
  p->trapframe->ra = p->ra;
    80005ce0:	6d3c                	ld	a5,88(a0)
    80005ce2:	18853703          	ld	a4,392(a0)
    80005ce6:	f798                	sd	a4,40(a5)
  p->trapframe->sp = p->sp;
    80005ce8:	6d3c                	ld	a5,88(a0)
    80005cea:	19053703          	ld	a4,400(a0)
    80005cee:	fb98                	sd	a4,48(a5)
  p->trapframe->gp = p->gp;
    80005cf0:	6d3c                	ld	a5,88(a0)
    80005cf2:	19853703          	ld	a4,408(a0)
    80005cf6:	ff98                	sd	a4,56(a5)
  p->trapframe->tp = p->tp;
    80005cf8:	6d3c                	ld	a5,88(a0)
    80005cfa:	1a053703          	ld	a4,416(a0)
    80005cfe:	e3b8                	sd	a4,64(a5)
  p->trapframe->t0 = p->t0;
    80005d00:	6d3c                	ld	a5,88(a0)
    80005d02:	1a853703          	ld	a4,424(a0)
    80005d06:	e7b8                	sd	a4,72(a5)
  p->trapframe->t1 = p->t1;
    80005d08:	6d3c                	ld	a5,88(a0)
    80005d0a:	1b053703          	ld	a4,432(a0)
    80005d0e:	ebb8                	sd	a4,80(a5)
  p->trapframe->t2 = p->t2;
    80005d10:	6d3c                	ld	a5,88(a0)
    80005d12:	1b853703          	ld	a4,440(a0)
    80005d16:	efb8                	sd	a4,88(a5)
  p->trapframe->s0 = p->s0;
    80005d18:	6d3c                	ld	a5,88(a0)
    80005d1a:	1c053703          	ld	a4,448(a0)
    80005d1e:	f3b8                	sd	a4,96(a5)
  p->trapframe->s1 = p->s1;
    80005d20:	6d3c                	ld	a5,88(a0)
    80005d22:	1c853703          	ld	a4,456(a0)
    80005d26:	f7b8                	sd	a4,104(a5)
  p->trapframe->s2 = p->s2;
    80005d28:	6d3c                	ld	a5,88(a0)
    80005d2a:	21053703          	ld	a4,528(a0)
    80005d2e:	fbd8                	sd	a4,176(a5)
  p->trapframe->s3 = p->s3;
    80005d30:	6d3c                	ld	a5,88(a0)
    80005d32:	21853703          	ld	a4,536(a0)
    80005d36:	ffd8                	sd	a4,184(a5)
  p->trapframe->s4 = p->s4;
    80005d38:	6d3c                	ld	a5,88(a0)
    80005d3a:	22053703          	ld	a4,544(a0)
    80005d3e:	e3f8                	sd	a4,192(a5)
  p->trapframe->s5 = p->s5;
    80005d40:	6d3c                	ld	a5,88(a0)
    80005d42:	22853703          	ld	a4,552(a0)
    80005d46:	e7f8                	sd	a4,200(a5)
  p->trapframe->s6 = p->s6;
    80005d48:	6d3c                	ld	a5,88(a0)
    80005d4a:	23053703          	ld	a4,560(a0)
    80005d4e:	ebf8                	sd	a4,208(a5)
  p->trapframe->s7 = p->s7;
    80005d50:	6d3c                	ld	a5,88(a0)
    80005d52:	23853703          	ld	a4,568(a0)
    80005d56:	eff8                	sd	a4,216(a5)
  p->trapframe->s8 = p->s8;
    80005d58:	6d3c                	ld	a5,88(a0)
    80005d5a:	24053703          	ld	a4,576(a0)
    80005d5e:	f3f8                	sd	a4,224(a5)
  p->trapframe->s9 = p->s9;
    80005d60:	6d3c                	ld	a5,88(a0)
    80005d62:	24853703          	ld	a4,584(a0)
    80005d66:	f7f8                	sd	a4,232(a5)
  p->trapframe->s10 = p->s10;
    80005d68:	6d3c                	ld	a5,88(a0)
    80005d6a:	25053703          	ld	a4,592(a0)
    80005d6e:	fbf8                	sd	a4,240(a5)
  p->trapframe->s11 = p->s11;
    80005d70:	6d3c                	ld	a5,88(a0)
    80005d72:	25853703          	ld	a4,600(a0)
    80005d76:	fff8                	sd	a4,248(a5)
  p->trapframe->a0 = p->a0;
    80005d78:	6d3c                	ld	a5,88(a0)
    80005d7a:	1d053703          	ld	a4,464(a0)
    80005d7e:	fbb8                	sd	a4,112(a5)
  p->trapframe->a1 = p->a1;
    80005d80:	6d3c                	ld	a5,88(a0)
    80005d82:	1d853703          	ld	a4,472(a0)
    80005d86:	ffb8                	sd	a4,120(a5)
  p->trapframe->a2 = p->a2;
    80005d88:	6d3c                	ld	a5,88(a0)
    80005d8a:	1e053703          	ld	a4,480(a0)
    80005d8e:	e3d8                	sd	a4,128(a5)
  p->trapframe->a3 = p->a3;
    80005d90:	6d3c                	ld	a5,88(a0)
    80005d92:	1e853703          	ld	a4,488(a0)
    80005d96:	e7d8                	sd	a4,136(a5)
  p->trapframe->a4 = p->a4;
    80005d98:	6d3c                	ld	a5,88(a0)
    80005d9a:	1f053703          	ld	a4,496(a0)
    80005d9e:	ebd8                	sd	a4,144(a5)
  p->trapframe->a5 = p->a5;
    80005da0:	6d3c                	ld	a5,88(a0)
    80005da2:	1f853703          	ld	a4,504(a0)
    80005da6:	efd8                	sd	a4,152(a5)
  p->trapframe->a6 = p->a6;
    80005da8:	6d3c                	ld	a5,88(a0)
    80005daa:	20053703          	ld	a4,512(a0)
    80005dae:	f3d8                	sd	a4,160(a5)
  p->trapframe->a7 = p->a7;
    80005db0:	6d3c                	ld	a5,88(a0)
    80005db2:	20853703          	ld	a4,520(a0)
    80005db6:	f7d8                	sd	a4,168(a5)
  p->trapframe->t3 = p->t3;
    80005db8:	6d3c                	ld	a5,88(a0)
    80005dba:	26053703          	ld	a4,608(a0)
    80005dbe:	10e7b023          	sd	a4,256(a5)
  p->trapframe->t4 = p->t4;
    80005dc2:	6d3c                	ld	a5,88(a0)
    80005dc4:	26853703          	ld	a4,616(a0)
    80005dc8:	10e7b423          	sd	a4,264(a5)
  p->trapframe->t5 = p->t5;
    80005dcc:	6d3c                	ld	a5,88(a0)
    80005dce:	27053703          	ld	a4,624(a0)
    80005dd2:	10e7b823          	sd	a4,272(a5)
  p->trapframe->t6 = p->t6;
    80005dd6:	6d3c                	ld	a5,88(a0)
    80005dd8:	27853703          	ld	a4,632(a0)
    80005ddc:	10e7bc23          	sd	a4,280(a5)
  p->flag = 1;
    80005de0:	4785                	li	a5,1
    80005de2:	18f52023          	sw	a5,384(a0)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80005de6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80005dea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80005dee:	10079073          	csrw	sstatus,a5
  intr_on();
  return 0;
}
    80005df2:	4501                	li	a0,0
    80005df4:	60a2                	ld	ra,8(sp)
    80005df6:	6402                	ld	s0,0(sp)
    80005df8:	0141                	addi	sp,sp,16
    80005dfa:	8082                	ret

0000000080005dfc <sys_sigalarm>:

int
sys_sigalarm(void)
{
    80005dfc:	7179                	addi	sp,sp,-48
    80005dfe:	f406                	sd	ra,40(sp)
    80005e00:	f022                	sd	s0,32(sp)
    80005e02:	ec26                	sd	s1,24(sp)
    80005e04:	1800                	addi	s0,sp,48
  int ticks;
  uint64 rfn;
  if (argint(0, &ticks) < 0 || argaddr(1, &rfn) != 0) {
    80005e06:	fdc40593          	addi	a1,s0,-36
    80005e0a:	4501                	li	a0,0
    80005e0c:	ffffd097          	auipc	ra,0xffffd
    80005e10:	e1e080e7          	jalr	-482(ra) # 80002c2a <argint>
    80005e14:	02054963          	bltz	a0,80005e46 <sys_sigalarm+0x4a>
    80005e18:	fd040593          	addi	a1,s0,-48
    80005e1c:	4505                	li	a0,1
    80005e1e:	ffffd097          	auipc	ra,0xffffd
    80005e22:	e2e080e7          	jalr	-466(ra) # 80002c4c <argaddr>
    80005e26:	84aa                	mv	s1,a0
    80005e28:	e10d                	bnez	a0,80005e4a <sys_sigalarm+0x4e>
    return -1;
  }

  sigalarm(ticks, (void *)rfn);
    80005e2a:	fd043583          	ld	a1,-48(s0)
    80005e2e:	fdc42503          	lw	a0,-36(s0)
    80005e32:	00000097          	auipc	ra,0x0
    80005e36:	e64080e7          	jalr	-412(ra) # 80005c96 <sigalarm>
  return 0;
}
    80005e3a:	8526                	mv	a0,s1
    80005e3c:	70a2                	ld	ra,40(sp)
    80005e3e:	7402                	ld	s0,32(sp)
    80005e40:	64e2                	ld	s1,24(sp)
    80005e42:	6145                	addi	sp,sp,48
    80005e44:	8082                	ret
    return -1;
    80005e46:	54fd                	li	s1,-1
    80005e48:	bfcd                	j	80005e3a <sys_sigalarm+0x3e>
    80005e4a:	54fd                	li	s1,-1
    80005e4c:	b7fd                	j	80005e3a <sys_sigalarm+0x3e>

0000000080005e4e <sys_sigreturn>:

int
sys_sigreturn(void)
{
    80005e4e:	1141                	addi	sp,sp,-16
    80005e50:	e406                	sd	ra,8(sp)
    80005e52:	e022                	sd	s0,0(sp)
    80005e54:	0800                	addi	s0,sp,16
  sigreturn();
    80005e56:	00000097          	auipc	ra,0x0
    80005e5a:	e72080e7          	jalr	-398(ra) # 80005cc8 <sigreturn>
  return 0; 
    80005e5e:	4501                	li	a0,0
    80005e60:	60a2                	ld	ra,8(sp)
    80005e62:	6402                	ld	s0,0(sp)
    80005e64:	0141                	addi	sp,sp,16
    80005e66:	8082                	ret
	...

0000000080005e70 <kernelvec>:
    80005e70:	7111                	addi	sp,sp,-256
    80005e72:	e006                	sd	ra,0(sp)
    80005e74:	e40a                	sd	sp,8(sp)
    80005e76:	e80e                	sd	gp,16(sp)
    80005e78:	ec12                	sd	tp,24(sp)
    80005e7a:	f016                	sd	t0,32(sp)
    80005e7c:	f41a                	sd	t1,40(sp)
    80005e7e:	f81e                	sd	t2,48(sp)
    80005e80:	fc22                	sd	s0,56(sp)
    80005e82:	e0a6                	sd	s1,64(sp)
    80005e84:	e4aa                	sd	a0,72(sp)
    80005e86:	e8ae                	sd	a1,80(sp)
    80005e88:	ecb2                	sd	a2,88(sp)
    80005e8a:	f0b6                	sd	a3,96(sp)
    80005e8c:	f4ba                	sd	a4,104(sp)
    80005e8e:	f8be                	sd	a5,112(sp)
    80005e90:	fcc2                	sd	a6,120(sp)
    80005e92:	e146                	sd	a7,128(sp)
    80005e94:	e54a                	sd	s2,136(sp)
    80005e96:	e94e                	sd	s3,144(sp)
    80005e98:	ed52                	sd	s4,152(sp)
    80005e9a:	f156                	sd	s5,160(sp)
    80005e9c:	f55a                	sd	s6,168(sp)
    80005e9e:	f95e                	sd	s7,176(sp)
    80005ea0:	fd62                	sd	s8,184(sp)
    80005ea2:	e1e6                	sd	s9,192(sp)
    80005ea4:	e5ea                	sd	s10,200(sp)
    80005ea6:	e9ee                	sd	s11,208(sp)
    80005ea8:	edf2                	sd	t3,216(sp)
    80005eaa:	f1f6                	sd	t4,224(sp)
    80005eac:	f5fa                	sd	t5,232(sp)
    80005eae:	f9fe                	sd	t6,240(sp)
    80005eb0:	badfc0ef          	jal	ra,80002a5c <kerneltrap>
    80005eb4:	6082                	ld	ra,0(sp)
    80005eb6:	6122                	ld	sp,8(sp)
    80005eb8:	61c2                	ld	gp,16(sp)
    80005eba:	7282                	ld	t0,32(sp)
    80005ebc:	7322                	ld	t1,40(sp)
    80005ebe:	73c2                	ld	t2,48(sp)
    80005ec0:	7462                	ld	s0,56(sp)
    80005ec2:	6486                	ld	s1,64(sp)
    80005ec4:	6526                	ld	a0,72(sp)
    80005ec6:	65c6                	ld	a1,80(sp)
    80005ec8:	6666                	ld	a2,88(sp)
    80005eca:	7686                	ld	a3,96(sp)
    80005ecc:	7726                	ld	a4,104(sp)
    80005ece:	77c6                	ld	a5,112(sp)
    80005ed0:	7866                	ld	a6,120(sp)
    80005ed2:	688a                	ld	a7,128(sp)
    80005ed4:	692a                	ld	s2,136(sp)
    80005ed6:	69ca                	ld	s3,144(sp)
    80005ed8:	6a6a                	ld	s4,152(sp)
    80005eda:	7a8a                	ld	s5,160(sp)
    80005edc:	7b2a                	ld	s6,168(sp)
    80005ede:	7bca                	ld	s7,176(sp)
    80005ee0:	7c6a                	ld	s8,184(sp)
    80005ee2:	6c8e                	ld	s9,192(sp)
    80005ee4:	6d2e                	ld	s10,200(sp)
    80005ee6:	6dce                	ld	s11,208(sp)
    80005ee8:	6e6e                	ld	t3,216(sp)
    80005eea:	7e8e                	ld	t4,224(sp)
    80005eec:	7f2e                	ld	t5,232(sp)
    80005eee:	7fce                	ld	t6,240(sp)
    80005ef0:	6111                	addi	sp,sp,256
    80005ef2:	10200073          	sret
    80005ef6:	00000013          	nop
    80005efa:	00000013          	nop
    80005efe:	0001                	nop

0000000080005f00 <timervec>:
    80005f00:	34051573          	csrrw	a0,mscratch,a0
    80005f04:	e10c                	sd	a1,0(a0)
    80005f06:	e510                	sd	a2,8(a0)
    80005f08:	e914                	sd	a3,16(a0)
    80005f0a:	710c                	ld	a1,32(a0)
    80005f0c:	7510                	ld	a2,40(a0)
    80005f0e:	6194                	ld	a3,0(a1)
    80005f10:	96b2                	add	a3,a3,a2
    80005f12:	e194                	sd	a3,0(a1)
    80005f14:	4589                	li	a1,2
    80005f16:	14459073          	csrw	sip,a1
    80005f1a:	6914                	ld	a3,16(a0)
    80005f1c:	6510                	ld	a2,8(a0)
    80005f1e:	610c                	ld	a1,0(a0)
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	30200073          	mret
	...

0000000080005f2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f2a:	1141                	addi	sp,sp,-16
    80005f2c:	e422                	sd	s0,8(sp)
    80005f2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f30:	0c0007b7          	lui	a5,0xc000
    80005f34:	4705                	li	a4,1
    80005f36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f38:	c3d8                	sw	a4,4(a5)
}
    80005f3a:	6422                	ld	s0,8(sp)
    80005f3c:	0141                	addi	sp,sp,16
    80005f3e:	8082                	ret

0000000080005f40 <plicinithart>:

void
plicinithart(void)
{
    80005f40:	1141                	addi	sp,sp,-16
    80005f42:	e406                	sd	ra,8(sp)
    80005f44:	e022                	sd	s0,0(sp)
    80005f46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	ace080e7          	jalr	-1330(ra) # 80001a16 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f50:	0085171b          	slliw	a4,a0,0x8
    80005f54:	0c0027b7          	lui	a5,0xc002
    80005f58:	97ba                	add	a5,a5,a4
    80005f5a:	40200713          	li	a4,1026
    80005f5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f62:	00d5151b          	slliw	a0,a0,0xd
    80005f66:	0c2017b7          	lui	a5,0xc201
    80005f6a:	953e                	add	a0,a0,a5
    80005f6c:	00052023          	sw	zero,0(a0)
}
    80005f70:	60a2                	ld	ra,8(sp)
    80005f72:	6402                	ld	s0,0(sp)
    80005f74:	0141                	addi	sp,sp,16
    80005f76:	8082                	ret

0000000080005f78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f78:	1141                	addi	sp,sp,-16
    80005f7a:	e406                	sd	ra,8(sp)
    80005f7c:	e022                	sd	s0,0(sp)
    80005f7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f80:	ffffc097          	auipc	ra,0xffffc
    80005f84:	a96080e7          	jalr	-1386(ra) # 80001a16 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f88:	00d5179b          	slliw	a5,a0,0xd
    80005f8c:	0c201537          	lui	a0,0xc201
    80005f90:	953e                	add	a0,a0,a5
  return irq;
}
    80005f92:	4148                	lw	a0,4(a0)
    80005f94:	60a2                	ld	ra,8(sp)
    80005f96:	6402                	ld	s0,0(sp)
    80005f98:	0141                	addi	sp,sp,16
    80005f9a:	8082                	ret

0000000080005f9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f9c:	1101                	addi	sp,sp,-32
    80005f9e:	ec06                	sd	ra,24(sp)
    80005fa0:	e822                	sd	s0,16(sp)
    80005fa2:	e426                	sd	s1,8(sp)
    80005fa4:	1000                	addi	s0,sp,32
    80005fa6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	a6e080e7          	jalr	-1426(ra) # 80001a16 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fb0:	00d5151b          	slliw	a0,a0,0xd
    80005fb4:	0c2017b7          	lui	a5,0xc201
    80005fb8:	97aa                	add	a5,a5,a0
    80005fba:	c3c4                	sw	s1,4(a5)
}
    80005fbc:	60e2                	ld	ra,24(sp)
    80005fbe:	6442                	ld	s0,16(sp)
    80005fc0:	64a2                	ld	s1,8(sp)
    80005fc2:	6105                	addi	sp,sp,32
    80005fc4:	8082                	ret

0000000080005fc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fc6:	1141                	addi	sp,sp,-16
    80005fc8:	e406                	sd	ra,8(sp)
    80005fca:	e022                	sd	s0,0(sp)
    80005fcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fce:	479d                	li	a5,7
    80005fd0:	04a7cc63          	blt	a5,a0,80006028 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005fd4:	00022797          	auipc	a5,0x22
    80005fd8:	02c78793          	addi	a5,a5,44 # 80028000 <disk>
    80005fdc:	00a78733          	add	a4,a5,a0
    80005fe0:	6789                	lui	a5,0x2
    80005fe2:	97ba                	add	a5,a5,a4
    80005fe4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fe8:	eba1                	bnez	a5,80006038 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005fea:	00451713          	slli	a4,a0,0x4
    80005fee:	00024797          	auipc	a5,0x24
    80005ff2:	0127b783          	ld	a5,18(a5) # 8002a000 <disk+0x2000>
    80005ff6:	97ba                	add	a5,a5,a4
    80005ff8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005ffc:	00022797          	auipc	a5,0x22
    80006000:	00478793          	addi	a5,a5,4 # 80028000 <disk>
    80006004:	97aa                	add	a5,a5,a0
    80006006:	6509                	lui	a0,0x2
    80006008:	953e                	add	a0,a0,a5
    8000600a:	4785                	li	a5,1
    8000600c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006010:	00024517          	auipc	a0,0x24
    80006014:	00850513          	addi	a0,a0,8 # 8002a018 <disk+0x2018>
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	3ce080e7          	jalr	974(ra) # 800023e6 <wakeup>
}
    80006020:	60a2                	ld	ra,8(sp)
    80006022:	6402                	ld	s0,0(sp)
    80006024:	0141                	addi	sp,sp,16
    80006026:	8082                	ret
    panic("virtio_disk_intr 1");
    80006028:	00002517          	auipc	a0,0x2
    8000602c:	74850513          	addi	a0,a0,1864 # 80008770 <syscalls+0x340>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	5a6080e7          	jalr	1446(ra) # 800005d6 <panic>
    panic("virtio_disk_intr 2");
    80006038:	00002517          	auipc	a0,0x2
    8000603c:	75050513          	addi	a0,a0,1872 # 80008788 <syscalls+0x358>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	596080e7          	jalr	1430(ra) # 800005d6 <panic>

0000000080006048 <virtio_disk_init>:
{
    80006048:	1101                	addi	sp,sp,-32
    8000604a:	ec06                	sd	ra,24(sp)
    8000604c:	e822                	sd	s0,16(sp)
    8000604e:	e426                	sd	s1,8(sp)
    80006050:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006052:	00002597          	auipc	a1,0x2
    80006056:	74e58593          	addi	a1,a1,1870 # 800087a0 <syscalls+0x370>
    8000605a:	00024517          	auipc	a0,0x24
    8000605e:	04e50513          	addi	a0,a0,78 # 8002a0a8 <disk+0x20a8>
    80006062:	ffffb097          	auipc	ra,0xffffb
    80006066:	b82080e7          	jalr	-1150(ra) # 80000be4 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000606a:	100017b7          	lui	a5,0x10001
    8000606e:	4398                	lw	a4,0(a5)
    80006070:	2701                	sext.w	a4,a4
    80006072:	747277b7          	lui	a5,0x74727
    80006076:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000607a:	0ef71163          	bne	a4,a5,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000607e:	100017b7          	lui	a5,0x10001
    80006082:	43dc                	lw	a5,4(a5)
    80006084:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006086:	4705                	li	a4,1
    80006088:	0ce79a63          	bne	a5,a4,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000608c:	100017b7          	lui	a5,0x10001
    80006090:	479c                	lw	a5,8(a5)
    80006092:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006094:	4709                	li	a4,2
    80006096:	0ce79363          	bne	a5,a4,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000609a:	100017b7          	lui	a5,0x10001
    8000609e:	47d8                	lw	a4,12(a5)
    800060a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060a2:	554d47b7          	lui	a5,0x554d4
    800060a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060aa:	0af71963          	bne	a4,a5,8000615c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ae:	100017b7          	lui	a5,0x10001
    800060b2:	4705                	li	a4,1
    800060b4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b6:	470d                	li	a4,3
    800060b8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060bc:	c7ffe737          	lui	a4,0xc7ffe
    800060c0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd375f>
    800060c4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060c6:	2701                	sext.w	a4,a4
    800060c8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ca:	472d                	li	a4,11
    800060cc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ce:	473d                	li	a4,15
    800060d0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060d2:	6705                	lui	a4,0x1
    800060d4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060d6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060da:	5bdc                	lw	a5,52(a5)
    800060dc:	2781                	sext.w	a5,a5
  if(max == 0)
    800060de:	c7d9                	beqz	a5,8000616c <virtio_disk_init+0x124>
  if(max < NUM)
    800060e0:	471d                	li	a4,7
    800060e2:	08f77d63          	bgeu	a4,a5,8000617c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060e6:	100014b7          	lui	s1,0x10001
    800060ea:	47a1                	li	a5,8
    800060ec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060ee:	6609                	lui	a2,0x2
    800060f0:	4581                	li	a1,0
    800060f2:	00022517          	auipc	a0,0x22
    800060f6:	f0e50513          	addi	a0,a0,-242 # 80028000 <disk>
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	c76080e7          	jalr	-906(ra) # 80000d70 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006102:	00022717          	auipc	a4,0x22
    80006106:	efe70713          	addi	a4,a4,-258 # 80028000 <disk>
    8000610a:	00c75793          	srli	a5,a4,0xc
    8000610e:	2781                	sext.w	a5,a5
    80006110:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006112:	00024797          	auipc	a5,0x24
    80006116:	eee78793          	addi	a5,a5,-274 # 8002a000 <disk+0x2000>
    8000611a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000611c:	00022717          	auipc	a4,0x22
    80006120:	f6470713          	addi	a4,a4,-156 # 80028080 <disk+0x80>
    80006124:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006126:	00023717          	auipc	a4,0x23
    8000612a:	eda70713          	addi	a4,a4,-294 # 80029000 <disk+0x1000>
    8000612e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006130:	4705                	li	a4,1
    80006132:	00e78c23          	sb	a4,24(a5)
    80006136:	00e78ca3          	sb	a4,25(a5)
    8000613a:	00e78d23          	sb	a4,26(a5)
    8000613e:	00e78da3          	sb	a4,27(a5)
    80006142:	00e78e23          	sb	a4,28(a5)
    80006146:	00e78ea3          	sb	a4,29(a5)
    8000614a:	00e78f23          	sb	a4,30(a5)
    8000614e:	00e78fa3          	sb	a4,31(a5)
}
    80006152:	60e2                	ld	ra,24(sp)
    80006154:	6442                	ld	s0,16(sp)
    80006156:	64a2                	ld	s1,8(sp)
    80006158:	6105                	addi	sp,sp,32
    8000615a:	8082                	ret
    panic("could not find virtio disk");
    8000615c:	00002517          	auipc	a0,0x2
    80006160:	65450513          	addi	a0,a0,1620 # 800087b0 <syscalls+0x380>
    80006164:	ffffa097          	auipc	ra,0xffffa
    80006168:	472080e7          	jalr	1138(ra) # 800005d6 <panic>
    panic("virtio disk has no queue 0");
    8000616c:	00002517          	auipc	a0,0x2
    80006170:	66450513          	addi	a0,a0,1636 # 800087d0 <syscalls+0x3a0>
    80006174:	ffffa097          	auipc	ra,0xffffa
    80006178:	462080e7          	jalr	1122(ra) # 800005d6 <panic>
    panic("virtio disk max queue too short");
    8000617c:	00002517          	auipc	a0,0x2
    80006180:	67450513          	addi	a0,a0,1652 # 800087f0 <syscalls+0x3c0>
    80006184:	ffffa097          	auipc	ra,0xffffa
    80006188:	452080e7          	jalr	1106(ra) # 800005d6 <panic>

000000008000618c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000618c:	7119                	addi	sp,sp,-128
    8000618e:	fc86                	sd	ra,120(sp)
    80006190:	f8a2                	sd	s0,112(sp)
    80006192:	f4a6                	sd	s1,104(sp)
    80006194:	f0ca                	sd	s2,96(sp)
    80006196:	ecce                	sd	s3,88(sp)
    80006198:	e8d2                	sd	s4,80(sp)
    8000619a:	e4d6                	sd	s5,72(sp)
    8000619c:	e0da                	sd	s6,64(sp)
    8000619e:	fc5e                	sd	s7,56(sp)
    800061a0:	f862                	sd	s8,48(sp)
    800061a2:	f466                	sd	s9,40(sp)
    800061a4:	f06a                	sd	s10,32(sp)
    800061a6:	0100                	addi	s0,sp,128
    800061a8:	892a                	mv	s2,a0
    800061aa:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061ac:	00c52c83          	lw	s9,12(a0)
    800061b0:	001c9c9b          	slliw	s9,s9,0x1
    800061b4:	1c82                	slli	s9,s9,0x20
    800061b6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061ba:	00024517          	auipc	a0,0x24
    800061be:	eee50513          	addi	a0,a0,-274 # 8002a0a8 <disk+0x20a8>
    800061c2:	ffffb097          	auipc	ra,0xffffb
    800061c6:	ab2080e7          	jalr	-1358(ra) # 80000c74 <acquire>
  for(int i = 0; i < 3; i++){
    800061ca:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061cc:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061ce:	00022b97          	auipc	s7,0x22
    800061d2:	e32b8b93          	addi	s7,s7,-462 # 80028000 <disk>
    800061d6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800061d8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061da:	8a4e                	mv	s4,s3
    800061dc:	a051                	j	80006260 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800061de:	00fb86b3          	add	a3,s7,a5
    800061e2:	96da                	add	a3,a3,s6
    800061e4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061e8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061ea:	0207c563          	bltz	a5,80006214 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061ee:	2485                	addiw	s1,s1,1
    800061f0:	0711                	addi	a4,a4,4
    800061f2:	23548d63          	beq	s1,s5,8000642c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    800061f6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061f8:	00024697          	auipc	a3,0x24
    800061fc:	e2068693          	addi	a3,a3,-480 # 8002a018 <disk+0x2018>
    80006200:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006202:	0006c583          	lbu	a1,0(a3)
    80006206:	fde1                	bnez	a1,800061de <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006208:	2785                	addiw	a5,a5,1
    8000620a:	0685                	addi	a3,a3,1
    8000620c:	ff879be3          	bne	a5,s8,80006202 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006210:	57fd                	li	a5,-1
    80006212:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006214:	02905a63          	blez	s1,80006248 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006218:	f9042503          	lw	a0,-112(s0)
    8000621c:	00000097          	auipc	ra,0x0
    80006220:	daa080e7          	jalr	-598(ra) # 80005fc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006224:	4785                	li	a5,1
    80006226:	0297d163          	bge	a5,s1,80006248 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000622a:	f9442503          	lw	a0,-108(s0)
    8000622e:	00000097          	auipc	ra,0x0
    80006232:	d98080e7          	jalr	-616(ra) # 80005fc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006236:	4789                	li	a5,2
    80006238:	0097d863          	bge	a5,s1,80006248 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000623c:	f9842503          	lw	a0,-104(s0)
    80006240:	00000097          	auipc	ra,0x0
    80006244:	d86080e7          	jalr	-634(ra) # 80005fc6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006248:	00024597          	auipc	a1,0x24
    8000624c:	e6058593          	addi	a1,a1,-416 # 8002a0a8 <disk+0x20a8>
    80006250:	00024517          	auipc	a0,0x24
    80006254:	dc850513          	addi	a0,a0,-568 # 8002a018 <disk+0x2018>
    80006258:	ffffc097          	auipc	ra,0xffffc
    8000625c:	008080e7          	jalr	8(ra) # 80002260 <sleep>
  for(int i = 0; i < 3; i++){
    80006260:	f9040713          	addi	a4,s0,-112
    80006264:	84ce                	mv	s1,s3
    80006266:	bf41                	j	800061f6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006268:	4785                	li	a5,1
    8000626a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000626e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006272:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006276:	f9042983          	lw	s3,-112(s0)
    8000627a:	00499493          	slli	s1,s3,0x4
    8000627e:	00024a17          	auipc	s4,0x24
    80006282:	d82a0a13          	addi	s4,s4,-638 # 8002a000 <disk+0x2000>
    80006286:	000a3a83          	ld	s5,0(s4)
    8000628a:	9aa6                	add	s5,s5,s1
    8000628c:	f8040513          	addi	a0,s0,-128
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	eb4080e7          	jalr	-332(ra) # 80001144 <kvmpa>
    80006298:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000629c:	000a3783          	ld	a5,0(s4)
    800062a0:	97a6                	add	a5,a5,s1
    800062a2:	4741                	li	a4,16
    800062a4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062a6:	000a3783          	ld	a5,0(s4)
    800062aa:	97a6                	add	a5,a5,s1
    800062ac:	4705                	li	a4,1
    800062ae:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800062b2:	f9442703          	lw	a4,-108(s0)
    800062b6:	000a3783          	ld	a5,0(s4)
    800062ba:	97a6                	add	a5,a5,s1
    800062bc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062c0:	0712                	slli	a4,a4,0x4
    800062c2:	000a3783          	ld	a5,0(s4)
    800062c6:	97ba                	add	a5,a5,a4
    800062c8:	05890693          	addi	a3,s2,88
    800062cc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800062ce:	000a3783          	ld	a5,0(s4)
    800062d2:	97ba                	add	a5,a5,a4
    800062d4:	40000693          	li	a3,1024
    800062d8:	c794                	sw	a3,8(a5)
  if(write)
    800062da:	100d0a63          	beqz	s10,800063ee <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062de:	00024797          	auipc	a5,0x24
    800062e2:	d227b783          	ld	a5,-734(a5) # 8002a000 <disk+0x2000>
    800062e6:	97ba                	add	a5,a5,a4
    800062e8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062ec:	00022517          	auipc	a0,0x22
    800062f0:	d1450513          	addi	a0,a0,-748 # 80028000 <disk>
    800062f4:	00024797          	auipc	a5,0x24
    800062f8:	d0c78793          	addi	a5,a5,-756 # 8002a000 <disk+0x2000>
    800062fc:	6394                	ld	a3,0(a5)
    800062fe:	96ba                	add	a3,a3,a4
    80006300:	00c6d603          	lhu	a2,12(a3)
    80006304:	00166613          	ori	a2,a2,1
    80006308:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000630c:	f9842683          	lw	a3,-104(s0)
    80006310:	6390                	ld	a2,0(a5)
    80006312:	9732                	add	a4,a4,a2
    80006314:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006318:	20098613          	addi	a2,s3,512
    8000631c:	0612                	slli	a2,a2,0x4
    8000631e:	962a                	add	a2,a2,a0
    80006320:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006324:	00469713          	slli	a4,a3,0x4
    80006328:	6394                	ld	a3,0(a5)
    8000632a:	96ba                	add	a3,a3,a4
    8000632c:	6589                	lui	a1,0x2
    8000632e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006332:	94ae                	add	s1,s1,a1
    80006334:	94aa                	add	s1,s1,a0
    80006336:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006338:	6394                	ld	a3,0(a5)
    8000633a:	96ba                	add	a3,a3,a4
    8000633c:	4585                	li	a1,1
    8000633e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006340:	6394                	ld	a3,0(a5)
    80006342:	96ba                	add	a3,a3,a4
    80006344:	4509                	li	a0,2
    80006346:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000634a:	6394                	ld	a3,0(a5)
    8000634c:	9736                	add	a4,a4,a3
    8000634e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006352:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006356:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000635a:	6794                	ld	a3,8(a5)
    8000635c:	0026d703          	lhu	a4,2(a3)
    80006360:	8b1d                	andi	a4,a4,7
    80006362:	2709                	addiw	a4,a4,2
    80006364:	0706                	slli	a4,a4,0x1
    80006366:	9736                	add	a4,a4,a3
    80006368:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000636c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006370:	6798                	ld	a4,8(a5)
    80006372:	00275783          	lhu	a5,2(a4)
    80006376:	2785                	addiw	a5,a5,1
    80006378:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000637c:	100017b7          	lui	a5,0x10001
    80006380:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006384:	00492703          	lw	a4,4(s2)
    80006388:	4785                	li	a5,1
    8000638a:	02f71163          	bne	a4,a5,800063ac <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000638e:	00024997          	auipc	s3,0x24
    80006392:	d1a98993          	addi	s3,s3,-742 # 8002a0a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006396:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006398:	85ce                	mv	a1,s3
    8000639a:	854a                	mv	a0,s2
    8000639c:	ffffc097          	auipc	ra,0xffffc
    800063a0:	ec4080e7          	jalr	-316(ra) # 80002260 <sleep>
  while(b->disk == 1) {
    800063a4:	00492783          	lw	a5,4(s2)
    800063a8:	fe9788e3          	beq	a5,s1,80006398 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800063ac:	f9042483          	lw	s1,-112(s0)
    800063b0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800063b4:	00479713          	slli	a4,a5,0x4
    800063b8:	00022797          	auipc	a5,0x22
    800063bc:	c4878793          	addi	a5,a5,-952 # 80028000 <disk>
    800063c0:	97ba                	add	a5,a5,a4
    800063c2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063c6:	00024917          	auipc	s2,0x24
    800063ca:	c3a90913          	addi	s2,s2,-966 # 8002a000 <disk+0x2000>
    free_desc(i);
    800063ce:	8526                	mv	a0,s1
    800063d0:	00000097          	auipc	ra,0x0
    800063d4:	bf6080e7          	jalr	-1034(ra) # 80005fc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063d8:	0492                	slli	s1,s1,0x4
    800063da:	00093783          	ld	a5,0(s2)
    800063de:	94be                	add	s1,s1,a5
    800063e0:	00c4d783          	lhu	a5,12(s1)
    800063e4:	8b85                	andi	a5,a5,1
    800063e6:	cf89                	beqz	a5,80006400 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800063e8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800063ec:	b7cd                	j	800063ce <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063ee:	00024797          	auipc	a5,0x24
    800063f2:	c127b783          	ld	a5,-1006(a5) # 8002a000 <disk+0x2000>
    800063f6:	97ba                	add	a5,a5,a4
    800063f8:	4689                	li	a3,2
    800063fa:	00d79623          	sh	a3,12(a5)
    800063fe:	b5fd                	j	800062ec <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006400:	00024517          	auipc	a0,0x24
    80006404:	ca850513          	addi	a0,a0,-856 # 8002a0a8 <disk+0x20a8>
    80006408:	ffffb097          	auipc	ra,0xffffb
    8000640c:	920080e7          	jalr	-1760(ra) # 80000d28 <release>
}
    80006410:	70e6                	ld	ra,120(sp)
    80006412:	7446                	ld	s0,112(sp)
    80006414:	74a6                	ld	s1,104(sp)
    80006416:	7906                	ld	s2,96(sp)
    80006418:	69e6                	ld	s3,88(sp)
    8000641a:	6a46                	ld	s4,80(sp)
    8000641c:	6aa6                	ld	s5,72(sp)
    8000641e:	6b06                	ld	s6,64(sp)
    80006420:	7be2                	ld	s7,56(sp)
    80006422:	7c42                	ld	s8,48(sp)
    80006424:	7ca2                	ld	s9,40(sp)
    80006426:	7d02                	ld	s10,32(sp)
    80006428:	6109                	addi	sp,sp,128
    8000642a:	8082                	ret
  if(write)
    8000642c:	e20d1ee3          	bnez	s10,80006268 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006430:	f8042023          	sw	zero,-128(s0)
    80006434:	bd2d                	j	8000626e <virtio_disk_rw+0xe2>

0000000080006436 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006436:	1101                	addi	sp,sp,-32
    80006438:	ec06                	sd	ra,24(sp)
    8000643a:	e822                	sd	s0,16(sp)
    8000643c:	e426                	sd	s1,8(sp)
    8000643e:	e04a                	sd	s2,0(sp)
    80006440:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006442:	00024517          	auipc	a0,0x24
    80006446:	c6650513          	addi	a0,a0,-922 # 8002a0a8 <disk+0x20a8>
    8000644a:	ffffb097          	auipc	ra,0xffffb
    8000644e:	82a080e7          	jalr	-2006(ra) # 80000c74 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006452:	00024717          	auipc	a4,0x24
    80006456:	bae70713          	addi	a4,a4,-1106 # 8002a000 <disk+0x2000>
    8000645a:	02075783          	lhu	a5,32(a4)
    8000645e:	6b18                	ld	a4,16(a4)
    80006460:	00275683          	lhu	a3,2(a4)
    80006464:	8ebd                	xor	a3,a3,a5
    80006466:	8a9d                	andi	a3,a3,7
    80006468:	cab9                	beqz	a3,800064be <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000646a:	00022917          	auipc	s2,0x22
    8000646e:	b9690913          	addi	s2,s2,-1130 # 80028000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006472:	00024497          	auipc	s1,0x24
    80006476:	b8e48493          	addi	s1,s1,-1138 # 8002a000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000647a:	078e                	slli	a5,a5,0x3
    8000647c:	97ba                	add	a5,a5,a4
    8000647e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006480:	20078713          	addi	a4,a5,512
    80006484:	0712                	slli	a4,a4,0x4
    80006486:	974a                	add	a4,a4,s2
    80006488:	03074703          	lbu	a4,48(a4)
    8000648c:	ef21                	bnez	a4,800064e4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000648e:	20078793          	addi	a5,a5,512
    80006492:	0792                	slli	a5,a5,0x4
    80006494:	97ca                	add	a5,a5,s2
    80006496:	7798                	ld	a4,40(a5)
    80006498:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000649c:	7788                	ld	a0,40(a5)
    8000649e:	ffffc097          	auipc	ra,0xffffc
    800064a2:	f48080e7          	jalr	-184(ra) # 800023e6 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800064a6:	0204d783          	lhu	a5,32(s1)
    800064aa:	2785                	addiw	a5,a5,1
    800064ac:	8b9d                	andi	a5,a5,7
    800064ae:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800064b2:	6898                	ld	a4,16(s1)
    800064b4:	00275683          	lhu	a3,2(a4)
    800064b8:	8a9d                	andi	a3,a3,7
    800064ba:	fcf690e3          	bne	a3,a5,8000647a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064be:	10001737          	lui	a4,0x10001
    800064c2:	533c                	lw	a5,96(a4)
    800064c4:	8b8d                	andi	a5,a5,3
    800064c6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800064c8:	00024517          	auipc	a0,0x24
    800064cc:	be050513          	addi	a0,a0,-1056 # 8002a0a8 <disk+0x20a8>
    800064d0:	ffffb097          	auipc	ra,0xffffb
    800064d4:	858080e7          	jalr	-1960(ra) # 80000d28 <release>
}
    800064d8:	60e2                	ld	ra,24(sp)
    800064da:	6442                	ld	s0,16(sp)
    800064dc:	64a2                	ld	s1,8(sp)
    800064de:	6902                	ld	s2,0(sp)
    800064e0:	6105                	addi	sp,sp,32
    800064e2:	8082                	ret
      panic("virtio_disk_intr status");
    800064e4:	00002517          	auipc	a0,0x2
    800064e8:	32c50513          	addi	a0,a0,812 # 80008810 <syscalls+0x3e0>
    800064ec:	ffffa097          	auipc	ra,0xffffa
    800064f0:	0ea080e7          	jalr	234(ra) # 800005d6 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
