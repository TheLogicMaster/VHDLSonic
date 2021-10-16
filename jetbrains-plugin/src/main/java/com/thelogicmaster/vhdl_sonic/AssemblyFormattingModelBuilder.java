package com.thelogicmaster.vhdl_sonic;

import com.intellij.formatting.Alignment;
import com.intellij.formatting.FormattingContext;
import com.intellij.formatting.FormattingModel;
import com.intellij.formatting.FormattingModelBuilder;
import com.intellij.formatting.FormattingModelProvider;
import com.intellij.formatting.SpacingBuilder;
import com.intellij.formatting.Wrap;
import com.intellij.formatting.WrapType;
import com.intellij.psi.codeStyle.CodeStyleSettings;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyTypes;
import org.jetbrains.annotations.NotNull;

public class AssemblyFormattingModelBuilder implements FormattingModelBuilder {

	private static SpacingBuilder createSpaceBuilder(CodeStyleSettings settings) {
		return new SpacingBuilder(settings, AssemblyLanguage.INSTANCE)
			.after(AssemblyTypes.SEPARATOR)
			.none()

			.between(AssemblyTypes.LABEL_DEFINITION, AssemblyTypes.INSTRUCTION)
			.spaces(1)

			.before(AssemblyTypes.INSTRUCTION)
			.spaces(4)

			.between(AssemblyTypes.LABEL_DEFINITION, AssemblyTypes.COMMENT)
			.spaces(1)

			.between(AssemblyTypes.INSTRUCTION, AssemblyTypes.COMMENT)
			.spaces(1)

			.after(AssemblyTypes.MNEMONIC)
			.spaces(1)

			.before(AssemblyTypes.COMMENT)
			.none()

			.before(AssemblyTypes.LABEL_DEFINITION)
			.none()

			.after(AssemblyTypes.LABEL_DEFINITION)
			.none()

			.before(AssemblyTypes.CRLF)
			.none();
	}

	@Override
	public @NotNull FormattingModel createModel (@NotNull FormattingContext formattingContext) {
		return FormattingModelProvider.createFormattingModelForPsiFile(
			formattingContext.getContainingFile(),
			new AssemblyBlock(formattingContext.getNode(), Wrap.createWrap(WrapType.NONE, false), Alignment.createAlignment(true), createSpaceBuilder(formattingContext.getCodeStyleSettings())),
			formattingContext.getCodeStyleSettings()
		);
	}
}
