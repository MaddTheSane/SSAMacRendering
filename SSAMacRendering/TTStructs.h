//
//  TTStructs.h
//  SSAMacRendering
//
//  Created by C.W. Betts on 8/4/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#ifndef TTStructs_h
#define TTStructs_h

#include <MacTypes.h>

#pragma pack(push, 2)

typedef struct TT_Header
{
	Fixed   Table_Version;
	Fixed   Font_Revision;
	
	SInt32  CheckSum_Adjust;
	SInt32  Magic_Number;
	
	UInt16  Flags;
	UInt16  Units_Per_EM;
	
	SInt32  Created [2];
	SInt32  Modified[2];
	
	SInt16  xMin;
	SInt16  yMin;
	SInt16  xMax;
	SInt16  yMax;
	
	UInt16  Mac_Style;
	UInt16  Lowest_Rec_PPEM;
	
	SInt16  Font_Direction;
	SInt16  Index_To_Loc_Format;
	SInt16  Glyph_Data_Format;
	
} TT_Header;

//Windows/OS/2 TrueType metrics table
typedef struct TT_OS2
{
	UInt16   version;                /* 0x0001 - more or 0xFFFF */
	SInt16   xAvgCharWidth;
	UInt16   usWeightClass;
	UInt16   usWidthClass;
	SInt16   fsType;
	SInt16   ySubscriptXSize;
	SInt16   ySubscriptYSize;
	SInt16   ySubscriptXOffset;
	SInt16   ySubscriptYOffset;
	SInt16   ySuperscriptXSize;
	SInt16   ySuperscriptYSize;
	SInt16   ySuperscriptXOffset;
	SInt16   ySuperscriptYOffset;
	SInt16   yStrikeoutSize;
	SInt16   yStrikeoutPosition;
	SInt16   sFamilyClass;
	
	UInt8    panose[10];
	
	UInt32   ulUnicodeRange1;        /* Bits 0-31   */
	UInt32   ulUnicodeRange2;        /* Bits 32-63  */
	UInt32   ulUnicodeRange3;        /* Bits 64-95  */
	UInt32   ulUnicodeRange4;        /* Bits 96-127 */
	
	SInt8    achVendID[4];
	
	UInt16   fsSelection;
	UInt16   usFirstCharIndex;
	UInt16   usLastCharIndex;
	SInt16   sTypoAscender;
	SInt16   sTypoDescender;
	SInt16   sTypoLineGap;
	UInt16   usWinAscent;
	UInt16   usWinDescent;
	
	/* only version 1 tables: */
	
	UInt32   ulCodePageRange1;       /* Bits 0-31   */
	UInt32   ulCodePageRange2;       /* Bits 32-63  */
	
	/* only version 2 tables: */
	
	SInt16   sxHeight;
	SInt16   sCapHeight;
	UInt16   usDefaultChar;
	UInt16   usBreakChar;
	UInt16   usMaxContext;
	
} TT_OS2;

#pragma pack(pop)


#endif /* TTStructs_h */
