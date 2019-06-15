// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"
#include "funcdata.h"

//
// System call support for Plan 9 (actually, harvey)
//
// Trap # in AX, args in DI SI DX R10 R8 R9, return in AX DX
// Note that this differs from "standard" ABI convention, which
// would pass 4th arg in CX, not R10.

//func Syscall(trap, a1, a2, a3 uintptr) (r1, r2 uintptr, err string)
//func Syscall6(trap, a1, a2, a3, a4, a5, a6 uintptr) (r1, r2 uintptr, err string)
//func RawSyscall(trap, a1, a2, a3 uintptr) (r1, r2, err uintptr)
//func RawSyscall6(trap, a1, a2, a3, a4, a5, a6 uintptr) (r1, r2, err uintptr)

#define SYS_ERRSTR 41	/* from zsysnum_plan9.go */

TEXT	·Syscall(SB),NOSPLIT,$0-56
	NO_LOCAL_POINTERS
	CALL	runtime·entersyscall(SB)
	MOVQ	a1+8(FP), DI
	MOVQ	a2+16(FP), SI
	MOVQ	a3+24(FP), DX
	MOVQ	$0, R10
	MOVQ	$0, R8
	MOVQ	$0, R9
	MOVQ	trap+0(FP), AX	// syscall entry
	SYSCALL
	MOVQ	AX, r1+32(FP)
	MOVQ	$0, r2+40(FP)
	CMPL	AX, $-1
	JNE	ok3

	LEAQ	errbuf-128(SP), AX
	MOVQ	AX, sysargs-160(SP)
	MOVQ	$128, sysargs1-152(SP)
	MOVQ	$SYS_ERRSTR, BP
	SYSCALL
	CALL	runtime·exitsyscall(SB)
	MOVQ	sysargs-160(SP), AX
	MOVQ	AX, errbuf-168(SP)
	CALL	runtime·gostring(SB)
	LEAQ	str-160(SP), SI
	JMP	copyresult3

ok3:
	CALL	runtime·exitsyscall(SB)
	LEAQ	·emptystring(SB), SI

copyresult3:
	LEAQ	err+48(FP), DI

	CLD
	MOVSQ
	MOVSQ

	RET

// func Syscall6(trap, a1, a2, a3, a4, a5, a6 uintptr) (r1, r2, err uintptr)
TEXT	·Syscall6(SB),NOSPLIT,$168-80
	NO_LOCAL_POINTERS
	CALL	runtime·entersyscall(SB)
	MOVQ	a1+8(FP), DI
	MOVQ	a2+16(FP), SI
	MOVQ	a3+24(FP), DX
	MOVQ	a4+32(FP), R10
	MOVQ	a5+40(FP), R8
	MOVQ	a6+48(FP), R9
	MOVQ	trap+0(FP), AX	// syscall entry
	SYSCALL
	MOVQ	AX, r1+56(FP)
	MOVQ	$0, r2+64(FP)
	CMPL	AX, $-1
	JNE	ok4

	LEAQ	errbuf-128(SP), AX
	MOVQ	AX, sysargs-160(SP)
	MOVQ	$128, sysargs1-152(SP)
	MOVQ	$SYS_ERRSTR, BP
	SYSCALL
	CALL	runtime·exitsyscall(SB)
	MOVQ	sysargs-160(SP), AX
	MOVQ	AX, errbuf-168(SP)
	CALL	runtime·gostring(SB)
	LEAQ	str-160(SP), SI
	JMP	copyresult4

ok4:
	CALL	runtime·exitsyscall(SB)
	LEAQ	·emptystring(SB), SI

copyresult4:
	LEAQ	err+72(FP), DI

	CLD
	MOVSQ
	MOVSQ

	RET

// func RawSyscall(trap, a1, a2, a3 uintptr) (r1, r2, err uintptr)
TEXT ·RawSyscall(SB),NOSPLIT,$0-56
	MOVQ	a1+8(FP), DI
	MOVQ	a2+16(FP), SI
	MOVQ	a3+24(FP), DX
	MOVQ	$0, R10
	MOVQ	$0, R8
	MOVQ	$0, R9
	MOVQ	trap+0(FP), AX	// syscall entry
	SYSCALL
	MOVQ	AX, r1+30(SP)
	MOVQ	AX, r2+48(SP)
	MOVQ	AX, err+56(SP)
	RET

// func RawSyscall6(trap, a1, a2, a3, a4, a5, a6 uintptr) (r1, r2, err uintptr)
TEXT	·RawSyscall6(SB),NOSPLIT,$0-80
	MOVQ	a1+8(FP), DI
	MOVQ	a2+16(FP), SI
	MOVQ	a3+24(FP), DX
	MOVQ	a4+32(FP), R10
	MOVQ	a5+40(FP), R8
	MOVQ	a6+48(FP), R9
	MOVQ	trap+0(FP), AX	// syscall entry
	SYSCALL
	MOVQ	AX, r1+56(FP)
	MOVQ	DX, r2+64(FP)
	MOVQ	$0, err+72(FP)
	RET

#define SYS_SEEK 39	/* from zsysnum_plan9.go */

//func seek(placeholder uintptr, fd int, offset int64, whence int) (newoffset int64, err string)
TEXT ·seek(SB),NOSPLIT,$48-56
	NO_LOCAL_POINTERS
	LEAQ	newoffset+32(FP), AX
	MOVQ	AX, placeholder+0(FP)

	// copy args down
	LEAQ	placeholder+0(FP), SI
	LEAQ	sysargs-40(SP), DI
	CLD
	MOVSQ
	MOVSQ
	MOVSQ
	MOVSQ
	MOVSQ
	MOVQ	$SYS_SEEK, BP	// syscall entry
	SYSCALL

	CMPL	AX, $-1
	JNE	ok6
	MOVQ	AX, newoffset+32(FP)

	CALL	syscall·errstr(SB)
	MOVQ	SP, SI
	JMP	copyresult6

ok6:
	LEAQ	·emptystring(SB), SI

copyresult6:
	LEAQ	err+40(FP), DI

	CLD
	MOVSQ
	MOVSQ
	RET
