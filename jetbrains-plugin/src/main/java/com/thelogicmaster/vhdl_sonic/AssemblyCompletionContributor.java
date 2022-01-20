package com.thelogicmaster.vhdl_sonic;

import com.intellij.codeInsight.completion.CompletionContributor;
import com.intellij.codeInsight.completion.CompletionParameters;
import com.intellij.codeInsight.completion.CompletionResultSet;
import com.intellij.codeInsight.lookup.LookupElementBuilder;
import com.intellij.psi.PsiElement;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyInstructionElement;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyLabelDefinition;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyTypes;
import org.jetbrains.annotations.NotNull;

import java.util.ArrayList;
import java.util.regex.Pattern;

public class AssemblyCompletionContributor extends CompletionContributor {

	private static void fillRegisterVariants(CompletionResultSet result) {
		for (String register: "x,y,sp,fp".split(","))
			result.addElement(LookupElementBuilder.create(register).withCaseSensitivity(false));
		for (int i = 0; i < 16; i++)
			result.addElement(LookupElementBuilder.create("r" + i).withCaseSensitivity(false));
	}

	private static void fillLabelVariants(CompletionParameters parameters, CompletionResultSet result, boolean loadOrStore) {
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

		if (parameter == 0) {
			if (Pattern.matches("^(ldr|ldw|ldb|str|stw|stb|tfr|inc|dec|mul|add|adc|sub|sbc|and|or|xor|lsl|asr|lsr|cmp|push|pop|jmp)$", mnemonic))
				fillRegisterVariants(result);
			if (Pattern.matches("^(jmp|jsr|beq|bne|bhs|blo|bmi|bpl|bvs|bvc|bhi|bls|bge|blt|bgt|ble|bra)$", mnemonic))
				fillLabelVariants(parameters, result, false);
		} else if (parameter == 1) {
			if (Pattern.matches("^(ldr|ldw|ldb|str|stw|stb|tfr|mul|add|adc|sub|sbc|and|or|xor|lsl|asr|lsr|cmp)$", mnemonic))
				fillRegisterVariants(result);
			if (Pattern.matches("^(ldr|ldw|ldb|str|stw|stb)$", mnemonic))
				fillLabelVariants(parameters, result, true);
		}
	}
}
