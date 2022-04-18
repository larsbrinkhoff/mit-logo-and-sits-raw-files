insert[d0lang];
NOMIDASINIT;LANGVERSION;MULTDIB;
insert[GlobalDefs];
	TITLE[BITBLT];
%
Last modified by Johnsson, May 9, 1979  2:28 PM
*	BBTable format
*
* WORD	  NAME		
*    0	FUNCTION	bit 0 Long Bitblt; bits 14-17 function (see below) 
*    1	unused
*    2	DBCA	Destination BCA   Base Core Address of dest bit map
*    3	DBMR	Destination BMR   Bit Map Width in words
*    4	DLX	Destination LX    Left X offset from first bit
*    5	DTY	Destination TY    Top Y offset from first scan line
*    6	DW	Destination W     Width in bits of bit map
*    7	DH	Destination H     Height in scan lines of bit map
*   10	SBCA	Source BCA
*   11	SBMR	Source BMR
*   12	SLX	Source LX
*   13	STY	Source TY
*   14	Gray0	            These four words are the Gray Block
*   15	Gray1		Gray0 is used on the first item,
*   16	Gray2		Gray1 on the second, Gray2 on the third,
*   17	Gray3		Gray3 on the fourth, Gray0 on the fifth,etc.
*   20	LongSourceLo
*   21	LongSourceHi
*   22	LongDestLo
*   23	LongDestHi


*	Bit BLT functions

* 	CODE	MA, MB	SALUFOP		Dest _

*	  0	0   0	R OR T		Src
*	  1	0   1	R OR T		Src OR Dest
*	  2	0   1	R XOR T		Src XOR Dest
*	  3	0   1	R AND notT	notSrc AND Dest
*	  4	1   0	R OR notT	notSrc
*	  5	1   1	R OR notT	notSrc OR Dest
*	  6	1   1	R XNOR T	notSrc XOR Dest
*	  7	1   1	R AND T		Src AND Dest
*	 10	0   0	xxx		(Src AND Gry) OR (notSrc AND Dest)
*	 11	1   0	R OR T		(Src AND Gry) OR Dest
*	 12	1   0	R XOR T		(Src AND Gry) XOR Dest
*	 13	1   0	R AND notT	not(Src AND Gry) AND Dest
*	 14	0   0	R OR T		Gry
*	 15	1   0	R OR T		Gry OR Dest
*	 16	1   0	R XOR T		Gry XOR Dest
*	 17	1   0	R AND notT	notGry AND Dest
	
	interpretation of bbFunction bits

	   00	mesa long pointer
	   01	mesa called = 1 / nova called = 0
	02-05	unused
	   06	bot to top = 1 / top to bot =0
	   07	r to l = 1 / l to r = 0
	10-12	which-innerloop index
	   13	zero
	14-17	Bitblt function code
%

*dispatch tables for bitblt
	SET[BBP1P,LSHIFT[BBP1,10]];
	SET[BBP2P,LSHIFT[BBP2,10]];
	SET[BBILA,  ADD[BBP1P,100]];
	SET[BBILB,  ADD[BBP1P,120]];
	SET[BBILC,  ADD[BBP1P,140]];
	SET[BBILD,  ADD[BBP1P,160]];
	SET[BBILE,  ADD[BBP1P,200]];
	SET[BBILDX, ADD[BBP1P,220]];
	SET[bbIdisp,ADD[BBP1P,240]];
	SET[BBF,    ADD[BBP2P,340]];

*	BBFA dispatch values

	set[BBNRM,7];	*no refill
	set[BBDST,6];	*destination refill
	set[BBSRC,5];	*source refill
	set[BBBTH,4];	*source and destination refill
	set[BBITM,3];	*item refill

	set[bbILtype0,    00];
	set[bbILtype1,    02];
	set[bbILtype2,    04];
	set[bbILtype3,    06];
	set[bbILtype4,    10];
(1795)

%	Initialization
*	*	determination of bit blt directions
*	(top to bottom , left to right)	dty < sty
*	(top to bottom , right to left)	(dty = sty) and (dlx > slx)
*	(bottom to top , left to right)	((dty = sty) and (dlx =< slx))
*						or (dty > sty)
%

	ONPAGE[BBP2] ;

bbp2ret:	return;

NovaBitBLT: 	*AC2,AC3 are a base register pointing to the BitBLT table
	AC0 _ 21c, task;		*Stkp points to ICOM in AC1
	Stkp _ AC0;
	AC0 _ 0c, goto[bbBitBLT]; *AC0 is the "entered from Nova" flag

