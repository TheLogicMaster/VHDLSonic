/* The following code was generated by JFlex 1.7.0 tweaked for IntelliJ platform */

package com.thelogicmaster.vhdl_sonic;

import com.intellij.lexer.FlexLexer;
import com.intellij.psi.tree.IElementType;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyTypes;
import com.intellij.psi.TokenType;


/**
 * This class is a scanner generated by 
 * <a href="http://www.jflex.de/">JFlex</a> 1.7.0
 * from the specification file <tt>Assembly.flex</tt>
 */
class AssemblyLexer implements FlexLexer {

  /** This character denotes the end of file */
  public static final int YYEOF = -1;

  /** initial size of the lookahead buffer */
  private static final int ZZ_BUFFERSIZE = 16384;

  /** lexical states */
  public static final int YYINITIAL = 0;
  public static final int ERROR = 2;
  public static final int OPERANDS = 4;
  public static final int LABELED = 6;

  /**
   * ZZ_LEXSTATE[l] is the state in the DFA for the lexical state l
   * ZZ_LEXSTATE[l+1] is the state in the DFA for the lexical state l
   *                  at the beginning of a line
   * l is of the form l = 2*k, k a non negative integer
   */
  private static final int ZZ_LEXSTATE[] = { 
     0,  0,  1,  1,  2,  2,  3, 3
  };

  /** 
   * Translates characters to character classes
   * Chosen bits are [12, 6, 3]
   * Total runtime size is 15664 bytes
   */
  public static int ZZ_CMAP(int ch) {
    return ZZ_CMAP_A[(ZZ_CMAP_Y[(ZZ_CMAP_Z[ch>>9]<<6)|((ch>>3)&0x3f)]<<3)|(ch&0x7)];
  }

  /* The ZZ_CMAP_Z table has 2176 entries */
  static final char ZZ_CMAP_Z[] = zzUnpackCMap(
    "\1\0\1\1\1\2\1\3\1\4\1\5\1\6\1\7\1\10\1\11\1\12\1\13\1\14\1\15\1\16\1\17\1"+
    "\20\1\21\1\22\3\21\1\23\1\24\1\25\1\21\14\26\1\27\50\26\1\30\2\26\1\31\1\32"+
    "\1\33\1\34\25\26\1\35\20\21\1\36\1\37\1\40\1\41\1\42\1\43\1\44\1\45\1\46\1"+
    "\47\1\50\1\21\1\51\1\52\1\53\1\54\1\55\1\56\1\57\1\21\1\26\1\60\1\61\5\21"+
    "\2\26\1\62\7\21\1\26\1\63\20\21\1\26\1\64\1\21\1\65\13\26\1\66\1\26\1\67\22"+
    "\21\1\70\5\21\1\71\11\21\1\72\1\73\1\74\1\75\1\21\1\76\2\21\1\77\3\21\1\100"+
    "\2\21\1\101\1\102\7\21\123\26\1\103\7\26\1\104\1\105\12\26\1\106\24\21\1\26"+
    "\1\107\u0582\21\1\110\u017f\21");

