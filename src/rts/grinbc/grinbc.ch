
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Word, and Pointer to Word.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Requirement: sizeof(GB_Ptr) == sizeof(GB_Word)

%%[8
#if USE_64_BITS
typedef uint64_t GB_Word ;
typedef  int64_t GB_SWord ;
#else
typedef uint32_t GB_Word ;
typedef  int32_t GB_SWord ;
#endif

typedef GB_Word* GB_Ptr ;
typedef GB_Ptr*  GB_PtrPtr ;
typedef uint8_t* GB_BytePtr ;
typedef GB_SWord GB_Int ;
typedef uint16_t GB_NodeTag ;
typedef uint16_t GB_NodeSize ;
typedef uint8_t  GB_Byte ;
%%]

%%[8
#define GB_Deref(x)						(*Cast(GB_Ptr,x))
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Node structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Node header layout

%%[8
#if USE_64_BITS
#define GB_NodeHeader_Size_BitSz		32
#define GB_NodeHeader_NdEv_BitSz		2
#define GB_NodeHeader_TagCat_BitSz		2
#define GB_NodeHeader_GC_BitSz			2
#define GB_NodeHeader_Tag_BitSz			26
#else
#define GB_NodeHeader_Size_BitSz		16
#define GB_NodeHeader_NdEv_BitSz		2
#define GB_NodeHeader_TagCat_BitSz		2
#define GB_NodeHeader_GC_BitSz			2
#define GB_NodeHeader_Tag_BitSz			10
#endif
%%]

Evaluation need: Yes, No, or blackhole (no evaluation, but when requested indicates a loop)

%%[8
#define GB_NodeNdEv_BlH					2			/* black hole */
#define GB_NodeNdEv_Yes					1
#define GB_NodeNdEv_No					0
%%]

Node categories. Two groups, the first require evaluation, the second not.

%%[8
#define GB_NodeTagCat_Fun				0			/* saturated function call closure 		*/
#define GB_NodeTagCat_App				1			/* general purpose application 			*/
#define GB_NodeTagCat_Ind				2			/* indirection 							*/
#define GB_NodeTagCat_CFun				3			/* saturated C function call closure 	*/

#define GB_NodeTagCat_Con				0			/* data, constructor 											*/
#define GB_NodeTagCat_PAp				1			/* partial application, tag is size of missing 					*/
%%[[95
#define GB_NodeTagCat_Intl				3			/* other internal structures, further described by tag 			*/
%%]]
%%]

Node header.

%%[8
#if NODEHEADER_VIA_STRUCT
typedef struct GB_NodeHeader {
  unsigned 	size 		: GB_NodeHeader_Size_BitSz 		;			/* size, incl header, in words 					*/
  unsigned 	needsEval 	: GB_NodeHeader_NdEv_BitSz 		;			/* possibly needs eval? 						*/
  unsigned 	tagCateg 	: GB_NodeHeader_TagCat_BitSz 	;			/* kind of tag, dpd on needsEval 				*/
  unsigned 	gc 			: GB_NodeHeader_GC_BitSz		;			/* garbage collection info (unused currently)	*/
  unsigned 	tag 		: GB_NodeHeader_Tag_BitSz 		;			/* tag, or additional size dpd on tagCateg 		*/
} GB_NodeHeader ;

#define GB_NH_Fld_Size(x)				((x)->size)
#define GB_NH_Fld_NdEv(x)				((x)->needsEval)
#define GB_NH_Fld_TagCat(x)				((x)->tagCateg)
#define GB_NH_Fld_GC(x)					((x)->gc)
#define GB_NH_Fld_Tag(x)				((x)->tag)

#else

typedef GB_Word GB_NodeHeader ;

#define GB_NH_Tag_Shift					0			
#define GB_NH_GC_Shift					(GB_NH_Tag_Shift + GB_NodeHeader_Tag_BitSz)
#define GB_NH_TagCat_Shift				(GB_NH_GC_Shift + GB_NodeHeader_GC_BitSz)
#define GB_NH_NdEv_Shift				(GB_NH_TagCat_Shift + GB_NodeHeader_TagCat_BitSz)
#define GB_NH_Size_Shift				(GB_NH_NdEv_Shift + GB_NodeHeader_NdEv_BitSz)
#define GB_NH_Full_Shift				(GB_NH_Size_Shift + GB_NodeHeader_Size_BitSz)

#define GB_NH_MkFld_Size(x)				(Cast(GB_Word,x)<<GB_NH_Size_Shift)
#define GB_NH_MkFld_NdEv(x)				(Cast(GB_Word,x)<<GB_NH_NdEv_Shift)
#define GB_NH_MkFld_TagCat(x)			(Cast(GB_Word,x)<<GB_NH_TagCat_Shift)
#define GB_NH_MkFld_GC(x)				(Cast(GB_Word,x)<<GB_NH_GC_Shift)
#define GB_NH_MkFld_Tag(x)				(Cast(GB_Word,x)<<GB_NH_Tag_Shift)

#define GB_NH_FldBits(x,f,t)			Bits_ExtrFromToSh(GB_Word,x,f,t)
#define GB_NH_FldBitsFr(x,f)			Bits_ExtrFromSh(GB_Word,x,f)
#define GB_NH_FldMask(f,t)				Bits_MaskFromTo(GB_Word,f,t)
#define GB_NH_FldMaskFr(f)				Bits_MaskFrom(GB_Word,f)

#define GB_NH_Mask_Size					GB_NH_FldMaskFr(GB_NH_Size_Shift)
#define GB_NH_Mask_NdEv					GB_NH_FldMask(GB_NH_NdEv_Shift,GB_NH_Size_Shift-1)
#define GB_NH_Mask_TagCat				GB_NH_FldMask(GB_NH_TagCat_Shift,GB_NH_NdEv_Shift-1)
#define GB_NH_Mask_GC					GB_NH_FldMask(GB_NH_GC_Shift,GB_NH_TagCat_Shift-1)
#define GB_NH_Mask_Tag					GB_NH_FldMask(GB_NH_Tag_Shift,GB_NH_GC_Shift-1)

#define GB_NH_SetFld(h,m,x)				(((h) & (~ (m))) | (x))
#define GB_NH_SetFld_Size(h,x)			GB_NH_SetFld(h,GB_NH_Mask_Size,GB_NH_MkFld_Size(x))
#define GB_NH_SetFld_NdEv(h,x)			GB_NH_SetFld(h,GB_NH_Mask_NdEv,GB_NH_MkFld_NdEv(x))
#define GB_NH_SetFld_TagCat(h,x)		GB_NH_SetFld(h,GB_NH_Mask_TagCat,GB_NH_MkFld_TagCat(x))
#define GB_NH_SetFld_GC(h,x)			GB_NH_SetFld(h,GB_NH_Mask_GC,GB_NH_MkFld_GC(x))
#define GB_NH_SetFld_Tag(h,x)			GB_NH_SetFld(h,GB_NH_Mask_Tag,GB_NH_MkFld_Tag(x))

#define GB_NH_Fld_Size(x)				GB_NH_FldBitsFr(x,GB_NH_Size_Shift)
#define GB_NH_Fld_NdEv(x)				GB_NH_FldBits(x,GB_NH_NdEv_Shift,GB_NH_Size_Shift-1)
#define GB_NH_Fld_TagCat(x)				GB_NH_FldBits(x,GB_NH_TagCat_Shift,GB_NH_NdEv_Shift-1)
#define GB_NH_Fld_GC(x)					GB_NH_FldBits(x,GB_NH_GC_Shift,GB_NH_TagCat_Shift-1)
#define GB_NH_Fld_Tag(x)				GB_NH_FldBits(x,GB_NH_Tag_Shift,GB_NH_GC_Shift-1)

#endif

%%]

%%[95
#define GB_NodeTag_Intl_Malloc			0			// Internal node: A malloc'ed ptr, requiring finalisation
%%]

%%[99
#if USE_GMP
#define GB_NodeTag_Intl_GMP_mpz			1			// Internal node: A GMP mpz_t 
#define GB_NodeTag_Intl_GMP_intl		2			// Internal node: GMP internal allocated 
#endif
%%]

%%[8
typedef struct GB_Node {
  GB_NodeHeader	header ;
  union {
    GB_Word 		fields[1] ;			/* size 1 is ok for a CAF, but not for other static node initializers */
%%[[95
    void*			ptr ;				/* when GB_NodeTag_Intl_Malloc */
%%]]
%%[[99
#if USE_GMP
    mpz_t			mpz ;				/* when GB_NodeTag_Intl_GMP_mpz */
#endif
%%]]
  } content ;
} GB_Node, *GB_NodePtr ;

#if NODEHEADER_VIA_STRUCT
#define GB_NH_NrFlds(h)					((h).size-1)
#else
#define GB_NH_NrFlds(h)					(GB_NH_Fld_Size(h)-1)
#endif

#define GB_Node_NrFlds(n)				GB_NH_NrFlds((n)->header)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Node construction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#if NODEHEADER_VIA_STRUCT
#define GB_MkHeader(sz,ev,cat,tg)			{sz, ev, cat, 0, tg}
#else
#define GB_MkHeader(sz,ev,cat,tg)			(GB_NH_MkFld_Size(sz) | GB_NH_MkFld_NdEv(ev) | GB_NH_MkFld_TagCat(cat) | GB_NH_MkFld_GC(0) | GB_NH_MkFld_Tag(tg))
#endif

#define GB_MkFunHeader(nArg)				GB_MkHeader((nArg)+2, GB_NodeNdEv_Yes, GB_NodeTagCat_Fun, 0)
#define GB_MkCFunHeader(nArg)				GB_MkHeader((nArg)+2, GB_NodeNdEv_Yes, GB_NodeTagCat_CFun, 0)
#define GB_MkCAFHeader						GB_MkFunHeader(0)
#define GB_MkConHeader(sz,tg)				GB_MkHeader((sz)+1, GB_NodeNdEv_No, GB_NodeTagCat_Con, tg)

#define GB_MkConEnumNode(tg)				{ GB_MkConHeader(0,tg) }

#define GB_FillNodeFlds1(n,x1)				{(n)->content.fields[0] = Cast(GB_Word,x1);}
#define GB_FillNodeFlds2(n,x1,x2)			{GB_FillNodeFlds1(n,x1   );(n)->content.fields[1] = Cast(GB_Word,x2);}
#define GB_FillNodeFlds3(n,x1,x2,x3)		{GB_FillNodeFlds2(n,x1,x2);(n)->content.fields[2] = Cast(GB_Word,x3);}

#define GB_FillNodeHdr(h,n)					{(n)->header = h;}
#define GB_FillConNode0(n,tg)				{GB_NodeHeader _h = GB_MkConHeader(0,tg); GB_FillNodeHdr(_h,n);}
#define GB_FillConNode1(n,tg,x1)			{GB_NodeHeader _h = GB_MkConHeader(1,tg); GB_FillNodeHdr(_h,n); GB_FillNodeFlds1(n,x1);}
#define GB_FillConNode2(n,tg,x1,x2)			{GB_NodeHeader _h = GB_MkConHeader(2,tg); GB_FillNodeHdr(_h,n); GB_FillNodeFlds2(n,x1,x2);}

#define GB_MkConNodeN(n,sz,tg)				{GB_NodeAlloc_In(1+sz,n); GB_FillConNode0(n,tg); }
#define GB_MkFixConNodeN(n,sz,tg)			{GB_NodeFixAlloc_In(1+sz,n); GB_FillConNode0(n,tg); }
#define GB_MkConNode0(n,tg)					{GB_NodeAlloc_In(1,n); GB_FillConNode0(n,tg); }
#define GB_MkConNode1(n,tg,x1)				{GB_NodeAlloc_In(2,n); GB_FillConNode1(n,tg,x1); }
#define GB_MkConNode2(n,tg,x1,x2)			{GB_NodeAlloc_In(3,n); GB_FillConNode2(n,tg,x1,x2); }

#define GB_FillCFunNode0(n,f)				{GB_NodeHeader _h = GB_MkCFunHeader(0); GB_FillNodeHdr(_h,n);GB_FillNodeFlds1(n,f);}
#define GB_FillCFunNode1(n,f,x1)			{GB_NodeHeader _h = GB_MkCFunHeader(1); GB_FillNodeHdr(_h,n);GB_FillNodeFlds2(n,f,x1);}
#define GB_FillCFunNode2(n,f,x1,x2)			{GB_NodeHeader _h = GB_MkCFunHeader(2); GB_FillNodeHdr(_h,n);GB_FillNodeFlds3(n,f,x1,x2);}

#define GB_MkCFunNode0(n,f)					{GB_NodeAlloc_In(2,n); GB_FillCFunNode0(n,f); }
#define GB_MkCFunNode1(n,f,x1)				{GB_NodeAlloc_In(3,n); GB_FillCFunNode1(n,f,x1); }
#define GB_MkCFunNode2(n,f,x1,x2)			{GB_NodeAlloc_In(4,n); GB_FillCFunNode2(n,f,x1,x2); }

extern GB_Node* gb_MkCAF( GB_BytePtr pc ) ;
%%]

%%[95
#define GB_NodeMallocSize					(EntierUpDivBy(sizeof(void*),sizeof(GB_Word)) + 1)

#define GB_MkMallocHeader					GB_MkHeader(GB_NodeMallocSize, GB_NodeNdEv_No, GB_NodeTagCat_Intl, GB_NodeTag_Intl_Malloc)
%%]

%%[99
#if USE_GMP
#define GB_NodeMpzSize						(EntierUpDivBy(sizeof(mpz_t),sizeof(GB_Word)) + 1)
#define GB_NodeGMPSize(nBytes)				(EntierUpDivBy(nBytes,sizeof(GB_Word)) + 1)

#define GB_MkMpzHeader						GB_MkHeader(GB_NodeMpzSize, GB_NodeNdEv_No, GB_NodeTagCat_Intl, GB_NodeTag_Intl_GMP_mpz)
#define GB_MkGMPHeader(sz)					GB_MkHeader(sz, GB_NodeNdEv_No, GB_NodeTagCat_Intl, GB_NodeTag_Intl_GMP_intl)
#endif
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% List
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#define GB_Tag_List_Nil						1
#define GB_Tag_List_Cons					0

#define GB_MkListNil(n)						{n = &gb_Nil;}
#define GB_MkListCons(n,x1,x2)				GB_MkConNode2(n,GB_Tag_List_Cons,x1,x2)

#define GB_List_IsNull(n)					(GB_NH_Fld_Tag((n)->header) == GB_Tag_List_Nil)
#define GB_List_Head(n)						((n)->content.fields[0])
#define GB_List_Tail(n)						Cast( GB_NodePtr,(n)->content.fields[1] )
#define GB_List_TailPtr(n)					Cast( GB_NodePtr*,&(n)->content.fields[1] )

#define GB_List_Iterate(n,sz,body)			while ( sz-- && ! GB_List_IsNull( n ) ) { \
												body ; \
												n = GB_List_Tail(n) ; \
											}

%%]