MesaBitBLT: lu _ xfWDC; *T has address of table
	skip[ALU=0];
	NWW _ (NWW) or (100000c); *disable interrupts in xfWDC#0
	AC2 _ T;
	T _ MDShi, task;
	AC3 _ T;	*Long pointer to BitBLT table in AC2,AC3
	AC0 _ 40000C, goto[bbBitBLT];

*get here when finished, with test of "entered from Mesa" flag pending
bbExit:	dblgoto[bbMdone,bbNdone,ALU#0];

bbMdone:	loadpage[4];
	stack&-2, gotop[MesaBBret];

bbNdone:	loadpage[nePage];
	gotop[neNoskip], FF1@[17];

*common bitblt code
bbBITBLT:
	pfetch1[AC2,bbFunction,0], call[bbp2ret];*fetch function
	pfetch2[AC2,bbRTEMslx,12],task;*fetch slx and sty 
	bbSrcQAddrLo _ zero ;
	pfetch2[AC2,bbRTEMdlx,4];*fetch dlx and dty
	t_(17c), task;
	t_(lsh[AC0,1])or(t);
	pfetch2[AC2,bbItemWidth,6], call[bbp2ret];*fetch dw and dh
	bbFunction_(bbFunction)and(t);*Insure no garbage and mask bit 0 if entered from Nova
	t_(AC0);
	task,bbFunction_(bbFunction)or(t); *"called from Mesa" bit
	t _ ldf[bbFunction,14,2] ;
	lu _ bbItemWidth;
	RTEMP_ T ,skip[alu#0];
	lu _ ldf[bbFunction,1,1], goto[bbExit];	*Completion return - item width is zero
	RTEMP_t;
	lu _ (RTEMP) xor (3c) ;
	skip[alu#0] ;
	goto[bbTB] , bbSrcQAddrLo _ (1c) ;	*if function is 14-17, source not used,use tblr
	T _ bbRTEMdty;
	LU _ (bbRTEMsty) - (T) ;			*calc sty - dty
	GOTO[bbBT1,alu<0],freezeresult;
bbA3:	GOTO[bbTB,ALU#0] ;
bbA4:	T _ bbRTEMdlx ;
	LU _ (bbRTEMslx) - (T) ;			*calc slx - dlx
	DBLGOTO[bbTBRL,bbTBLR,ALU<0] ,t _ Stack;
bbBT1:	GOTO[bbBTLR] ,t _ Stack;	*bottom to top , left to right
bbTB:	GOTO[bbTBLR] ,t _ Stack;	*top to bottom , left to right

*		for left to right , top to bottom
*		specific initialization
*	sty		sty + icom
bbTBLR:
	bbRTEMsty _ (bbRTEMsty) + (T);
	GOTOp[bbGenlInit],bbRTEMdty _ (bbRTEMdty) + (T) ;
*
*		for left to right , bottom to top
*		specific initialization
bbBTLR:
	task,T _ (bbItemsRemaining) - (T) - 1 ;
	bbRTEMsty _ (bbRTEMsty) + (T) ;
	bbRTEMdty _ (bbRTEMdty) + (T);
	GOTOp[bbGenlInit],bbFunction_(bbFunction)or(1000C);*set L to R bit
*
*		for right to left , top to bottom
*		specific initialization
bbTBRL:
	bbRTEMsty _ (bbRTEMsty) + (T) ;
	task,bbRTEMdty _ (bbRTEMdty) + (T) ;
	t _ bbRTEMslx ;
	t _ (bbRTEMdlx) - (t);
	bbSDNonOverlap _ t ;
	lu _ ldf[bbSDNonOverlap,0,12] ;
	skip[alu#0],bbMinusSDNonOverlap_(zero)-(t);
	goto[bbGenlInit];*L to R if non-overlap < 100b
	lu _ ldf[bbItemWidth,0,12] ;
	skip[alu#0] ;
	goto[bbGenlInit];*L to R if item length < 100b
	lu _ (bbItemWidth) - (t) ;
	skip[carry];
	goto[bbGenlInit];*L to R if item width < non-overlap
	GOTO[bbGenlInit] , bbFunction_(bbFunction)or(400C) ;*R to L

*		general initialization
*		calc ss
*	ss		(lsh[4](sbca + (sty * sbmr)) + slx)  24 bits

bbGenlInit:
	skip[r even] , lu _ bbSrcQAddrLo ;
	goto[bbinnosrc], pfetch2[AC2,bbDBCA,2];
	pfetch2[AC2,bbSBCA,10] ;*fetch sbca and sbmr
	goto[bbLongSrcGet,r<0],lu_bbFunction;
bbShortSrcGet:
	 t_bbSBCA;
	 call[bbp2ret],bbSrcQAddrLo_t;
	 goto[bbSrcInit],bbSrcQAddrHi_(zero);*short form set-up
bbLongSrcGet:
	 t_20c;
	 call[bbp2ret],pfetch2[AC2,bbSrcQAddrLo];*long form set-up

*T _ sty * sbmr.  The product is =< 16 bits
bbSrcInit:
	T _ bbSBMR;
	RTEMP _ T;
	T _ 0c, call[bbSrcMul];
bbSrcMul:	RTEMP _ rsh[RTEMP,1], goto[.+2,Reven];
	T _ (bbRTEMsty) + (T);
	bbRTEMsty _ lsh[bbRTEMsty, 1], goto[.+2, ALU=0];
	return;
bbSrcMulDone:	
	bbSrcQAddrLo_(bbSrcQAddrLo)+(t);
	skip[nocarry], t_lsh[bbSrcQAddrLo,4];*move SrcQAddr to SrcStartBit
	bbSrcQAddrHi_(bbSrcQAddrHi)+1;
	bbSrcStartBitLo_t;
	t_rsh[bbSrcQAddrLo,14];	
	task,t_(lsh[bbSrcQAddrHi,4])+(t);
	bbSrcStartBitHi_t;
	t_bbRTEMslx;*add slx to SrcStartBit
	bbSrcStartBitLo_(bbSrcStartBitLo)+(t);
	skip[nocarry], bbSrcQAddrLo_(bbSrcQAddrLo)and not(3c);
	bbSrcStartBitHi_(bbSrcStartBitHi)+1;* SrcStartBit now complete
*		calc ds
*	ds		(lsh[4](dbca + (dty * dbmr)) + dlx)  24 bits
	pfetch2[AC2,bbDBCA,2];*fetch dbca and dbmr
bbinnosrc:
	goto[bbShortDestGet,r>=0],lu_bbFunction;
bbLongDestGet:
	t_22c;
	goto[bbDestInit],pfetch2[AC2,bbDestQAddrLo];
bbShortDestGet:
	t_bbDBCA;
	task,bbDestQAddrLo_t;
	bbDestQAddrHi_(zero);*short form set-up
*T _ dty * dbmr.  16-bit product
bbDestInit:
	T _ bbDBMR;
	RTEMP _ T;
	T _ 0c, call[bbDestMul];
bbDestMul:	RTEMP _ rsh[RTEMP,1], goto[.+2, Reven];
	T _ (bbRTEMdty) + (T);
	bbRTEMdty _ lsh[bbRTEMdty, 1], goto[.+2, ALU=0];
	return;

bbDestMulDone:
	bbDestQAddrLo_(bbDestQAddrLo)+(t);
	skip[nocarry],t_lsh[bbDestQAddrLo,4];*move DestQAddr to DestStartBit
	bbDestQAddrHi_(bbDestQAddrHi)+1;
	bbDestStartBitLo_t;
	goto[.+1],t_rsh[bbDestQAddrLo,14];	
	t_(lsh[bbDestQAddrHi,4])+(t);
	task,bbDestStartBitHi_t;
	t_bbRTEMdlx;*add dlx to DestStartBit
	bbDestStartBitLo_(bbDestStartBitLo)+(t);
	skip[nocarry],t _ bbItemWidth;
	bbDestStartBitHi_(bbDestStartBitHi)+1;* DestStartBit now complete
	bbMinusItemWidth _ (zero) - (T) ;	*want minus item width
*	test for specific initialization (bottom to top)
	lu_ldf[bbFunction,6,1] ;
	goto[bbILX0,alu=0] ;
*			this will go to bbilx0 if t to b
*			or bbilx1 if b to t

bbILX1:	t _ bbSBMR ;
	task,bbSBMR _ (zero) - (t) ;
	t _ bbDBMR ;
	bbDBMR _ (zero) - (t) ;

bbILX0:	
	T _ (Stack);
	bbItemsRemainingMinus1 _ (bbItemsRemaining) - (T) - 1 ;
	skip[alu>=0] , bbItemsRemainingMinus2 _ (bbItemsRemainingMinus1) - 1 ;
	lu _ ldf[bbFunction,1,1], goto[bbExit];	*Completion return - no items remaining
	bbGrayCnt _ T ;
	skip[r even] , lu _ bbSrcQAddrLo;
	goto[.+2] , SB _ bbDestStartBitLo ;
	SB _ bbSrcStartBitLo ;
	task,DB _ bbDestStartBitLo ;
	MNBR _ bbMinusItemWidth;

bbfd:	DISPATCH[bbFunction,14,4] ;
	DISP[bbFUN00] ;
*		will dispatch to bbfunN for function N

bbFUN00:	goto[bbEndInit] , T _ (204C) , AT[BBF,0] ;*salufop _ [0,0,r or t]
bbFUN01:	goto[bbEndInit] , T _ (304C) , AT[BBF,1] ;*salufop _ [1,0,r or t]
bbFUN02:	goto[bbEndInit] , T _ (363C) , AT[BBF,2] ;*salufop _ [1,0,r xor t]
bbFUN03:	goto[bbEndInit] , T _ (327C) , AT[BBF,3] ;*salufop _ [1,0,r and not t]
bbFUN04:	goto[bbEndInit] , T _ (074C) , AT[BBF,4] ;*salufop _ [0,1,r or not t]
bbFUN05:	goto[bbEndInit] , T _ (104C) , AT[BBF,5] ;*salufop _ [1,1,r or t]
bbFUN06:	goto[bbEndInit] , T _ (154C) , AT[BBF,6] ;*salufop _ [1,1,r xnor t]
bbFUN07:	goto[bbEndInit] , T _ (156C) , AT[BBF,7] ;*salufop _ [1,1,r and t]
bbFUN10:	T _ (200C) , AT[BBF,10] ;		*salufop _ [x,0,x]
	goto[bbEndInit] , bbFunction _ (bbFunction) OR (40C) ;	*type 1 transfer
bbFUN11:	T _ (304C) , AT[BBF,11] ;		*salufop _ [1,0,r or t]
	GOTO[bbEndInit] , bbFunction _ (bbFunction) OR (100C) ;	*type 2 transfer
bbFUN12:	T _ (363C) , AT[BBF,12] ;		*salufop _ [1,0,r xor t]
	GOTO[bbEndInit] , bbFunction _ (bbFunction) OR (100C) ;	*type 2 transfer
bbFUN13:	T _ (327C) , AT[BBF,13] ;		*salufop _ [1,0,r and not t]
	GOTO[bbEndInit] , bbFunction _ (bbFunction) OR (100C) ;	*type 2 transfer
bbFUN14:	T _ (204C) , AT[BBF,14] ;		*salufop _ [0,0,r or t]
	GOTO[bbEndInit] , bbFunction _ (bbFunction) OR (200C) ;	*type 4 transfer
bbFUN15:	T _ (304C) , AT[BBF,15] ;		*salufop _ [1,0,r or t]
	GOTO[bbEndInit] , bbFunction _ (bbFunction) OR (140C) ;	*type 3 transfer
bbFUN16:	T _ (363C) , AT[BBF,16] ;		*salufop _ [1,0,r xor t]
	GOTO[bbEndInit] , bbFunction _ (bbFunction) OR (140C) ;	*type 3 transfer
bbFUN17:	T _ (327C) , AT[BBF,17] ;		*salufop _ [1,0,r and not t]
	GOTO[bbEndInit] , bbFunction _ (bbFunction) OR (140C) ;	*type 3 transfer

bbEndInit:
	LOADPAGE[BBP1] ;
	GOTOP[bbFirstItem],saluf _ t;


	ONPAGE[BBP1] ;
*	Inner loops
*		functions 0-7
*	
bbInnerLoops:
bbILA1Z:
	call[.+1] , AT[BBIDISP,bbILtype0] ;
	DBLGOTO[bbILA2,bbILAX,MB] ,
	T _ (BBFA[SB[bbSOURCE]]) or (t) ;
bbILA2:	DISP[bbILA1] , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) ;
bbILAX:	DISP[bbILA1] , DB[bbDEST] _ (BBFB[DB[bbDEST]]) SALUFOP (T) ;
bbILA1:	return , AT[BBILA,BBNRM] ;
%	bbila2 will go to 
*		bbila1		no refill required
*		bbilas		source refill required
*		bbilad		dest refill required
*		bbilasd		source and dest refills required
*		bbilai		item refill required
*	
%	
*		function 10
*	
bbILB1:
		call[.+1] , AT[BBIDISP,bbILtype1] ;
		T _ (BBFA[SB[bbSOURCE]]) or (t) ;
bbILB2:	DISP[bbILB3] , RTEMP _ T ;	*5 copies of the following code are
				*required to save the dispatch data
				*from the BBFA executed previously
%	bbilb2 will go to 
*		bbilb3  	no refill required
*		bbilb3s 	source refill required
*		bbilb3d 	dest refill required
*		bbilb3sd	source and dest refills required
*		bbilb3i 	item refill required
%
bbILB3:	DB[bbDEST] _ (DB[bbDEST]) AND NOT(T) , AT[BBILB,BBNRM] ;
	T _ RTEMP ;
	T _ (bbGRY) AND (T) ;
bbILB6:	return , DB[bbDEST] _ (BBFB[DB[bbDEST]]) OR (T) ;
*
bbILB3S:	DB[bbDEST] _ (DB[bbDEST]) AND NOT(T) , AT[BBILB,BBSRC] ;
	T _ RTEMP ;
	T _ (bbGRY) AND (T) ;
bbILB6S:	GOTO[bbILBS] , DB[bbDEST] _ (BBFB[DB[bbDEST]]) OR (T) ;
*
bbILB3D:	DB[bbDEST] _ (DB[bbDEST]) AND NOT(T) , AT[BBILB,BBDST] ;
	call[bbtgry],T _ RTEMP ;
bbILB6D:	GOTO[bbILBD] , DB[bbDEST] _ (BBFB[DB[bbDEST]]) OR (T) ;
*
bbILB3SD:	DB[bbDEST] _ (DB[bbDEST]) AND NOT(T) , AT[BBILB,BBBTH] ;
	call[bbtgry],T _ RTEMP ;
bbILB6SD:	GOTO[bbILBSD] , DB[bbDEST] _ (BBFB[DB[bbDEST]]) OR (T) ;
*
bbILB3I:	DB[bbDEST] _ (DB[bbDEST]) AND NOT(T) , AT[BBILB,BBITM] ;
	call[bbtgry],T _ RTEMP ;
bbILB6I:	GOTO[bbILBI] , DB[bbDEST] _ (BBFB[DB[bbDEST]]) OR (T) ;
bbtgry:
	T _ (bbGRY) AND (T),return ;

*		functions 11-13

bbILC1:
		call[.+1] , AT[BBIDISP,bbILtype2] ;
		T _ (BBFA[SB[bbSOURCE]]) or (t) ;
bbILC2:		DISP[bbILC3] , T _ (bbGRY) AND (T) ;
bbILC3:		return , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) , AT[BBILC,BBNRM] ;
%	bbilc2 will go to 
*		bbilc3		no refill required
*		bbilc3s		source refill required
*		bbilc3d		dest refill required
*		bbilc3sd	source and dest refills required
*		bbilc3i		item refill required
%
*		functions 14

bbILE1x:
		call[.+1] , AT[BBIDISP,bbILtype4] ;
		T _ (BBFA[AllOnes]) ;
bbILE3:	DISP[bbILE4] , T _ (bbGRY) and (t) ;
bbILE4:	return , DB[bbDEST] _ (BBFB[DB[bbDEST]]) SALUFOP (T) , AT[BBILE,BBNRM] ;
%	bbile3 will go to 
*		bbile4		no refill required
*		bbile4s		source refill required
*		bbile4d		dest refill required
*		bbile4sd		source and dest refills required
*		bbile4i		item refill required
%


*		functions 15-17

bbILD1:
		call[.+1] , AT[BBIDISP,bbILtype3] ;
		T _ BBFA[AllOnes] ;
bbILD3:		DISP[bbILD4] , T _ (bbGRY) AND (T) ;
bbILD4:		return , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) , AT[BBILD,BBNRM] ;
%	bbild3 will go to 
*		bbild4		no refill required
*		bbild4s		source refill required
*		bbild4d		dest refill required
*		bbild4sd	source and dest refills required
*		bbild4i		item refill required
%

*Source refill
bbSourceRefill:
bbILBS:
bbILAS:	DBLGOTO[bbNoSrcFetch,bbSrcFetch,R ODD] , bbSrcQAddrLo _ (bbSrcQAddrLo) + (4C) , AT[BBILA,BBSRC] ;
bbILC3S:	GOTO[bbSourceRefill] , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) , AT[BBILC,BBSRC] ;
bbILD4S:	GOTO[bbSourceRefill] , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) , AT[BBILD,BBSRC] ;
bbILE4S:	GOTO[bbSourceRefill] , DB[bbDEST] _ (BBFB[DB[bbDEST]]) SALUFOP (T) , AT[BBILE,BBSRC] ;

bbILret:
bbNoSrcFetch:
	return ;
bbSrcFetch:
	goto[.+3,nocarry];
	bbSrcQAddrHi_(bbSrcQAddrHi)+(400c)+1;
	nop;*can't load hi base reg in m-i preceding a memory operation
	PFETCH4[bbSrcQAddrLo,bbSOURCE,0] , return ;

*Dest refill
bbDestRefill:
	nop;
bbDestRefillx:
	GOTO[bbDestFetch] , PSTORE4[bbDestQAddrLo,bbDEST,0];
bbILBD:
bbILAD:	GOTO[bbDestRefillx] , AT[BBILA,BBDST] ;
bbILC3D:	GOTO[bbDestRefill] , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) , AT[BBILC,BBDST] ;
bbILD4D:	GOTO[bbDestRefill] , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) , AT[BBILD,BBDST] ;
bbILE4D:	GOTO[bbDestRefill] , DB[bbDEST] _ (BBFB[DB[bbDEST]]) SALUFOP (T) , AT[BBILE,BBDST] ;