  /* The ZZ_CMAP_Y table has 4672 entries */
  static final char ZZ_CMAP_Y[] = zzUnpackCMap(
    "\1\0\1\1\2\0\1\2\1\3\1\4\1\5\1\6\1\7\1\10\1\11\1\6\1\7\1\10\1\12\1\13\4\0"+
    "\1\14\1\15\1\14\2\16\1\17\3\16\1\17\20\16\1\20\50\16\1\21\1\16\1\22\1\0\1"+
    "\23\1\24\2\0\16\16\1\25\1\26\1\27\1\30\2\16\1\31\11\16\1\32\21\16\1\31\25"+
    "\16\1\33\3\16\1\17\1\34\1\33\4\16\1\0\1\33\4\16\1\32\1\35\1\0\3\16\2\36\3"+
    "\0\1\16\1\36\10\16\1\37\1\40\14\16\1\41\1\42\1\16\1\43\1\37\1\44\2\0\7\16"+
    "\1\45\14\16\1\22\1\0\1\37\1\46\4\16\1\47\1\14\5\16\1\47\2\0\3\16\1\50\10\0"+
    "\2\16\1\25\1\47\2\0\1\51\1\16\1\31\17\16\1\52\1\37\1\33\1\16\1\41\1\42\1\53"+
    "\2\16\1\43\1\54\1\55\1\42\1\56\1\57\1\60\1\52\1\37\1\22\1\0\1\61\1\62\1\53"+
    "\2\16\1\43\1\63\1\64\1\62\1\65\1\34\1\66\1\67\1\37\1\47\1\0\1\61\1\32\1\31"+
    "\2\16\1\43\1\70\1\55\1\32\1\71\1\72\1\0\1\52\1\37\1\0\1\34\1\61\1\42\1\53"+
    "\2\16\1\43\1\70\1\55\1\42\1\65\1\73\1\60\1\52\1\37\1\34\1\0\1\74\1\75\1\76"+
    "\1\77\1\100\1\75\1\16\1\21\1\75\1\76\1\101\1\0\1\67\1\37\2\0\1\41\1\25\1\43"+
    "\2\16\1\43\1\16\1\102\1\25\1\76\1\103\1\36\1\52\1\37\2\0\1\41\1\25\1\43\2"+
    "\16\1\43\1\41\1\55\1\25\1\76\1\103\1\27\1\52\1\37\1\104\1\0\1\61\1\25\1\43"+
    "\4\16\1\45\1\25\1\105\1\51\1\57\1\52\1\37\1\0\1\106\1\74\1\16\1\17\1\106\2"+
    "\16\1\31\1\107\1\17\1\110\1\111\1\16\1\67\1\37\1\112\1\0\1\33\6\16\1\36\1"+
    "\16\1\17\1\37\1\113\4\0\1\114\1\115\1\51\1\33\1\116\1\74\1\16\1\71\1\111\1"+
    "\47\1\37\1\117\4\0\1\72\2\0\1\22\1\37\1\113\1\120\1\121\1\16\1\33\3\16\1\23"+
    "\1\33\1\16\1\25\2\16\1\33\3\16\1\23\1\27\7\0\10\16\1\37\1\113\10\16\1\37\1"+
    "\122\4\16\1\32\1\15\5\16\1\123\51\16\1\76\1\17\1\76\5\16\1\76\4\16\1\76\1"+
    "\17\1\76\1\16\1\17\7\16\1\76\10\16\1\45\4\0\2\16\2\0\12\16\2\47\1\33\114\16"+
    "\1\42\2\16\1\33\2\16\1\36\11\16\1\75\1\16\1\72\1\16\1\25\1\23\1\0\2\16\1\23"+
    "\1\0\2\16\1\50\1\0\1\16\1\25\1\124\1\0\12\16\1\125\1\126\1\37\1\113\3\0\1"+
    "\127\1\37\1\113\13\16\1\0\5\16\1\36\10\16\1\47\1\0\3\16\1\17\1\16\1\50\1\16"+
    "\1\50\1\67\1\37\3\16\1\47\1\23\1\0\5\16\1\50\3\16\1\22\1\37\1\113\4\0\3\16"+
    "\1\50\7\16\1\17\3\16\1\42\1\37\1\113\1\37\1\113\1\57\1\0\1\16\1\17\10\0\11"+
    "\16\1\50\1\37\1\113\1\0\1\130\1\50\1\0\6\16\1\37\1\46\6\16\1\50\1\0\7\16\1"+
    "\0\1\37\1\131\1\37\1\46\3\16\1\47\1\16\1\72\10\0\1\123\3\16\1\17\1\22\36\16"+
    "\1\47\1\130\42\16\2\47\4\16\2\47\1\16\1\132\3\16\1\47\6\16\1\25\1\111\1\133"+
    "\1\23\1\134\1\50\1\16\1\23\1\133\1\23\5\0\1\135\1\0\1\57\1\72\1\0\1\136\3"+
    "\0\1\34\1\57\2\0\1\16\1\23\6\0\4\16\1\72\1\0\1\110\1\106\1\107\1\137\1\24"+
    "\1\140\1\16\1\55\1\141\1\142\2\0\5\16\1\72\144\0\1\73\6\16\1\22\42\0\5\16"+
    "\1\17\5\16\1\17\20\16\1\23\1\130\1\50\1\0\4\16\1\32\1\15\7\16\1\57\1\0\1\57"+
    "\2\16\1\17\1\0\10\17\4\16\5\0\1\57\72\0\1\141\3\0\1\33\1\16\1\137\1\23\1\33"+
    "\11\16\1\17\1\143\1\33\12\16\1\123\1\141\4\16\1\47\1\33\12\16\1\17\2\0\3\16"+
    "\1\36\6\0\170\16\1\47\11\0\72\16\1\47\5\0\21\16\1\23\10\0\5\16\1\47\41\16"+
    "\1\23\2\16\1\37\1\144\2\0\6\16\1\123\1\32\16\16\1\22\3\0\1\57\1\16\1\106\14"+
    "\16\1\53\3\16\1\17\1\16\7\0\1\57\6\16\3\0\6\16\1\50\1\0\10\16\1\47\1\0\1\37"+
    "\1\113\3\16\1\145\1\37\1\46\3\16\1\47\4\16\1\50\1\0\3\16\1\23\10\16\1\72\1"+
    "\57\1\37\1\113\2\16\1\37\1\146\6\16\1\17\1\0\1\16\1\47\1\37\1\113\2\16\1\17"+
    "\1\106\10\16\1\36\2\0\1\127\2\16\1\147\1\0\3\150\1\0\2\17\5\16\1\123\1\47"+
    "\1\0\17\16\1\151\1\37\1\113\64\16\1\50\1\0\2\16\1\17\1\130\5\16\1\50\40\0"+
    "\55\16\1\47\15\16\1\22\4\0\1\17\1\0\1\130\1\141\1\16\1\43\1\17\1\111\1\152"+
    "\15\16\1\22\3\0\1\130\54\16\1\47\2\0\10\16\1\106\6\16\5\0\1\16\1\50\2\16\2"+
    "\0\2\16\1\100\2\0\1\141\4\0\1\25\20\16\1\23\2\0\1\37\1\113\1\33\2\16\1\62"+
    "\1\33\2\16\1\36\1\73\12\16\1\17\3\106\1\153\4\0\1\16\1\41\2\16\1\17\2\16\1"+
    "\154\1\16\1\47\1\16\1\47\4\0\17\16\1\36\10\0\6\16\1\23\20\0\1\15\20\0\3\16"+
    "\1\23\6\16\1\72\1\0\1\72\3\0\4\16\2\0\3\16\1\36\5\16\1\36\3\16\1\47\4\16\1"+
    "\50\1\16\1\137\5\0\23\16\1\47\1\37\1\113\4\16\1\50\4\16\1\50\5\16\1\0\6\16"+
    "\1\50\23\0\46\16\1\17\1\0\2\16\1\47\1\0\1\16\23\0\1\47\1\43\4\16\1\32\1\155"+
    "\2\16\1\47\1\0\2\16\1\17\1\0\3\16\1\17\10\0\2\16\1\151\1\0\2\16\1\47\1\0\3"+
    "\16\1\22\10\0\7\16\1\73\10\0\1\156\1\51\1\41\1\33\2\16\1\50\1\62\4\0\3\16"+
    "\1\23\3\16\1\23\4\0\1\16\1\33\2\16\1\17\3\0\6\16\1\47\1\0\2\16\1\47\1\0\2"+
    "\16\1\36\1\0\2\16\1\22\15\0\11\16\1\72\6\0\6\16\1\36\1\0\6\16\1\36\41\0\10"+
    "\16\1\17\3\0\1\67\1\37\1\0\1\57\7\16\1\36\2\0\3\16\1\72\1\37\1\113\6\16\1"+
    "\157\1\37\2\0\4\16\1\160\1\0\10\16\1\23\1\153\1\37\1\161\4\0\2\16\1\31\4\16"+
    "\1\27\10\0\1\17\1\140\1\16\1\32\1\16\1\72\7\16\1\36\1\37\1\113\1\41\1\42\1"+
    "\53\2\16\1\43\1\70\1\55\1\42\1\65\1\101\1\141\1\134\2\23\21\0\11\16\1\36\1"+
    "\37\1\113\4\0\10\16\1\32\1\0\1\37\1\113\24\0\6\16\1\47\1\16\1\72\2\0\1\47"+
    "\4\0\10\16\1\162\1\0\1\37\1\113\4\0\7\16\1\0\1\37\1\113\6\0\3\16\1\102\1\16"+
    "\1\50\1\37\1\113\54\0\10\16\1\37\1\113\1\0\1\57\70\0\7\16\1\72\40\0\1\16\1"+
    "\43\4\16\1\17\1\16\1\72\1\0\1\37\1\113\2\0\1\106\3\16\1\106\2\16\1\33\1\17"+
    "\51\0\63\16\1\22\14\0\15\16\1\17\2\0\30\16\1\50\27\0\5\16\1\17\72\0\10\16"+
    "\1\17\67\0\7\16\1\72\3\16\1\17\1\37\1\113\14\0\3\16\1\47\1\23\1\0\6\16\1\17"+
    "\1\0\1\50\1\0\1\37\1\113\1\130\2\16\1\141\2\16\56\0\10\16\1\23\1\0\5\16\1"+
    "\17\1\0\1\57\2\16\10\0\1\72\3\0\75\16\1\23\2\0\36\16\1\36\41\0\1\22\77\0\15"+
    "\16\1\36\1\16\1\23\1\16\1\72\1\16\1\163\130\0\1\141\1\102\1\36\1\130\1\45"+
    "\1\50\3\0\1\164\22\0\1\153\67\0\12\16\1\25\10\16\1\25\1\165\1\166\1\16\1\167"+
    "\1\41\7\16\1\32\1\45\2\25\3\16\1\170\1\111\1\106\1\43\51\16\1\47\3\16\1\43"+
    "\2\16\1\123\3\16\1\123\2\16\1\25\3\16\1\25\2\16\1\17\3\16\1\17\3\16\1\43\3"+
    "\16\1\43\2\16\1\123\1\52\6\37\6\16\1\17\1\130\5\16\1\23\1\15\1\0\1\136\2\0"+
    "\1\130\1\33\1\16\52\0\1\17\2\16\1\53\1\152\1\36\72\0\30\16\1\23\1\0\1\17\5"+
    "\0\11\16\1\36\1\37\1\113\24\0\1\41\3\16\1\114\1\33\1\123\1\171\1\110\1\172"+
    "\1\114\1\132\1\114\2\123\1\66\1\16\1\31\1\16\1\50\1\61\1\31\1\16\1\50\116"+
    "\0\3\16\1\22\3\16\1\22\3\16\1\22\16\0\32\16\1\17\5\0\106\16\1\23\1\0\33\16"+
    "\1\47\120\16\1\22\53\0\3\16\1\47\134\0\36\16\2\0");

