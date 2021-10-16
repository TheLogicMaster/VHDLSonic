package com.thelogicmaster.vhdl_sonic.psi;

import com.intellij.psi.tree.IElementType;
import com.thelogicmaster.vhdl_sonic.AssemblyLanguage;
import org.jetbrains.annotations.NonNls;
import org.jetbrains.annotations.NotNull;

public class AssemblyTokenType extends IElementType {
	public AssemblyTokenType(@NotNull @NonNls String debugName) {
		super(debugName, AssemblyLanguage.INSTANCE);
	}

	@Override
	public String toString() {
		return "AssemblyTokenType." + super.toString();
	}
}
