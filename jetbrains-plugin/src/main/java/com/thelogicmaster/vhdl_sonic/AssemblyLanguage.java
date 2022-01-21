package com.thelogicmaster.vhdl_sonic;

import com.intellij.lang.ASTNode;
import com.intellij.lang.Language;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.psi.PsiElement;
import com.intellij.psi.PsiFile;
import com.intellij.psi.PsiManager;
import com.intellij.psi.search.FileTypeIndex;
import com.intellij.psi.search.GlobalSearchScope;
import com.intellij.psi.util.PsiTreeUtil;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyFile;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyInstructionElement;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyLabelDefinition;
import com.thelogicmaster.vhdl_sonic.psi.AssemblyTypes;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class AssemblyLanguage extends Language {
	public static final AssemblyLanguage INSTANCE = new AssemblyLanguage();
	public static final String[] INSTRUCTIONS;
	public static final Map<String, String[]> DOCUMENTATION;

	private static final int MAX_INCLUDE_DEPTH = 100;

	static {
		DOCUMENTATION = new HashMap<>();
		DOCUMENTATION.put("org", new String[]{
			"Set assembly origin",
			"ORG $1234"
		});
		DOCUMENTATION.put("include", new String[]{
			"Include an assembly file",
			"INCLUDE \"libraries/Math.asm\""
		});
		DOCUMENTATION.put("label", new String[]{
			"Manually define a label",
			"LABEL label=$1234"
		});
		DOCUMENTATION.put("def", new String[]{
			"Define a constant",
			"DEF constant=$1"
		});
		DOCUMENTATION.put("ifndef", new String[]{
			"Define a constant if not already defined",
			"IFNDEF constant=$1"
		});
		DOCUMENTATION.put("data", new String[]{
			"Enter variable data section",
			"DATA"
		});
		DOCUMENTATION.put("rodata", new String[]{
			"Enter program data section",
			"RODATA"
		});
		DOCUMENTATION.put("var", new String[]{
			"Variable placeholder for byte or byte array",
			"label: VAR",
			"label: VAR[n]"
		});
		DOCUMENTATION.put("db", new String[]{
			"Define byte, accepts immediate values and String literals",
			"label: DB \"Hello World!\\n\",$0"
		});
		DOCUMENTATION.put("dw", new String[]{
			"Define 16-bit word",
			"label: DW $1234,12345"
		});
		DOCUMENTATION.put("dd", new String[]{
			"Define 32-bit double-word",
			"label: DD $12345678,123456789"
		});
		DOCUMENTATION.put("bin", new String[]{
			"Define binary blob from file",
			"BIN \"sprite.bin\""
		});
		DOCUMENTATION.put("align", new String[]{
			"Specify the assembler byte alignment",
			"ALIGN 4"
		});
		DOCUMENTATION.put("nop", new String[]{
			"No operation",
			"NOP"
		});
		DOCUMENTATION.put("beq", new String[]{
			"Branch if equal (Z==1)",
			"BEQ label",
			"BEQ -8"
		});
		DOCUMENTATION.put("bne", new String[]{
			"Branch if not equal (Z==0)",
			"BNE label",
			"BNE -8"
		});
		DOCUMENTATION.put("bhs", new String[]{
			"Branch if unsigned higher or same (C==1)",
			"BHS label",
			"BHS -8"
		});
		DOCUMENTATION.put("blo", new String[]{
			"Branch if unsigned lower (C==0)",
			"BLO label",
			"BLO -8"
		});
		DOCUMENTATION.put("bmi", new String[]{
			"Branch if minus (N==1)",
			"BMI label",
			"BMI -8"
		});
		DOCUMENTATION.put("bpl", new String[]{
			"Branch if plus (N==0)",
			"BPL label",
			"BPL -8"
		});
		DOCUMENTATION.put("bvs", new String[]{
			"Branch if signed overflow (V==1)",
			"BVS label",
			"BVS -8"
		});
		DOCUMENTATION.put("bvc", new String[]{
			"Branch if no signed overflow (V==0)",
			"BVC label",
			"BVC -8"
		});
		DOCUMENTATION.put("bhi", new String[]{
			"Branch if unsigned higher (C & ~Z)",
			"BHI label",
			"BHI -8"
		});
		DOCUMENTATION.put("bls", new String[]{
			"Branch if unsigned lower or same (~C | Z)",
			"BLS label",
			"BLS -8"
		});
		DOCUMENTATION.put("bge", new String[]{
			"Branch if signed greater or equal (N==V)",
			"BGE label",
			"BGE -8"
		});
		DOCUMENTATION.put("blt", new String[]{
			"Branch if signed less (N!=V)",
			"BLT label",
			"BLT -8"
		});
		DOCUMENTATION.put("bgt", new String[]{
			"Branch if signed greater (~Z & N==V)",
			"BGT label",
			"BGT -8"
		});
		DOCUMENTATION.put("ble", new String[]{
			"Branch if signed less or equal (Z | N!=V)",
			"BLE label",
			"BLE -8"
		});
		DOCUMENTATION.put("bra", new String[]{
			"Branch always",
			"BRA label",
			"BRA -8"
		});
		DOCUMENTATION.put("inc", new String[]{
			"Increments a register. Sets Zero, Carry, Negative, and Overflow flags",
			"INC R0"
		});
		DOCUMENTATION.put("dec", new String[]{
			"Decrements a register. Sets Zero, Carry, Negative, and Overflow flags",
			"DEC R0"
		});
		DOCUMENTATION.put("tfr", new String[]{
			"Transfer one register to another",
			"TFR R1,R0"
		});
		DOCUMENTATION.put("mul", new String[]{
			"Multiplies register by an immediate or register. Sets Zero flag",
			"MUL R0,$FF",
			"MUL R0,R1"
		});
		DOCUMENTATION.put("lsl", new String[]{
			"Shifts register left by register or immediate number of bits into C. Sets Zero flag and carry flag",
			"LSL R0,2",
			"LSL R0,R1"
		});
		DOCUMENTATION.put("asr", new String[]{
			"Arithmetically shifts register right by register or immediate number of bits into C. Sets Zero flag and carry flag",
			"ASR R0,2",
			"ASR R0,R1"
		});
		DOCUMENTATION.put("lsr", new String[]{
			"Logically shifts register right by register or immediate number of bits into C. Sets Zero flag and carry flag",
			"ASL R0,2",
			"ASL R0,R1"
		});
		DOCUMENTATION.put("add", new String[]{
			"Adds an immediate or register to register. Sets Zero, Carry, Negative, and Overflow flags",
			"ADD R0,$FF",
			"ADD R0,R1"
		});
		DOCUMENTATION.put("adc", new String[]{
			"Adds an immediate or register and Carry to register. Sets Zero, Carry, Negative, and Overflow flags",
			"ADC R0,$FF",
			"ADC R0,R1"
		});
		DOCUMENTATION.put("sub", new String[]{
			"Subtracts an immediate or register from register. Sets Zero, Carry, Negative, and Overflow flags",
			"SUB R0,$FF",
			"SUB R0,R1"
		});
		DOCUMENTATION.put("sbc", new String[]{
			"Subtracts an immediate or register and Carry from register. Sets Zero, Carry, Negative, and Overflow flags",
			"SBC R0,$FF",
			"SBC R0,R1"
		});
		DOCUMENTATION.put("and", new String[]{
			"Bitwise ANDs register with an immediate or register. Sets Zero, Carry, Negative, and Overflow flags",
			"AND R0,$FF",
			"AND R0,R1"
		});
		DOCUMENTATION.put("or", new String[]{
			"Bitwise ORs register with an immediate or register. Sets Zero, Carry, Negative, and Overflow flags",
			"OR R0,$FF",
			"OR R0,R1"
		});
		DOCUMENTATION.put("xor", new String[]{
			"Bitwise XORs register with an immediate or register. Sets Zero, Carry, Negative, and Overflow flags",
			"XOR R0,$FF",
			"XOR R0,R1"
		});
		DOCUMENTATION.put("cmp", new String[]{
			"Sets the Zero, Carry, Negative, and Overflow flags for SUB without modifying register",
			"CMP R0,0",
			"CMP R0,R1"
		});
		DOCUMENTATION.put("jmp", new String[]{
			"Jump to address",
			"JMP label",
			"JMP $1234",
			"JMP R0"
		});
		DOCUMENTATION.put("push", new String[]{
			"Push a register to the stack",
			"PUSH R0"
		});
		DOCUMENTATION.put("pop", new String[]{
			"Pop a register from the stack",
			"POP R0"
		});
		DOCUMENTATION.put("jsr", new String[]{
			"Jump to subroutine",
			"JSR label",
			"JSR $1234"
		});
		DOCUMENTATION.put("ret", new String[]{
			"Return from subroutine",
			"RET"
		});
		DOCUMENTATION.put("rti", new String[]{
			"Return from interrupt",
			"RTI"
		});
		DOCUMENTATION.put("halt", new String[]{
			"Halt CPU",
			"HALT"
		});
		DOCUMENTATION.put("int", new String[]{
			"Trigger an interrupt",
			"INT 0"
		});
		DOCUMENTATION.put("cli", new String[]{
			"Disable interrupts",
			"CLI"
		});
		DOCUMENTATION.put("sei", new String[]{
			"Enable interrupts",
			"SEI"
		});
		DOCUMENTATION.put("sec", new String[]{
			"Set carry flag",
			"SEC"
		});
		DOCUMENTATION.put("clc", new String[]{
			"Clear carry flag",
			"CLC"
		});
		DOCUMENTATION.put("ldr", new String[]{
			"Load register with value from immediate or memory",
			"LDR R0,1234",
			"LDR R0,[label]",
			"LDR R0,[$1234]",
			"LDR R0,R1++",
			"LDR R0,R1,4"
		});
		DOCUMENTATION.put("ldw", new String[]{
			"Load register with 16-bit word from memory",
			"LDW R0,[label]",
			"LDW R0,[$1234]",
			"LDW R0,R1++",
			"LDW R0,R1,4"
		});
		DOCUMENTATION.put("ldb", new String[]{
			"Load register with byte from memory",
			"LDB R0,[label]",
			"LDB R0,[$1234]",
			"LDB R0,R1++",
			"LDB R0,R1,4"
		});
		DOCUMENTATION.put("str", new String[]{
			"Store 32-bit register double-word into memory",
			"STR R0,[label]",
			"STR R0,[$1234]",
			"STR R0,R1++",
			"STR R0,R1,4"
		});
		DOCUMENTATION.put("stw", new String[]{
			"Store 16-bit register word into memory",
			"STW R0,[label]",
			"STW R0,[$1234]",
			"STW R0,R1++",
			"STW R0,R1,4"
		});
		DOCUMENTATION.put("stb", new String[]{
			"Store register byte into memory",
			"STB R0,[label]",
			"STB R0,[$1234]",
			"STB R0,R1++",
			"STB R0,R1,4"
		});

		INSTRUCTIONS = DOCUMENTATION.keySet().toArray(new String[0]);
	}

	/**
	 * Collects all Assembly program files in the project
	 * @param project to collect from
	 * @return List of collected files
	 */
	public static List<AssemblyFile> getProjectFiles(Project project) {
		ArrayList<AssemblyFile> files = new ArrayList<>();
		Collection<VirtualFile> virtualFiles = FileTypeIndex.getFiles(AssemblyFileType.INSTANCE, GlobalSearchScope.allScope(project));
		for (VirtualFile virtualFile: virtualFiles) {
			AssemblyFile assemblyFile = (AssemblyFile)PsiManager.getInstance(project).findFile(virtualFile);
			if (assemblyFile == null)
				continue;
			files.add(assemblyFile);
		}
		return files;
	}

	private static void extractDefinition(AssemblyInstructionElement instructionElement, Map<String, String> constants, boolean overwrite) {
		Matcher matcher = Pattern.compile("(?:ifn)?def\\W+(\\w+)=(.+)").matcher(instructionElement.getText());
		if (!matcher.matches())
			return;
		if (!overwrite && constants.containsKey(matcher.group(1)))
			return;
		constants.put(matcher.group(1), matcher.group(2));
	}

	private static void collectVisibleConstants(PsiElement file, PsiElement operand, Map<String, String> constants, Set<String> includes, int depth) {
		if (depth > MAX_INCLUDE_DEPTH)
			return;

		AssemblyInstructionElement[] instructions = PsiTreeUtil.getChildrenOfType(file, AssemblyInstructionElement.class);
		if (instructions == null)
			return;

		for (AssemblyInstructionElement instruction: instructions) {
			if (instruction == operand.getParent())
				return;
			String mnemonic = instruction.getMnemonic();

			if ("include".equals(mnemonic)) {
				ASTNode includeNode = instruction.getNode().findChildByType(AssemblyTypes.STRING);
				if (includeNode == null)
					continue;
				String include = includeNode.getText().replace("\"", "");
				String includePath = Paths.get(file.getContainingFile().getVirtualFile().getParent().getPath(), include).toAbsolutePath().toString();
				if (!includes.add(includePath))
					continue;

				for (AssemblyFile assemblyFile : getProjectFiles(operand.getProject()))
					if (includePath.equals(assemblyFile.getVirtualFile().getPath()))
						collectVisibleConstants(assemblyFile, operand, constants, includes, depth + 1);
			} else if ("def".equals(mnemonic))
				extractDefinition(instruction, constants, true);
			else if ("ifndef".equals(mnemonic))
				extractDefinition(instruction, constants, false);
		}
	}

	/**
	 * Attempts to parse a constant within an operand node.
	 * Upon failing to do so, just returns the source node text
	 * @param operand to parse
	 * @return String of parsed operand
	 */
	public static String evaluateOperandConstant(ASTNode operand) {
		Pattern pattern = Pattern.compile(".*\\{(\\w+)}.*");

		HashMap<String, String> constants = new HashMap<>();
		collectVisibleConstants(operand.getPsi().getContainingFile(), operand.getPsi().getParent(), constants, new HashSet<>(), 0);

		String current = operand.getText();

		for (int i = 0; i < 10; i++) {
			Matcher matcher = pattern.matcher(current);
			if (!matcher.matches())
				break;
			String constant = matcher.group(1);
			if (!constants.containsKey(constant))
				break;
			current = constants.get(constant);
		}

		return current;
	}

	private static void collectVisibleLabels(PsiFile file, Collection<AssemblyLabelDefinition> definitions, Set<String> collected, Set<String> duplicates, Set<String> includes, int depth) {
		if (depth > MAX_INCLUDE_DEPTH)
			return;

		AssemblyLabelDefinition[] labels = PsiTreeUtil.getChildrenOfType(file, AssemblyLabelDefinition.class);
		if (labels != null)
			for (AssemblyLabelDefinition label: labels) {
				definitions.add(label);
				String labelName = label.getName();
				if (!collected.add(labelName))
					duplicates.add(labelName);
			}

		AssemblyInstructionElement[] instructions = PsiTreeUtil.getChildrenOfType(file, AssemblyInstructionElement.class);
		if (instructions != null)
			for (AssemblyInstructionElement instruction: instructions) {
				if (!"include".equals(instruction.getMnemonic()))
					continue;

				ASTNode include = instruction.getNode().findChildByType(AssemblyTypes.STRING);
				if (include == null)
					continue;
				String includeText = include.getText().replace("\"", "");
				Path includePath = Paths.get(file.getVirtualFile().getParent().getPath(), includeText).toAbsolutePath();
				if (!includes.add(includePath.toString()))
					continue;

				for (AssemblyFile assemblyFile : getProjectFiles(file.getProject()))
					if (includePath.equals(Paths.get(assemblyFile.getVirtualFile().getPath())))
						collectVisibleLabels(assemblyFile, definitions, collected, duplicates, includes, depth + 1);
			}
	}

	/**
	 * Collects all visible labels in an Assembly program
	 * @param file to collect labels from
	 * @param definitions collection to store results
	 * @return A set of duplicate label names
	 */
	public static Set<String> collectVisibleLabels(PsiFile file, Collection<AssemblyLabelDefinition> definitions) {
		Set<String> duplicates = new HashSet<>();
		collectVisibleLabels(file, definitions, new HashSet<>(), duplicates, new HashSet<>(), 0);
		return duplicates;
	}

	private AssemblyLanguage() {
		super("Assembly");
	}
}