  /* The ZZ_CMAP_A table has 984 entries */
  static final char ZZ_CMAP_A[] = zzUnpackCMap(
    "\11\0\1\37\1\2\2\1\1\3\2\0\1\37\1\0\1\23\1\0\1\7\1\14\1\0\1\16\3\0\1\24\1"+
    "\6\1\11\2\0\2\15\10\13\1\5\1\22\1\0\1\32\3\0\5\10\1\27\11\33\1\30\1\33\1\26"+
    "\1\34\4\33\2\25\1\33\1\35\1\17\1\36\1\0\1\4\2\25\1\33\1\20\1\0\1\21\7\0\1"+
    "\1\4\0\1\4\12\0\1\4\2\0\17\4\1\0\7\4\1\31\2\4\4\0\4\4\6\0\5\4\7\0\1\4\1\0"+
    "\1\4\1\0\5\4\1\0\2\4\2\0\4\4\1\0\1\4\6\0\1\4\1\0\3\4\1\0\1\4\1\0\4\4\1\0\13"+
    "\4\1\0\1\4\1\0\7\4\1\0\1\4\7\0\2\4\1\0\2\4\1\0\4\4\5\0\12\12\4\0\6\4\1\0\10"+
    "\4\2\0\2\4\1\0\6\4\2\12\3\4\2\0\4\4\2\0\3\4\2\12\14\4\2\0\4\4\10\0\10\4\2"+
    "\0\2\12\1\4\2\0\6\4\1\0\1\4\3\0\4\4\2\0\5\4\2\0\4\4\10\0\1\4\4\0\2\4\1\0\1"+
    "\4\1\0\3\4\1\0\6\4\4\0\2\4\1\0\2\4\1\0\2\4\1\0\2\4\2\0\1\4\1\0\3\4\2\0\3\4"+
    "\3\0\4\4\1\0\1\4\7\0\2\12\1\4\1\0\2\4\1\0\5\4\1\0\3\4\2\0\1\4\15\0\2\4\2\0"+
    "\2\4\1\0\6\4\3\0\3\4\1\0\4\4\3\0\2\4\1\0\1\4\1\0\2\4\3\0\2\4\3\0\1\4\6\0\3"+
    "\4\3\0\3\4\5\0\2\4\2\0\2\4\5\0\1\4\1\0\5\4\3\0\12\4\1\0\1\4\4\0\1\4\4\0\6"+
    "\4\1\0\1\4\3\0\2\4\4\0\2\12\7\0\2\4\1\0\1\4\2\0\2\4\1\0\1\4\2\0\1\4\3\0\3"+
    "\4\1\0\1\4\1\0\1\4\2\12\2\0\4\4\5\0\1\4\1\0\1\4\1\0\1\4\4\0\2\4\2\12\4\4\2"+
    "\0\3\4\1\0\5\4\1\0\2\4\4\0\4\4\3\0\1\4\4\0\2\4\5\0\3\4\5\0\5\4\2\12\3\0\3"+
    "\4\1\0\1\4\1\0\1\4\1\0\1\4\1\0\1\4\2\0\3\4\1\0\6\4\2\0\2\4\2\1\12\0\1\4\4"+
    "\0\5\4\2\0\1\4\1\0\4\4\1\0\1\4\5\0\5\4\4\0\1\4\2\0\2\4\2\0\3\4\2\12\2\4\7"+
    "\0\1\4\1\0\1\4\2\0\2\12\5\4\3\0\5\4\2\0\6\4\1\0\3\4\1\0\2\4\2\0\2\4\1\0\2"+
    "\4\1\0\2\4\2\0\3\4\3\0\3\4\1\0\2\4\1\0\2\4\3\0\1\4\2\0\5\4\1\0\2\4\1\0\5\4"+
    "\1\0\2\12\4\4\2\0\1\4\1\0\2\12\1\4\1\0\1\4\3\0\1\4\3\0\1\4\3\0\2\4\3\0\2\4"+
    "\3\0\4\4\4\0\1\4\2\0\2\4\2\0\4\4\1\0\4\4\1\0\1\4\1\0\5\4\1\0\4\4\2\0\1\4\1"+
    "\0\1\4\5\0\1\4\1\0\1\4\1\0\3\4");

