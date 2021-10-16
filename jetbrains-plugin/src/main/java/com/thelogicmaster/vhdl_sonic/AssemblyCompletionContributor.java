package com.thelogicmaster.vhdl_sonic;

import com.intellij.codeInsight.completion.CompletionContributor;
import com.intellij.codeInsight.completion.CompletionParameters;
import com.intellij.codeInsight.completion.CompletionResultSet;
import com.intellij.codeInsight.lookup.LookupElementBuilder;
import com.intellij.psi.PsiElement;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyInstructionElement;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyTypes;
import org.jetbrains.annotations.NotNull;

public class AssemblyCompletionContributor extends CompletionContributor {

//	private static void fillRegisterVariants(CompletionResultSet result) {
//		for (String register: "A,B,H,L".split(","))
//			result.addElement(LookupElementBuilder.create(register).withCaseSensitivity(false));
//	}

	@Override
	public void fillCompletionVariants (@NotNull CompletionParameters parameters, @NotNull CompletionResultSet result) {
		PsiElement pos = parameters.getPosition();
		PsiElement orig = parameters.getOriginalPosition();
		if (orig == null)
			return;
		if (pos.getNode().getElementType() == AssemblyTypes.MNEMONIC)
			for (String instruction: AssemblyLanguage.INSTRUCTIONS)
				result.addElement(LookupElementBuilder.create(instruction).withCaseSensitivity(false));

		PsiElement parent = pos.getParent();
		if (!(parent instanceof AssemblyInstructionElement))
			return;
		AssemblyInstructionElement instruction = ((AssemblyInstructionElement)parent);
		String mnemonic = instruction.getMnemonic();

		int parameter = 0;
		PsiElement prev = pos.getPrevSibling();
		while (prev != null) {
			if (prev.getNode().getElementType() == AssemblyTypes.SEPARATOR)
				parameter++;
			prev = prev.getPrevSibling();
		}

		/*if (parameter == 0) {
			if (Pattern.matches("^(ldr|str|jmp|jsr)$", mnemonic)) {
				boolean loadOrStore = Pattern.matches("^(ldr|str)$", mnemonic);

				ArrayList<AssemblyLabelDefinition> labels = new ArrayList<>();
				AssemblyLanguage.collectVisibleLabels(parameters.getOriginalFile(), labels);
				for (AssemblyLabelDefinition label: labels) {
					String name = label.getName();
					if (name == null || name.endsWith("_"))
						continue;
					if (loadOrStore)
						name = "[" + name + "]";
					result.addElement(LookupElementBuilder.create(name).withCaseSensitivity(false));
				}
			}

			if (Pattern.matches("^(inc|dec|add|adc|sub|sbc|and|or|xor|cmp|in|out)$", mnemonic))
				fillRegisterVariants(result);
		} else if (parameter == 1) {
			if (Pattern.matches("^(jr)$", mnemonic))
				for (String register: "Z,C,N,V,nZ,nC,nN,nV".split(","))
					result.addElement(LookupElementBuilder.create(register).withCaseSensitivity(false));

			if (Pattern.matches("^(ldr|str|lda|in|out)$", mnemonic))
				fillRegisterVariants(result);
		}*/
	}
}