%%[8
extern GB_NodePtr gb_listTail( GB_NodePtr n ) ;
extern GB_Word gb_listHead( GB_NodePtr n ) ;
extern Bool gb_listNull( GB_NodePtr n ) ;
extern GB_NodePtr gb_listForceEval( GB_NodePtr* pn, int sz ) ;
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PackedString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#define GB_Tag_PackedString					0
#define GB_Tag_PackedStringOffset			1
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Linking, fixing addresses, module info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#define GB_LinkTbl_EntryKind_Const					0			/* obsolete (now via PatchCode_Deref1): constant */
#define GB_LinkTbl_EntryKind_ConstPtr				1			/* obsolete (now via PatchCode_Deref2): ptr to constant */
#define GB_LinkTbl_EntryKind_CodeEntry				2			/* code entry */
#define GB_LinkTbl_EntryKind_PatchCode				3			/* patch code with value */
#define GB_LinkTbl_EntryKind_PatchCode_Deref1		4			/* patch code with *value */
#define GB_LinkTbl_EntryKind_PatchCode_Deref2		5			/* patch code with **value */
#define GB_LinkTbl_EntryKind_PatchOffsets			6			/* patch code containing offsets with abolute address */
%%[[12
#define GB_LinkTbl_EntryKind_ImpEntry				7			/* import entry */
%%]]
%%]