  /** 
   * Translates DFA states to action switch labels.
   */
  private static final int [] ZZ_ACTION = zzUnpackAction();

  private static final String ZZ_ACTION_PACKED_0 =
    "\4\0\1\1\2\2\1\1\1\3\1\4\1\5\1\6"+
    "\1\7\2\1\1\10\5\1\1\11\2\6\2\1\1\3"+
    "\1\0\1\12\1\0\1\10\1\0\2\10\4\0\1\13"+
    "\2\0\2\11\1\6\7\0\1\14\7\0\1\14\1\11"+
    "\2\10\1\11\1\6\6\0\1\14\1\0\2\14\3\0"+
    "\1\14\4\0\3\14";

  private static int [] zzUnpackAction() {
    int [] result = new int[86];
    int offset = 0;
    offset = zzUnpackAction(ZZ_ACTION_PACKED_0, offset, result);
    return result;
  }

  private static int zzUnpackAction(String packed, int offset, int [] result) {
    int i = 0;       /* index in packed string  */
    int j = offset;  /* index in unpacked array */
    int l = packed.length();
    while (i < l) {
      int count = packed.charAt(i++);
      int value = packed.charAt(i++);
      do result[j++] = value; while (--count > 0);
    }
    return j;
  }


  /** 
   * Translates a state to a row index in the transition table
   */
  private static final int [] ZZ_ROWMAP = zzUnpackRowMap();

