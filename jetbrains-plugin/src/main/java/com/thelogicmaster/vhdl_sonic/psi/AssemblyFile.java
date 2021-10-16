package com.thelogicmaster.vhdl_sonic.psi;

import com.intellij.extapi.psi.PsiFileBase;
import com.intellij.openapi.fileTypes.FileType;
import com.intellij.psi.FileViewProvider;
import com.thelogicmaster.vhdl_sonic.AssemblyFileType;
import com.thelogicmaster.vhdl_sonic.AssemblyLanguage;
import org.jetbrains.annotations.NotNull;

public class AssemblyFile extends PsiFileBase {
	public AssemblyFile(@NotNull FileViewProvider viewProvider) {
		super(viewProvider, AssemblyLanguage.INSTANCE);
	}

	@NotNull
	@Override
	public FileType getFileType() {
		return AssemblyFileType.INSTANCE;
	}

	@Override
	public String toString() {
		return "Assembly File";
	}
}
