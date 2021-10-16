package com.thelogicmaster.vhdl_sonic;

import com.intellij.lexer.FlexAdapter;

public class AssemblyLexerAdaptor extends FlexAdapter {

	public AssemblyLexerAdaptor() {
		super(new AssemblyLexer(null));
	}
}