  private static final String ZZ_ROWMAP_PACKED_0 =
    "\0\0\0\40\0\100\0\140\0\200\0\200\0\240\0\300"+
    "\0\340\0\u0100\0\u0120\0\u0140\0\200\0\u0160\0\u0180\0\u01a0"+
    "\0\u01c0\0\u01e0\0\u0200\0\u0220\0\u0240\0\u0260\0\u0280\0\u02a0"+
    "\0\u02c0\0\u02e0\0\u0300\0\300\0\200\0\u0320\0\u0160\0\u0340"+
    "\0\u0360\0\u01c0\0\u0380\0\u03a0\0\u03c0\0\u0220\0\u0220\0\u03e0"+
    "\0\u0400\0\u0280\0\u0140\0\u02c0\0\u0420\0\u0440\0\u0460\0\u0480"+
    "\0\u04a0\0\u04c0\0\u04e0\0\u0500\0\u0520\0\u0540\0\u0560\0\u0580"+
    "\0\u05a0\0\u05c0\0\u05e0\0\u0600\0\u0620\0\200\0\u0380\0\200"+
    "\0\200\0\u0640\0\u0660\0\u0680\0\u06a0\0\u06c0\0\u06e0\0\u0520"+
    "\0\u0700\0\u0720\0\u0560\0\u0740\0\u0760\0\u0780\0\u05c0\0\u07a0"+
    "\0\u07c0\0\u07e0\0\u0800\0\u0820\0\200\0\u0740";

  private static int [] zzUnpackRowMap() {
    int [] result = new int[86];
    int offset = 0;
    offset = zzUnpackRowMap(ZZ_ROWMAP_PACKED_0, offset, result);
    return result;
  }

  private static int zzUnpackRowMap(String packed, int offset, int [] result) {
    int i = 0;  /* index in packed string  */
    int j = offset;  /* index in unpacked array */
    int l = packed.length();
    while (i < l) {
      int high = packed.charAt(i++) << 16;
      result[j++] = high | packed.charAt(i++);
    }
    return j;
  }

  /** 
   * The transition table of the DFA
   */
  private static final int [] ZZ_TRANS = zzUnpackTrans();

