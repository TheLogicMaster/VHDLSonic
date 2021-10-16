package com.thelogicmaster.vhdl_sonic.psi;

import com.intellij.psi.tree.IElementType;
import com.thelogicmaster.vhdl_sonic.AssemblyLanguage;
import org.jetbrains.annotations.NonNls;
import org.jetbrains.annotations.NotNull;

public class AssemblyElementType extends IElementType {

	public AssemblyElementType(@NotNull @NonNls String debugName) {
		super(debugName, AssemblyLanguage.INSTANCE);
	}
}
