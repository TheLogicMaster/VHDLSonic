package com.thelogicmaster.vhdl_sonic.psi;

import com.intellij.lang.ASTNode;
import com.intellij.model.psi.PsiExternalReferenceHost;
import com.intellij.psi.PsiElement;

public interface AssemblyInstructionElement extends PsiElement, PsiExternalReferenceHost {

	String getMnemonic();
	ASTNode getLabelNode();
}