  private static final String ZZ_TRANS_PACKED_0 =
    "\1\5\2\6\1\7\1\10\3\5\1\11\1\5\2\10"+
    "\1\5\1\10\4\5\1\12\2\5\4\11\1\10\1\5"+
    "\2\11\2\5\1\13\1\5\2\6\1\7\16\5\1\12"+
    "\14\5\1\13\1\5\2\6\1\7\1\14\1\5\1\15"+
    "\1\16\1\14\1\17\2\20\1\21\1\20\1\22\1\5"+
    "\1\23\1\5\1\12\1\24\1\25\1\26\1\27\1\30"+
    "\1\14\1\30\1\31\1\14\1\30\1\32\1\5\1\13"+
    "\1\5\2\6\1\7\4\5\1\33\11\5\1\12\2\5"+
    "\4\33\2\5\2\33\2\5\1\13\42\0\1\6\41\0"+
    "\1\34\1\35\2\0\1\34\1\0\2\34\1\0\1\34"+
    "\7\0\5\34\1\0\2\34\7\0\1\34\1\35\2\0"+
    "\1\11\1\0\2\34\1\0\1\34\7\0\4\11\1\34"+
    "\1\0\2\11\3\0\2\12\2\0\34\12\37\0\1\13"+
    "\4\0\1\14\3\0\1\14\1\0\2\14\1\0\1\14"+
    "\7\0\5\14\1\36\2\14\13\0\1\37\2\0\1\37"+
    "\1\0\1\37\11\0\1\37\21\0\1\40\2\41\1\0"+
    "\1\41\26\0\1\14\3\0\1\14\1\0\2\20\1\0"+
    "\1\20\7\0\5\14\1\36\2\14\20\0\1\42\22\0"+
    "\1\43\3\0\13\43\1\44\20\43\4\0\1\45\3\0"+
    "\1\45\1\0\2\45\1\0\1\45\7\0\5\45\1\0"+
    "\2\45\3\0\1\46\3\0\17\46\1\47\14\46\24\0"+
    "\1\40\17\0\1\14\3\0\1\14\1\50\2\14\1\0"+
    "\1\14\6\0\1\51\5\14\1\36\2\14\7\0\1\14"+
    "\3\0\1\14\1\0\1\14\1\52\1\0\1\52\7\0"+
    "\5\14\1\36\2\14\7\0\1\14\3\0\1\14\1\0"+
    "\2\14\1\0\1\14\7\0\3\14\1\53\1\14\1\36"+
    "\2\14\7\0\1\54\3\0\1\54\1\0\2\54\1\0"+
    "\1\54\7\0\5\54\1\0\2\54\7\0\1\55\2\0"+
    "\1\56\1\55\1\57\2\60\1\61\1\60\1\62\1\0"+
    "\1\63\4\0\5\55\1\0\2\55\13\0\1\33\14\0"+
    "\4\33\2\0\2\33\7\0\1\64\2\0\1\65\1\64"+
    "\1\66\2\64\1\67\1\64\1\70\1\0\1\71\2\0"+
    "\1\72\1\73\1\74\4\64\1\0\2\64\30\0\1\75"+
    "\24\0\2\41\1\0\1\41\40\0\1\76\21\0\1\43"+
    "\3\0\12\43\1\77\21\43\4\0\1\45\3\0\1\45"+
    "\1\0\2\45\1\0\1\45\3\0\1\76\3\0\5\45"+
    "\1\0\2\45\14\0\1\100\52\0\1\100\17\0\1\55"+
    "\3\0\1\55\1\0\2\55\1\0\1\55\7\0\5\55"+
    "\1\0\2\55\1\0\1\101\11\0\1\102\2\0\1\102"+
    "\1\0\1\102\11\0\1\102\22\0\2\103\1\0\1\103"+
    "\26\0\1\55\3\0\1\55\1\0\2\60\1\0\1\60"+
    "\7\0\5\55\1\0\2\55\1\0\1\76\16\0\1\104"+
    "\22\0\1\105\3\0\13\105\1\106\20\105\4\0\1\107"+
    "\3\0\1\107\1\0\2\107\1\0\1\107\7\0\5\107"+
    "\1\0\2\107\7\0\1\64\3\0\1\64\1\0\2\64"+
    "\1\0\1\64\7\0\5\64\1\0\2\64\13\0\1\110"+
    "\2\0\1\110\1\0\1\110\11\0\1\110\21\0\1\111"+
    "\2\112\1\0\1\112\37\0\1\113\22\0\1\114\3\0"+
    "\13\114\1\115\20\114\4\0\1\116\3\0\1\116\1\0"+
    "\2\116\1\0\1\116\7\0\5\116\1\0\2\116\3\0"+
    "\1\72\3\0\17\72\1\117\14\72\24\0\1\111\17\0"+
    "\1\64\3\0\1\64\1\120\2\64\1\0\1\64\6\0"+
    "\1\121\5\64\1\0\2\64\14\0\1\50\12\0\1\51"+
    "\23\0\1\102\2\0\1\102\1\0\1\102\11\0\1\102"+
    "\6\0\1\76\13\0\2\103\1\0\1\103\20\0\1\76"+
    "\16\0\1\104\20\0\1\76\17\0\1\122\21\0\1\105"+
    "\3\0\12\105\1\123\21\105\4\0\1\107\3\0\1\107"+
    "\1\0\2\107\1\0\1\107\3\0\1\122\3\0\5\107"+
    "\1\0\2\107\30\0\1\124\24\0\2\112\1\0\1\112"+
    "\40\0\1\125\21\0\1\114\3\0\12\114\1\126\21\114"+
    "\4\0\1\116\3\0\1\116\1\0\2\116\1\0\1\116"+
    "\3\0\1\125\3\0\5\116\1\0\2\116\14\0\1\125"+
    "\52\0\1\125\51\0\1\76\17\0\1\122\17\0\1\76"+
    "\12\0\1\120\12\0\1\121\13\0";

  private static int [] zzUnpackTrans() {
    int [] result = new int[2112];
    int offset = 0;
    offset = zzUnpackTrans(ZZ_TRANS_PACKED_0, offset, result);
    return result;
  }

  private static int zzUnpackTrans(String packed, int offset, int [] result) {
    int i = 0;       /* index in packed string  */
    int j = offset;  /* index in unpacked array */
    int l = packed.length();
    while (i < l) {
      int count = packed.charAt(i++);
      int value = packed.charAt(i++);
      value--;
      do result[j++] = value; while (--count > 0);
    }
    return j;
  }


  /* error codes */
  private static final int ZZ_UNKNOWN_ERROR = 0;
  private static final int ZZ_NO_MATCH = 1;
  private static final int ZZ_PUSHBACK_2BIG = 2;

  /* error messages for the codes above */
  private static final String[] ZZ_ERROR_MSG = {
    "Unknown internal scanner error",
    "Error: could not match input",
    "Error: pushback value was too large"
  };

  /**
   * ZZ_ATTRIBUTE[aState] contains the attributes of state <code>aState</code>
   */
  private static final int [] ZZ_ATTRIBUTE = zzUnpackAttribute();

  private static final String ZZ_ATTRIBUTE_PACKED_0 =
    "\4\0\2\11\6\1\1\11\16\1\1\0\1\11\1\0"+
    "\1\1\1\0\2\1\4\0\1\1\2\0\3\1\7\0"+
    "\1\1\7\0\2\1\1\11\1\1\2\11\6\0\1\1"+
    "\1\0\2\1\3\0\1\1\4\0\1\1\1\11\1\1";