Link commands for global references

%%[8
typedef struct GB_LinkEntry {
  uint16_t		tblKind ;
  GB_Ptr		linkLoc ;
  GB_Word		linkVal ;
} GB_LinkEntry ;
%%]

Module info

%%[12
typedef struct GB_ModEntry {
  char*			name ;
  GB_NodePtr	*expNode ;
} GB_ModEntry ;

extern GB_ModEntry* gb_lookupModEntry( char* modNm, GB_ModEntry* modTbl ) ;

%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Memory management
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Assume that sizeof(GrWord) == sizeof(GB_Word).
This should be ok and merged later on, but a check in it is currently part of the sanity check.
Size must be minimal 2 words to ensure enough space for an indirection pointer (plus the usual header in front).

%%[8
#if USE_BOEHM_GC
#define GB_HeapAlloc_Words(nWords)		GB_HeapAlloc_Bytes(nWords * sizeof(GB_Word))
#define GB_HeapFixAlloc_Words(nWords)	GB_HeapFixAlloc_Bytes(nWords * sizeof(GB_Word))
#define GB_HeapAlloc_Bytes(nBytes)		Cast(GB_Ptr,GC_MALLOC(nBytes))
#define GB_HeapFixAlloc_Bytes(nBytes)	Cast(GB_Ptr,GC_MALLOC_UNCOLLECTABLE(nBytes))

extern void gb_Node_Finalize( void* p, void* cd ) ;
extern void* gb_Dummy_Finalization_Proc ;
extern void* gb_Dummy_Finalization_cd ;

#else

#define GB_HeapAlloc_Words(nWords)		Cast(GB_Ptr,heapalloc(nWords))
#define GB_HeapFixAlloc_Words(nWords)	GB_HeapAlloc_Words(nWords)
#define GB_HeapAlloc_Bytes(nBytes)		GB_HeapAlloc_Words(EntierUpBy(nBytes,sizeof(GB_Word)))
#define GB_HeapFixAlloc_Bytes(nBytes)	GB_HeapAlloc_Bytes(nBytes)	
#endif

#define GB_NodeAlloc_In(nWords,n)			{ (n) = Cast(GB_NodePtr,GB_HeapAlloc_Words(nWords)) ; }
#define GB_NodeFixAlloc_In(nWords,n)		{ (n) = Cast(GB_NodePtr,GB_HeapFixAlloc_Words(nWords)) ; }
#define GB_NodeAlloc_Hdr_In(nWords,h,n)		{ GB_NodeAlloc_In(nWords,n) ; (n)->header = (h) ; }
%%]

For finalizers boehm's gc is assumed!!!!
This breaks when compiled without bgc.

%%[95
#if USE_BOEHM_GC
#define GB_NodeAlloc_Malloc_In(nBytes,n)	{ GB_NodeAlloc_Hdr_In(GB_NodeMallocSize,GB_MkMallocHeader,n) ; \
											  (n)->content.ptr = malloc(nBytes) ; \
											  GC_REGISTER_FINALIZER(n, &gb_Node_Finalize, (n)->content.ptr, Cast(GC_finalization_proc*,&gb_Dummy_Finalization_Proc), &gb_Dummy_Finalization_cd) ; \
											}
#endif
%%]

