package com.thelogicmaster.vhdl_sonic;

import com.intellij.codeInspection.ProblemHighlightType;
import com.intellij.lang.ASTNode;
import com.intellij.lang.annotation.AnnotationHolder;
import com.intellij.lang.annotation.Annotator;
import com.intellij.lang.annotation.HighlightSeverity;
import com.intellij.psi.PsiElement;
import com.intellij.psi.tree.TokenSet;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyElementFactory;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyInstructionElement;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyLabelDefinition;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyTypes;
import org.jetbrains.annotations.NotNull;

import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.regex.Pattern;

public class AssemblyAnnotator implements Annotator {

	private static final TokenSet[] INHERENT_OPERANDS = new TokenSet[]{};
	private static final TokenSet[] REGISTER_OPERANDS = new TokenSet[]{
		TokenSet.create(AssemblyTypes.REGISTER)
	};
	private static final TokenSet[] REGISTER_REGISTER_OPERANDS = new TokenSet[]{
		TokenSet.create(AssemblyTypes.REGISTER),
		TokenSet.create(AssemblyTypes.REGISTER)
	};
	private static final TokenSet[] CONSTANT_OPERANDS = new TokenSet[]{
		TokenSet.create(AssemblyTypes.CONSTANT)
	};
	private static final TokenSet[] ADDRESS_OPERANDS = new TokenSet[]{
		TokenSet.create(AssemblyTypes.CONSTANT, AssemblyTypes.LABEL)
	};
	private static final TokenSet[] REGISTER_OR_ADDRESS_OPERANDS = new TokenSet[]{
		TokenSet.create(AssemblyTypes.REGISTER, AssemblyTypes.CONSTANT, AssemblyTypes.LABEL)
	};
	private static final TokenSet[] ARITHMETIC_OPERANDS = new TokenSet[]{
		TokenSet.create(AssemblyTypes.REGISTER),
		TokenSet.create(AssemblyTypes.CONSTANT, AssemblyTypes.REGISTER)
	};
	private static final TokenSet[] MEMORY_OPERANDS = new TokenSet[]{
		TokenSet.create(AssemblyTypes.REGISTER),
		TokenSet.create(AssemblyTypes.CONSTANT, AssemblyTypes.LABEL, AssemblyTypes.REGISTER)
	};
	private static final TokenSet[] RELATIVE_MEMORY_OPERANDS = new TokenSet[]{
		TokenSet.create(AssemblyTypes.REGISTER),
		TokenSet.create(AssemblyTypes.REGISTER),
		TokenSet.create(AssemblyTypes.CONSTANT)
	};
	private static final TokenSet[] DEFINITION_OPERANDS = new TokenSet[]{
		TokenSet.create(AssemblyTypes.DEFINITION)
	};

	private static final String INVALID_OPERANDS = "Invalid operands";

	private static final TokenSet OPERAND_TOKEN_SET = TokenSet.andNot(TokenSet.ANY,
		TokenSet.orSet(TokenSet.WHITE_SPACE, TokenSet.create(AssemblyTypes.MNEMONIC, AssemblyTypes.SEPARATOR)));

	private void annotateInstructionError(String error, AssemblyInstructionElement instruction, AnnotationHolder holder) {
		holder.newAnnotation(HighlightSeverity.ERROR, error)
			.range(instruction)
			.highlightType(ProblemHighlightType.ERROR)
			.create();
	}

	private void ensureOperandsOrder(AssemblyInstructionElement instruction, AnnotationHolder holder, List<ASTNode> operands, List<ASTNode> evaluated, TokenSet ... types) {
		if (types.length != operands.size()) {
			annotateInstructionError("Got " + operands.size() + " operands, expected: " + types.length, instruction, holder);
			return;
		}
		for (int i = 0; i < types.length; i++)
			if (!types[i].contains(operands.get(i).getElementType()))
				holder.newAnnotation(HighlightSeverity.ERROR, "Expected: " + types[i] + ", got: " + evaluated.get(i).getElementType())
					.range(operands.get(i))
					.highlightType(ProblemHighlightType.ERROR)
					.create();
	}