  private static int [] zzUnpackAttribute() {
    int [] result = new int[86];
    int offset = 0;
    offset = zzUnpackAttribute(ZZ_ATTRIBUTE_PACKED_0, offset, result);
    return result;
  }

  private static int zzUnpackAttribute(String packed, int offset, int [] result) {
    int i = 0;       /* index in packed string  */
    int j = offset;  /* index in unpacked array */
    int l = packed.length();
    while (i < l) {
      int count = packed.charAt(i++);
      int value = packed.charAt(i++);
      do result[j++] = value; while (--count > 0);
    }
    return j;
  }

  /** the input device */
  private java.io.Reader zzReader;

  /** the current state of the DFA */
  private int zzState;

  /** the current lexical state */
  private int zzLexicalState = YYINITIAL;

  /** this buffer contains the current text to be matched and is
      the source of the yytext() string */
  private CharSequence zzBuffer = "";

  /** the textposition at the last accepting state */
  private int zzMarkedPos;

  /** the current text position in the buffer */
  private int zzCurrentPos;

  /** startRead marks the beginning of the yytext() string in the buffer */
  private int zzStartRead;

  /** endRead marks the last character in the buffer, that has been read
      from input */
  private int zzEndRead;

  /**
   * zzAtBOL == true <=> the scanner is currently at the beginning of a line
   */
  private boolean zzAtBOL = true;

  /** zzAtEOF == true <=> the scanner is at the EOF */
  private boolean zzAtEOF;

  /** denotes if the user-EOF-code has already been executed */
  private boolean zzEOFDone;


  /**
   * Creates a new scanner
   *
   * @param   in  the java.io.Reader to read input from.
   */
  AssemblyLexer(java.io.Reader in) {
    this.zzReader = in;
  }


  /** 
   * Unpacks the compressed character translation table.
   *
   * @param packed   the packed character translation table
   * @return         the unpacked character translation table
   */
  private static char [] zzUnpackCMap(String packed) {
    int size = 0;
    for (int i = 0, length = packed.length(); i < length; i += 2) {
      size += packed.charAt(i);
    }
    char[] map = new char[size];
    int i = 0;  /* index in packed string  */
    int j = 0;  /* index in unpacked array */
    while (i < packed.length()) {
      int  count = packed.charAt(i++);
      char value = packed.charAt(i++);
      do map[j++] = value; while (--count > 0);
    }
    return map;
  }

  public final int getTokenStart() {
    return zzStartRead;
  }

  public final int getTokenEnd() {
    return getTokenStart() + yylength();
  }

  public void reset(CharSequence buffer, int start, int end, int initialState) {
    zzBuffer = buffer;
    zzCurrentPos = zzMarkedPos = zzStartRead = start;
    zzAtEOF  = false;
    zzAtBOL = true;
    zzEndRead = end;
    yybegin(initialState);
  }

  /**
   * Refills the input buffer.
   *
   * @return      {@code false}, iff there was new input.
   *
   * @exception   java.io.IOException  if any I/O-Error occurs
   */
  private boolean zzRefill() throws java.io.IOException {
    return true;
  }


  /**
   * Returns the current lexical state.
   */
  public final int yystate() {
    return zzLexicalState;
  }


  /**
   * Enters a new lexical state
   *
   * @param newState the new lexical state
   */
  public final void yybegin(int newState) {
    zzLexicalState = newState;
  }


  /**
   * Returns the text matched by the current regular expression.
   */
  public final CharSequence yytext() {
    return zzBuffer.subSequence(zzStartRead, zzMarkedPos);
  }


  /**
   * Returns the character at position {@code pos} from the
   * matched text.
   *
   * It is equivalent to yytext().charAt(pos), but faster
   *
   * @param pos the position of the character to fetch.
   *            A value from 0 to yylength()-1.
   *
   * @return the character at position pos
   */
  public final char yycharat(int pos) {
    return zzBuffer.charAt(zzStartRead+pos);
  }


  /**
   * Returns the length of the matched text region.
   */
  public final int yylength() {
    return zzMarkedPos-zzStartRead;
  }


  /**
   * Reports an error that occurred while scanning.
   *
   * In a wellformed scanner (no or only correct usage of
   * yypushback(int) and a match-all fallback rule) this method
   * will only be called with things that "Can't Possibly Happen".
   * If this method is called, something is seriously wrong
   * (e.g. a JFlex bug producing a faulty scanner etc.).
   *
   * Usual syntax/scanner level error handling should be done
   * in error fallback rules.
   *
   * @param   errorCode  the code of the errormessage to display
   */
  private void zzScanError(int errorCode) {
    String message;
    try {
      message = ZZ_ERROR_MSG[errorCode];
    }
    catch (ArrayIndexOutOfBoundsException e) {
      message = ZZ_ERROR_MSG[ZZ_UNKNOWN_ERROR];
    }

    throw new Error(message);
  }