bbDestFetch:
	bbDestQAddrLo _ (bbDestQAddrLo) + (4C);
	goto[.+3,nocarry];
	bbDestQAddrHi_(bbDestQAddrHi)+(400c)+1;
	nop;*can't load hi base reg in m-i preceding a memory operation
	goto[bbildisp] , PFETCH4[bbDestQAddrLo,bbDEST,0] ;


*	Source and Dest refill
bbSrcDestRefill:
bbILBSD:
bbILASD:	DBLGOTO[bbDestRefill,bbSrcDestFetch,R ODD] , bbSrcQAddrLo _ (bbSrcQAddrLo) + (4C) , AT[BBILA,BBBTH] ;
bbILC3SD:	GOTO[bbSrcDestRefill] , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) , AT[BBILC,BBBTH] ;
bbILD4SD:	GOTO[bbSrcDestRefill] , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) , AT[BBILD,BBBTH] ;
bbILE4SD:	GOTO[bbSrcDestRefill] , DB[bbDEST] _ (BBFB[DB[bbDEST]]) SALUFOP (T) , AT[BBILE,BBBTH] ;

bbSrcDestFetch:
	goto[.+3,nocarry];
	bbSrcQAddrHi_(bbSrcQAddrHi)+(400c)+1;
	nop;*can't load hi base reg in m-i preceding a memory operation
	PFETCH4[bbSrcQAddrLo,bbSOURCE,0] , goto[bbDestRefill] ;