	private void checkOperands(AssemblyInstructionElement instruction, AssemblyInstructionElement evaluatedInstruction, AnnotationHolder holder) {
		String mnemonic = instruction.getMnemonic();
		List<ASTNode> operands = Arrays.asList(instruction.getNode().getChildren(OPERAND_TOKEN_SET));
		List<ASTNode> evaluated = Arrays.asList(evaluatedInstruction.getNode().getChildren(OPERAND_TOKEN_SET));

		for (int i = 0; i < operands.size(); i++)
			if (Pattern.matches("\\{\\w+}", evaluated.get(i).getText()))
				holder.newAnnotation(HighlightSeverity.ERROR, "Unable to evaluate: '" + operands.get(i).getText() + "'")
					.range(operands.get(i))
					.highlightType(ProblemHighlightType.LIKE_UNKNOWN_SYMBOL)
					.create();

		if (Pattern.matches("^(nop|ret|rti|sei|cli|sec|clc|halt|data|rodata)$", mnemonic)) {
			ensureOperandsOrder(instruction, holder, operands, evaluated, INHERENT_OPERANDS);
		} else if (Pattern.matches("^(ldb|ldw|ldr|stb|stw|str)$", mnemonic)) {
			if (operands.size() == 2)
				ensureOperandsOrder(instruction, holder, operands, evaluated, MEMORY_OPERANDS);
			else if (operands.size() == 3)
				ensureOperandsOrder(instruction, holder, operands, evaluated, RELATIVE_MEMORY_OPERANDS);
			else
				annotateInstructionError(INVALID_OPERANDS, instruction, holder);
		} else if (Pattern.matches("^(mul|add|adc|sub|sbc|and|or|xor|cmp|lsl|lsr|asr)$", mnemonic)) {
			ensureOperandsOrder(instruction, holder, operands, evaluated, ARITHMETIC_OPERANDS);
		} else if (Pattern.matches("^(inc|dec|push|pop)$", mnemonic)) {
			ensureOperandsOrder(instruction, holder, operands, evaluated, REGISTER_OPERANDS);
		} else if (Pattern.matches("^(beq|bne|bhs|blo|bmi|bpl|bvs|bvc|bhi|bls|bge|blt|bgt|ble|bra|jsr)$", mnemonic)) {
			ensureOperandsOrder(instruction, holder, operands, evaluated, ADDRESS_OPERANDS);
		} else if (Pattern.matches("^(tfr)$", mnemonic)) {
			ensureOperandsOrder(instruction, holder, operands, evaluated, REGISTER_REGISTER_OPERANDS);
		} else if (Pattern.matches("^(int)$", mnemonic)) {
			ensureOperandsOrder(instruction, holder, operands, evaluated, CONSTANT_OPERANDS);
		} else if (Pattern.matches("^(jmp)$", mnemonic)) {
			ensureOperandsOrder(instruction, holder, operands, evaluated, REGISTER_OR_ADDRESS_OPERANDS);
		} else if (Pattern.matches("^(org)$", mnemonic)) {
			ensureOperandsOrder(instruction, holder, operands, evaluated, CONSTANT_OPERANDS);
		} else if (Pattern.matches("^(var)$", mnemonic)) {
			if (operands.size() == 1)
				ensureOperandsOrder(instruction, holder, operands, evaluated, CONSTANT_OPERANDS);
			else if (operands.size() != 0)
				annotateInstructionError(INVALID_OPERANDS, instruction, holder);
		} else if (Pattern.matches("^(db)$", mnemonic)) {
			for (ASTNode operand: operands)
				if (operand.getElementType() != AssemblyTypes.STRING && operand.getElementType() != AssemblyTypes.CONSTANT)
					holder.newAnnotation(HighlightSeverity.ERROR, "Invalid constant")
						.range(operand)
						.highlightType(ProblemHighlightType.ERROR)
						.create();
		} else if (Pattern.matches("^(bin|include)$", mnemonic)) {
			if (operands.size() != 1 || evaluated.get(0).getElementType() != AssemblyTypes.STRING)
				annotateInstructionError(INVALID_OPERANDS, instruction, holder);
			else if (!Paths.get(instruction.getContainingFile().getVirtualFile().getParent().getPath(), evaluated.get(0).getText().replaceAll("\"", "")).toFile().exists())
				holder.newAnnotation(HighlightSeverity.WARNING, "Unresolved file")
					.range(operands.get(0))
					.highlightType(ProblemHighlightType.WARNING)
					.create();
		} else if (Pattern.matches("^(def)$", mnemonic)) {
			ensureOperandsOrder(instruction, holder, operands, evaluated, DEFINITION_OPERANDS);
		} else
			annotateInstructionError("Invalid instruction mnemonic", instruction, holder);
	}

	private void checkOperandLabels(AssemblyInstructionElement instruction, AssemblyInstructionElement evaluatedInstruction, AnnotationHolder holder) {
		ASTNode label = evaluatedInstruction.getLabelNode();
		if (label == null)
			return;

		ArrayList<AssemblyLabelDefinition> labelsDefinitions = new ArrayList<>();
		AssemblyLanguage.collectVisibleLabels(instruction.getContainingFile(), labelsDefinitions);
		for (AssemblyLabelDefinition definition: labelsDefinitions)
			if (label.getText().replaceAll("[=\\[\\]]", "").equals(definition.getName()))
				return;

		holder.newAnnotation(HighlightSeverity.ERROR, "Unresolved label")
			.range(instruction.getNode().getChildren(OPERAND_TOKEN_SET)[0])
			.highlightType(ProblemHighlightType.LIKE_UNKNOWN_SYMBOL)
			.create();
	}

	@Override
	public void annotate (@NotNull PsiElement element, @NotNull AnnotationHolder holder) {
		if (element instanceof AssemblyInstructionElement) {
			AssemblyInstructionElement instruction = ((AssemblyInstructionElement)element);
			String instructionText = instruction.getText();
			for (ASTNode operand: instruction.getNode().getChildren(OPERAND_TOKEN_SET))
				if (Pattern.matches("\\{\\w+}", operand.getText()))
					instructionText = instructionText.replace(operand.getText(), AssemblyLanguage.evaluateOperandConstant(operand));
			AssemblyInstructionElement evaluatedInstruction =
				(AssemblyInstructionElement)AssemblyElementFactory.createFile(instruction.getProject(), instructionText).getFirstChild();

			checkOperands(instruction, evaluatedInstruction, holder);
			checkOperandLabels(instruction, evaluatedInstruction, holder);
		} else if (element instanceof AssemblyLabelDefinition) {
			String labelName = ((AssemblyLabelDefinition)element).getName();
			for (String duplicate: AssemblyLanguage.collectVisibleLabels(element.getContainingFile(), new ArrayList<>()))
				if (duplicate.equals(labelName))
					holder.newAnnotation(HighlightSeverity.ERROR, "Duplicate label")
						.range(element)
						.highlightType(ProblemHighlightType.ERROR)
						.create();
		}
	}
}