  /**
   * Pushes the specified amount of characters back into the input stream.
   *
   * They will be read again by then next call of the scanning method
   *
   * @param number  the number of characters to be read again.
   *                This number must not be greater than yylength()!
   */
  public void yypushback(int number)  {
    if ( number > yylength() )
      zzScanError(ZZ_PUSHBACK_2BIG);

    zzMarkedPos -= number;
  }


  /**
   * Contains user EOF-code, which will be executed exactly once,
   * when the end of file is reached
   */
  private void zzDoEOF() {
    if (!zzEOFDone) {
      zzEOFDone = true;
    
    }
  }


  /**
   * Resumes scanning until the next regular expression is matched,
   * the end of input is encountered or an I/O-Error occurs.
   *
   * @return      the next token
   * @exception   java.io.IOException  if any I/O-Error occurs
   */
  public IElementType advance() throws java.io.IOException {
    int zzInput;
    int zzAction;

    // cached fields:
    int zzCurrentPosL;
    int zzMarkedPosL;
    int zzEndReadL = zzEndRead;
    CharSequence zzBufferL = zzBuffer;

    int [] zzTransL = ZZ_TRANS;
    int [] zzRowMapL = ZZ_ROWMAP;
    int [] zzAttrL = ZZ_ATTRIBUTE;

    while (true) {
      zzMarkedPosL = zzMarkedPos;

      zzAction = -1;

      zzCurrentPosL = zzCurrentPos = zzStartRead = zzMarkedPosL;

      zzState = ZZ_LEXSTATE[zzLexicalState];

      // set up zzAction for empty match case:
      int zzAttributes = zzAttrL[zzState];
      if ( (zzAttributes & 1) == 1 ) {
        zzAction = zzState;
      }


      zzForAction: {
        while (true) {

          if (zzCurrentPosL < zzEndReadL) {
            zzInput = Character.codePointAt(zzBufferL, zzCurrentPosL/*, zzEndReadL*/);
            zzCurrentPosL += Character.charCount(zzInput);
          }
          else if (zzAtEOF) {
            zzInput = YYEOF;
            break zzForAction;
          }
          else {
            // store back cached positions
            zzCurrentPos  = zzCurrentPosL;
            zzMarkedPos   = zzMarkedPosL;
            boolean eof = zzRefill();
            // get translated positions and possibly new buffer
            zzCurrentPosL  = zzCurrentPos;
            zzMarkedPosL   = zzMarkedPos;
            zzBufferL      = zzBuffer;
            zzEndReadL     = zzEndRead;
            if (eof) {
              zzInput = YYEOF;
              break zzForAction;
            }
            else {
              zzInput = Character.codePointAt(zzBufferL, zzCurrentPosL/*, zzEndReadL*/);
              zzCurrentPosL += Character.charCount(zzInput);
            }
          }
          int zzNext = zzTransL[ zzRowMapL[zzState] + ZZ_CMAP(zzInput) ];
          if (zzNext == -1) break zzForAction;
          zzState = zzNext;

          zzAttributes = zzAttrL[zzState];
          if ( (zzAttributes & 1) == 1 ) {
            zzAction = zzState;
            zzMarkedPosL = zzCurrentPosL;
            if ( (zzAttributes & 8) == 8 ) break zzForAction;
          }

        }
      }

      // store back cached position
      zzMarkedPos = zzMarkedPosL;

      if (zzInput == YYEOF && zzStartRead == zzCurrentPos) {
        zzAtEOF = true;
        zzDoEOF();
        return null;
      }
      else {
        switch (zzAction < 0 ? zzAction : ZZ_ACTION[zzAction]) {
          case 1: 
            { yybegin(ERROR); return TokenType.BAD_CHARACTER;
            } 
            // fall through
          case 13: break;
          case 2: 
            { yybegin(YYINITIAL); return AssemblyTypes.CRLF;
            } 
            // fall through
          case 14: break;
          case 3: 
            { yybegin(OPERANDS); return AssemblyTypes.MNEMONIC;
            } 
            // fall through
          case 15: break;
          case 4: 
            { yybegin(YYINITIAL); return AssemblyTypes.COMMENT;
            } 
            // fall through
          case 16: break;
          case 5: 
            { return TokenType.WHITE_SPACE;
            } 
            // fall through
          case 17: break;
          case 6: 
            { return AssemblyTypes.LABEL;
            } 
            // fall through
          case 18: break;
          case 7: 
            { return AssemblyTypes.SEPARATOR;
            } 
            // fall through
          case 19: break;
          case 8: 
            { return AssemblyTypes.CONSTANT;
            } 
            // fall through
          case 20: break;
          case 9: 
            { return AssemblyTypes.REGISTER;
            } 
            // fall through
          case 21: break;
          case 10: 
            { yybegin(LABELED); return AssemblyTypes.LABEL_DEF;
            } 
            // fall through
          case 22: break;
          case 11: 
            { return AssemblyTypes.STRING;
            } 
            // fall through
          case 23: break;
          case 12: 
            { return AssemblyTypes.DEFINITION;
            } 
            // fall through
          case 24: break;
          default:
            zzScanError(ZZ_NO_MATCH);
          }
      }
    }
  }


}