%%[99
#if USE_GMP
#define GB_NodeAlloc_Mpz_In(n)				{ GB_NodeAlloc_Hdr_In(GB_NodeMpzSize,GB_MkMpzHeader,n) ; mpz_init((n)->content.mpz) ; }
#define GB_NodeAlloc_GMP_In(nBytes,n)		{ int sz = GB_NodeGMPSize(nBytes) ; GB_NodeAlloc_Hdr_In(sz,GB_MkGMPHeader(sz),n) ; }

extern void* gb_Alloc_GMP( size_t nBytes ) ;
extern void* gb_ReAlloc_GMP( void *n, size_t nBytesOld, size_t nBytes ) ;
extern void gb_Free_GMP( void *n, size_t nBytesOld ) ;
#endif
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GB_Ptr and GB_Int are tagged values, stored in a GB_Word, GB_Ints are shifted left
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#define GB_Word_TagSize 			1
#define GB_Word_TagMask 			1
#define GB_Word_IntMask 			(~ GB_Word_TagMask)
#define GB_Word_TagInt 				1
#define GB_Word_TagPtr 				0

#define GB_Int_ShiftPow2			Bits_Pow2(GB_Int,GB_Word_TagSize)

#define GB_Word_IsInt(x)			((x) & GB_Word_TagMask)
#define GB_Word_IsPtr(x)			(! GB_Word_IsInt(x))
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GB_Int arithmetic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#define GB_GBInt2CastedInt(ty,x)	(Cast(ty,(x)&GB_Word_IntMask) / GB_Int_ShiftPow2)
#define GB_GBInt2Int(x)				GB_GBInt2CastedInt(int,x)
#define GB_Int2GBInt(x)				((Cast(GB_Int,x)) << GB_Word_TagSize | GB_Word_TagInt)

#define GB_Int0						GB_Int2GBInt(0)
#define GB_Int1						GB_Int2GBInt(1)
#define GB_Int2						GB_Int2GBInt(2)

#define GB_Int_Add(x,y)				((x) + (y) - GB_Word_TagInt)
#define GB_Int_Sub(x,y)				((x) - (y) + GB_Word_TagInt)
#define GB_Int_Mul(x,y)				(((x)-GB_Word_TagInt) * ((y)/GB_Int_ShiftPow2) + GB_Word_TagInt)
#define GB_Int_Div(x,y)				((((x)-GB_Word_TagInt) / (((y)-GB_Word_TagInt))) * GB_Int_ShiftPow2 + GB_Word_TagInt)
#define GB_Int_Neg(x)				GB_Int_Sub(GB_Int0,x)

%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Integer via GMP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mpz_t is defined as an array, this makes casting problematic (compiler complains),
so a pointer based definition is used. However, __mpz_struct is an internal type which may
undergo name changes as GMP versions progress.

%%[99
#if USE_GMP
typedef __mpz_struct*  GB_mpz ;

#define GB_Integer_Op_In(op,z,x,y)		{ GB_NodeAlloc_Mpz_In(z) ; op( z->content.mpz, x->content.mpz, y->content.mpz ) ; }
#define GB_Integer_Add_In(z,x,y)		GB_Integer_Op_In(mpz_add,z,x,y)
#define GB_Integer_Sub_In(z,x,y)		GB_Integer_Op_In(mpz_sub,z,x,y)
#define GB_Integer_Mul_In(z,x,y)		GB_Integer_Op_In(mpz_mul,z,x,y)
#define GB_Integer_Div_In(z,x,y)		GB_Integer_Op_In(mpz_cdiv_q,z,x,y)

#define GB_Integer_Cmp(x,y)				mpz_cmp(x->content.mpz, y->content.mpz)

#endif
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Instruction opcode inline operands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
/* Location variant: load source, store destination, extensive variant */
#define GB_InsOp_LocE_SP			0x0
#define GB_InsOp_LocE_Reg			0x1
#define GB_InsOp_LocE_Imm			0x2
#define GB_InsOp_LocE_PC			0x3

/* Location variant: load destination, store source, brief variant */
#define GB_InsOp_LocB_TOS			0x0
#define GB_InsOp_LocB_Reg			0x1

/* Location variant: operator destination */
#define GB_InsOp_LocODst_TOS		0x0
#define GB_InsOp_LocODst_Reg		0x1

/* Location variant: operator source */
#define GB_InsOp_LocOSrc_SP			0x0
#define GB_InsOp_LocOSrc_Reg		0x1
#define GB_InsOp_LocOSrc_Imm		0x2
#define GB_InsOp_LocOSrc_TOS		0x3

/* Operator kind/type */
#define GB_InsOp_TyOp_Add			0x0
#define GB_InsOp_TyOp_Sub			0x1
#define GB_InsOp_TyOp_Mul			0x2
#define GB_InsOp_TyOp_Div			0x3

/* Operator data kind/type */
#define GB_InsOp_DataOp_IW			0x0
#define GB_InsOp_DataOp_II			0x1
#define GB_InsOp_DataOp_FW			0x2

/* Immediate constant size */
#define GB_InsOp_ImmSz_08			0x0
#define GB_InsOp_ImmSz_16			0x1
#define GB_InsOp_ImmSz_32			0x2
#define GB_InsOp_ImmSz_64			0x3

/* Indirection level, deref times */
#define GB_InsOp_Deref0				0x0
#define GB_InsOp_Deref1				0x1
#define GB_InsOp_Deref2				0x2
#define GB_InsOp_DerefInt			0x3

/* Indirection level, deref times, brief variant */
#define GB_InsOp_DerefB1			0x0
#define GB_InsOp_DerefB2			0x1

%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Groups/categories/prefixes of/for instruction opcodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#define GB_Ins_Prefix(pre,sh)					(Cast(GB_Byte,pre) << (sh))

#define GB_Ins_PreLd							GB_Ins_Prefix(0x0,7)
#define GB_Ins_PreSt							GB_Ins_Prefix(0x2,6)
#define GB_Ins_PreArith							GB_Ins_Prefix(0x6,5)
#define GB_Ins_PreEvAp							GB_Ins_Prefix(0x1C,3)
#define GB_Ins_PreHeap							GB_Ins_Prefix(0x1D,3)
#define GB_Ins_PreCall							GB_Ins_Prefix(0x1E,3)
#define GB_Ins_PreOther							GB_Ins_Prefix(0x1F,3)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Instruction opcodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#define GB_Ins_Ld(indLev,locB,locE,immSz)		(GB_Ins_PreLd | ((indLev) << 5) | ((locB) << 4) | ((locE) << 2) | ((immSz) << 0))
#define GB_Ins_St(indLev,locE,locB,immSz)		(GB_Ins_PreSt | ((indLev) << 5) | ((locE) << 3) | ((locB) << 2) | ((immSz) << 0))
#define GB_Ins_Call(locB)						(GB_Ins_PreCall | ((0x0) << 1) | ((locB) << 0))
#define GB_Ins_TailCall(locB)					(GB_Ins_PreCall | ((0x1) << 1) | ((locB) << 0))
#define GB_Ins_RetCall							(GB_Ins_PreCall | ((0x2) << 1) | 0x0)
#define GB_Ins_RetCase							(GB_Ins_PreCall | ((0x2) << 1) | 0x1)
#define GB_Ins_CaseCall 						(GB_Ins_PreCall | ((0x3) << 1) | 0x0)
#define GB_Ins_CallC	 						(GB_Ins_PreCall | ((0x3) << 1) | 0x1)
#define GB_Ins_Split(locB)						(GB_Ins_PreHeap | ((0x0) << 1) | ((locB) << 0))
#define GB_Ins_Adapt(locB)						(GB_Ins_PreHeap | ((0x1) << 1) | ((locB) << 0))
#define GB_Ins_AllocStore(locB)					(GB_Ins_PreHeap | ((0x2) << 1) | ((locB) << 0))
#define GB_Ins_Fetch(locB)						(GB_Ins_PreHeap | ((0x3) << 1) | ((locB) << 0))
#define GB_Ins_Eval(locB)						(GB_Ins_PreEvAp | ((0x0) << 1) | ((locB) << 0))
#define GB_Ins_Apply(locB)						(GB_Ins_PreEvAp | ((0x1) << 1) | ((locB) << 0))
#define GB_Ins_TailEval(locB)					(GB_Ins_PreEvAp | ((0x2) << 1) | ((locB) << 0))
#define GB_Ins_Ldg(locB)						(GB_Ins_PreEvAp | ((0x3) << 1) | ((locB) << 0))
#define GB_Ins_Op(opTy,dtTy,locO)				(GB_Ins_PreArith | ((opTy) << 3) | ((dtTy) << 1) | ((locO) << 0))
#define GB_Ins_OpExt(indLev,locE,immSz)			(((indLev) << 4) | ((locE) << 2) | ((immSz) << 0))
#define GB_Ins_FetchUpdate						(GB_Ins_PreOther | 0x1)
#define GB_Ins_EvalApplyCont					(GB_Ins_PreOther | 0x2)
#define GB_Ins_PApplyCont						(GB_Ins_PreOther | 0x3)
#define GB_Ins_EvalUpdCont						(GB_Ins_PreOther | 0x5)
#define GB_Ins_Ext								(GB_Ins_PreOther | 0x6)
#define GB_Ins_NOP								(GB_Ins_PreOther | 0x7)
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Extended instruction opcodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#define GB_InsExt_Halt							0xFF
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Interface with interpreter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
extern GB_Byte gb_code_Eval[] ;

extern void gb_push( GB_Word x ) ;
extern GB_Word gb_eval( GB_Word x ) ;

#if GB_COUNT_STEPS
extern unsigned int gb_StepCounter ;
#endif

extern void gb_interpretLoop( ) ;
extern void gb_interpretLoopWith( GB_BytePtr initPC ) ;
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
extern void gb_Initialize() ;

extern void gb_InitTables
	( int byteCodesSz
	, GB_BytePtr byteCodes
	, int linkEntriesSz
	, GB_LinkEntry* linkEntries
	, GB_BytePtr* globalEntries
	, GB_Word* consts
%%[[12
	// , GB_NodePtr *impNode
	// , int impNodeSz, char** impNodeNms
	, GB_NodePtr expNode
	, int expNodeSz, int* expNodeOffs
	, GB_ModEntry* modTbl
%%]]
	) ;
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
extern int gb_Opt_TraceSteps ;
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Sanity check on assumptions made by interpreter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
extern void gb_checkInterpreterAssumptions() ;
%%]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Dumping, tracing. printing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%[8
#if TRACE || DUMP_INTERNALS
extern void gb_prWord( GB_Word x ) ;
#endif
%%]

%%[8
#if DUMP_INTERNALS
extern void gb_prState( char* msg, int maxStkSz ) ;
#endif
%%]

%%[8
#define IF_GB_TR_ON(l,x)		IF_TR_ON(l,if (gb_Opt_TraceSteps) { x })
%%]