*	Common return to inner loops
bbILDISP:
	call[bbILret] , BBFB ;
	DISPATCH[bbFunction,10,4] ;
	DISP[bbInnerLoops] ;
%			depending upon the loop type this will go to
*		type 0	bbila1z		function 0-7
*		type 1	bbilb1		function 10
*		type 2	bbilc1		function 11-13
*		type 3	bbild1		function 15-17
*		type 4	bbile1x		function 14
%

*	Item refill
*			test if right to left or left to right
bbItemRefill:
bbILBI:
bbILAI:	GOTO[bbILI] , lu_ldf[bbFunction,7,1] , AT[BBILA,BBITM] ;
bbILC3I:	GOTO[bbItemRefill] , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) , AT[BBILC,BBITM] ;
bbILD4I:	GOTO[bbItemRefill] , DB[bbDEST] _ (BBFBX[DB[bbDEST]]) SALUFOP (T) , AT[BBILD,BBITM] ;
bbILE4I:	GOTO[bbItemRefill] , DB[bbDEST] _ (BBFB[DB[bbDEST]]) SALUFOP (T) , AT[BBILE,BBITM] ;

bbILI:	goto[bbContRtoL,alu#0] ;

*		common item refill
bbComItemRefill:
	pstore4[bbDestQAddrLo,bbDEST,0] ;
	call[bbILret],stack _ (stack) + 1 ;*update icom (TOS if called by Mesa, AC1 if called by Nova)
	GOTO[.+3,R >= 0] , bbItemsRemainingMinus2 _ (bbItemsRemainingMinus2) - 1 ;
bbExitp1:	LoadPage[bbp2];
	lu _ ldf[bbFunction,1,1], gotop[bbExit]; *Completion return
*Test for interrupts
	lu _ NWW,skip[R>=0];
	dblgoto[bbDestUpdate,bbSrcUpdate,R ODD],lu_bbSrcQAddrLo; *Interrupts disabled by Nova
	skip[ALU#0],lu _ ldf[bbFunction,1,1];
	dblgoto[bbDestUpdate,bbSrcUpdate,R ODD],lu_bbSrcQAddrLo;
	dblgoto[bbMesaInt,bbNovaInt,ALU#0];

bbMesaInt:	LoadPage[opPage3];
	T _ 1c, callp[MIPend];	*back up the Mesa PC by 1
	dblgoto[bbDestUpdate,bbSrcUpdate,R ODD],lu_bbSrcQAddrLo;

*Since we are now in a subroutine, and since the Nova only checks for interrupts at buffer
*refill and during jumbs, things are complicated.  We simulate a JMP .+0

bbNovaInt:	T _ ldf[GETRSPEC[127],15,2];
	 LoadPage[nePage]; *Point the jump-to PC at the BitBLT
	T _ (PCB) + (T), gotop[JMP];


bbSrcUpdate:
	skip[r>=0],t _ lsh[bbSBMR,4] ;
	bbSrcStartBitHi_(bbSrcStartBitHi)-(20c);
	bbSrcStartBitLo _ (bbSrcStartBitLo) + (t) ;
	skip[nocarry],t_rsh[bbSBMR,14];
	bbSrcStartBitHi _ (bbSrcStartBitHi) + 1 ;
	bbSrcStartBitHi _ (bbSrcStartBitHi) + (t);

bbDestUpdate:
	skip[r>=0],t _ lsh[bbDBMR,4] ;
	bbDestStartBitHi_(bbDestStartBitHi)-(20c);
	bbDestStartBitLo _ (bbDestStartBitLo) + (t) ;
	skip[nocarry],t_rsh[bbDBMR,14];
	bbDestStartBitHi _ (bbDestStartBitHi) + 1 ;
	bbDestStartBitHi _ (bbDestStartBitHi) + (t);

bbFirstItem:
bbTouchSourcePages:
	call[bbILret];*task switch
	GOTO[bbTouchDestPages,R ODD],lu_bbSrcQAddrLo ;
	t_(bbMinusItemWidth)+1;
	RTEMP_(zero)-(t);
	call[bbSetbbSQA];
	t_(bbSrcStartBitLo) and not (170000c);
	RTEMP_(RTEMP)+(t);
	skip[carry],RTEMP_rsh[RTEMP,14];
	goto[bbTSP1];
	skip[alu#0];
	RTEMP_(20c);

bbTSP1:
	t_RTEMP_lsh[RTEMP,10];
	call[.+1];*avoid mem pass-around
	pfetch4[bbSrcQAddrLo,bbSOURCE];
	t_RTEMP_(RTEMP)-(400c);
	skip[alu<0];
	return;
	nop;

bbTouchDestPages:
	t_(bbMinusItemWidth)+1;
	RTEMP_(zero)-(t);
	call[bbSetbbDQA];
	t_(bbDestStartBitLo) and not (170000c);
	RTEMP_(RTEMP)+(t);
	skip[carry],RTEMP_rsh[RTEMP,14];
	goto[bbTDP1];
	skip[alu#0];
	RTEMP_(20c);

bbTDP1:
	t_RTEMP_lsh[RTEMP,10];
	call[.+1];*avoid mem pass-around
	pfetch4[bbDestQAddrLo,bbDEST];
	t_RTEMP_(RTEMP)-(400c);
	skip[alu<0];
	return;

bbNewGry:
	lu_ldf[bbFunction,14,1];
	goto[bbNoGray,alu=0],MNBR _ bbMinusItemWidth ;
	t_(AC2)+(14c) ;
	lu _ ldf[bbFunction,1,1]; *"called from Mesa" bit
	dblgoto[NovaGray,MesaGray,ALU=0], t_(ldf[bbGrayCnt,16,2])+(t);
NovaGray:	pfetch1[Nova,bbgry], goto[.+2];
MesaGray:	Pfetch1[MDS,bbgry];
	bbGrayCnt_(bbGrayCnt)+1;
bbNoGray:
	SB_bbSrcStartBitLo;
	skip[r even],lu_bbSrcQAddrLo ;
	SB _ bbDestStartBitLo ;
	DB_bbDestStartBitLo;
	lu_ldf[bbFunction,7,1] ;
	skip[alu#0] ;
	GOTO[bbILDISP] ;

bbNewRtoL:	*new item right to left
	t_bbMinusSDNonOverlap ;
	task,bbMinusNumBitsTran_t ;
	t_MNBR_bbMinusNumBitsTran ;
	t_(bbMinusItemWidth)-(t) ;
	call[bbILret],bbMinusBitsRemaining _t;
bbSourceBitUpdate:
	goto[bbDestBitUpdate,r odd],lu_bbSrcQAddrLo;
	bbSrcStartBitLo _ (bbSrcStartBitLo) - (t) ;
	skip[nocarry] ;
	bbSrcStartBitHi _ (bbSrcStartBitHi) + 1 ;
	RTEMP_t;
	call[bbSetbbSQA];
	t_RTEMP;
	SB_bbSrcStartBitLo;
bbDestBitUpdate:
	bbDestStartBitLo _ (bbDestStartBitLo) - (t) ;
	skip[nocarry] ;
	bbDestStartBitHi _ (bbDestStartBitHi) + 1 ;
	goto[bbGetNextSubItem];

bbContRtoL:	*continue item right to left
	t _ bbMinusBitsRemaining ;
	skip[alu#0] , lu _ (bbMinusSDNonOverlap) - (t) ;
	GOTO[bbComItemRefill] ;*current item exhausted
	skip[nocarry],PSTORE4[bbDestQAddrLo,bbDEST,0];
	t _ bbMinusSDNonOverlap ;
	bbMinusNumBitsTran _ t ;
	task,bbMinusBitsRemaining _ (bbMinusBitsRemaining) - (t) ;
	mnbr _ bbMinusNumBitsTran ;
*	  adjust source and dest bit addresses for next sub-item
	goto[bbrlskip,r odd],lu_bbSrcQAddrLo;
	t _ bbMinusNumBitsTran ;
	bbSrcStartBitLo _ (bbSrcStartBitLo) + (t) ;
	skip[carry] ;
	bbSrcStartBitHi _ (bbSrcStartBitHi) - 1 ;
	call[bbSetbbSQA];
	SB_bbSrcStartBitLo;
bbrlskip:
	t _ bbMinusNumBitsTran ;
	bbDestStartBitLo _ (bbDestStartBitLo) + (t) ;
	skip[carry] ;
	 bbDestStartBitHi _ (bbDestStartBitHi) - 1 ;
bbGetNextSubItem:
	call[bbSetbbDQA];
	skip[r even],lu_bbSrcQAddrLo ;
	SB _ bbDestStartBitLo ;
	DB_bbDestStartBitLo;
	pfetch4[bbDestQAddrLo,bbDEST,0] ;
	skip[R ODD] , lu _ bbSrcQAddrLo ;
	pfetch4[bbSrcQAddrLo,bbSOURCE,0] ;
	GOTO[bbILDISP] ;

bbSetbbSQA:	*build source mem-base from source bit
	t_rsh[bbSrcStartBitLo,4] ;
	bbSrcQAddrLo _ t ;
	t_lsh[bbSrcStartBitHi,14] ;
	bbSrcQAddrLo _ (bbSrcQAddrLo) + (t) ;
	t_rsh[bbSrcStartBitHi,4] ;
	bbSrcQAddrHi _ t ;
	bbSrcQAddrHi_(lsh[bbSrcQAddrHi,10]) + (t) + 1 ;
	return,bbSrcQAddrLo _ (bbSrcQAddrLo) and not (3c) ;

bbSetbbDQA:	*build dest mem-base from dest bit
	t_rsh[bbDestStartBitLo,4] ;
	bbDestQAddrLo _ t ;
	t_lsh[bbDestStartBitHi,14] ;
	bbDestQAddrLo _ (bbDestQAddrLo) + (t) ;
	t_rsh[bbDestStartBitHi,4] ;
	bbDestQAddrHi _ t ;
	bbDestQAddrHi_(lsh[bbDestQAddrHi,10]) + (t) + 1 ;
	return,bbDestQAddrLo _ (bbDestQAddrLo) and not (3c) ;


	end[bb];

 