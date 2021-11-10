package com.thelogicmaster.vhdl_sonic;

import com.intellij.lexer.FlexLexer;
import com.intellij.psi.tree.IElementType;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyTypes;
import com.intellij.psi.TokenType;

%%

%class AssemblyLexer
%implements FlexLexer
%unicode
%ignorecase
%function advance
%type IElementType
%eof{  return;
%eof}

CRLF=\R
LABEL=\w+
LABEL_DEF={LABEL}:
SEPARATOR=,
HEX_CONSTANT=\$[0-9a-fA-F]+
DECIMAL_CONSTANT=-?\d+
BINARY_CONSTANT=%[01]+
CHAR_CONSTANT=\'\\?.\'
PORT_CONSTANT=\{\w+}
CONSTANTS={HEX_CONSTANT}|{DECIMAL_CONSTANT}|{BINARY_CONSTANT}|{CHAR_CONSTANT}|{PORT_CONSTANT}
COMMENT=;[^\r\n]*
STRING=\".*\"
INC_DEC=\+\+|--
REGISTERS=r[0-9]+|x|y|fp|sp
REGISTER={INC_DEC}?{REGISTERS}{INC_DEC}?
DEFINITION=\w+=({CONSTANTS}|{LABEL}|{STRING}|{REGISTER})

%state ERROR OPERANDS LABELED

%%

// Reset on newline
{CRLF}                                                  { yybegin(YYINITIAL); return AssemblyTypes.CRLF; }

{COMMENT}                                               { yybegin(YYINITIAL); return AssemblyTypes.COMMENT; }

<YYINITIAL> {LABEL_DEF}                                 { yybegin(LABELED); return AssemblyTypes.LABEL_DEF; }

// Separate case to ensure one label per line
<LABELED> [a-zA-Z]+                                     { yybegin(OPERANDS); return AssemblyTypes.MNEMONIC; }

<YYINITIAL> [a-zA-Z]+                                   { yybegin(OPERANDS); return AssemblyTypes.MNEMONIC; }

<OPERANDS> {
    {SEPARATOR}                                         { return AssemblyTypes.SEPARATOR; }
    {DEFINITION}                                        { return AssemblyTypes.DEFINITION; }
    \[{CONSTANTS}\]|{CONSTANTS}                         { return AssemblyTypes.CONSTANT; }
    {REGISTER}                                          { return AssemblyTypes.REGISTER; }
    {STRING}                                            { return AssemblyTypes.STRING; }
    \[{LABEL}\]|=?{LABEL}                               { return AssemblyTypes.LABEL; }
}

// Catch extra whitespace
[\ \t]+                                                 { return TokenType.WHITE_SPACE; }

// Anything not matched is not allowed
[^]                                                     { yybegin(ERROR); return TokenType.BAD_CHARACTER; }
