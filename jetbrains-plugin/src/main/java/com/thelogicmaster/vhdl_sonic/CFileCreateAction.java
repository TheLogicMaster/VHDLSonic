package com.thelogicmaster.vhdl_sonic;

import com.intellij.ide.actions.CreateFileFromTemplateAction;
import com.intellij.ide.actions.CreateFileFromTemplateDialog;
import com.intellij.openapi.project.Project;
import com.intellij.psi.PsiDirectory;
import org.jetbrains.annotations.NotNull;

public class CFileCreateAction extends CreateFileFromTemplateAction {

	private static final String NAME = "Create C Program";

	public CFileCreateAction () {
		super(NAME, "Create a C program file", AssemblyIcons.LOGO);
	}

	@Override
	protected void buildDialog(@NotNull Project project, @NotNull PsiDirectory directory, CreateFileFromTemplateDialog.Builder builder) {
		builder
			.setTitle(NAME)
			.addKind("", AssemblyIcons.LOGO, "C Program");
	}

	@Override
	protected String getActionName(PsiDirectory directory, @NotNull String newName, String templateName) {
		return NAME;
	}
}
