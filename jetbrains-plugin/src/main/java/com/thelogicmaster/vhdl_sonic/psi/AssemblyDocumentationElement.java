package com.thelogicmaster.vhdl_sonic.psi;

import com.intellij.navigation.ItemPresentation;
import com.intellij.psi.PsiElement;
import com.intellij.psi.impl.FakePsiElement;
import org.jetbrains.annotations.NonNls;
import org.jetbrains.annotations.Nullable;

public class AssemblyDocumentationElement extends FakePsiElement {
	private final PsiElement element;
	private final String documentation;

	public AssemblyDocumentationElement(PsiElement element, String documentation) {
		this.element = element;
		this.documentation = documentation;
	}

	@Override
	public PsiElement getParent() {
		return element;
	}

	@Nullable
	public String getDocumentation() {
		return documentation;
	}

	@Override
	public @Nullable @NonNls String getText () {
		return documentation;
	}
}
