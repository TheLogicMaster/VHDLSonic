package com.thelogicmaster.vhdl_sonic;

import com.intellij.openapi.editor.colors.TextAttributesKey;
import com.intellij.openapi.fileTypes.SyntaxHighlighter;
import com.intellij.openapi.options.colors.AttributesDescriptor;
import com.intellij.openapi.options.colors.ColorDescriptor;
import com.intellij.openapi.options.colors.ColorSettingsPage;
import com.intellij.openapi.util.NlsContexts;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;
import java.util.Map;

public class AssemblyColorSettingsPage implements ColorSettingsPage {

	private static final AttributesDescriptor[] DESCRIPTORS = new AttributesDescriptor[]{
		new AttributesDescriptor("Label", AssemblySyntaxHighlighter.LABEL),
		new AttributesDescriptor("Register", AssemblySyntaxHighlighter.REGISTER),
		new AttributesDescriptor("Comment", AssemblySyntaxHighlighter.COMMENT),
		new AttributesDescriptor("Bad value", AssemblySyntaxHighlighter.BAD_CHARACTER),
		new AttributesDescriptor("Constant", AssemblySyntaxHighlighter.CONSTANT),
		new AttributesDescriptor("Label definition", AssemblySyntaxHighlighter.LABEL_DEF),
		new AttributesDescriptor("Separator", AssemblySyntaxHighlighter.SEPARATOR),
		new AttributesDescriptor("Mnemonic", AssemblySyntaxHighlighter.MNEMONIC),
		new AttributesDescriptor("String", AssemblySyntaxHighlighter.STRING)
	};

	@Override
	public @Nullable Icon getIcon () {
		return AssemblyIcons.LOGO;
	}

	@Override
	public @NotNull SyntaxHighlighter getHighlighter () {
		return new AssemblySyntaxHighlighter();
	}

	@Override
	public @NotNull String getDemoText () {
		return "; This is a comment\n"
			+ "\tdb \"Hello World\",#0\n"
			+ "\torg $100\n"
			+ "hello: ; A label\n"
			+ "\tand $F\n"
			+ "\tpush a\n"
			+ "\tjmp hello\n"
			+ "\torg $200\n"
			+ "\tbin \"sprite.bin\"\n"
			+ "\tdata ; Data section\n"
			+ "temp: var ; Variable\n";
	}

	@Override
	public @Nullable Map<String, TextAttributesKey> getAdditionalHighlightingTagToDescriptorMap () {
		return null;
	}

	@Override
	public AttributesDescriptor @NotNull [] getAttributeDescriptors () {
		return DESCRIPTORS;
	}

	@Override
	public ColorDescriptor @NotNull [] getColorDescriptors () {
		return ColorDescriptor.EMPTY_ARRAY;
	}

	@Override
	public @NotNull @NlsContexts.ConfigurableName String getDisplayName () {
		return "Assembly";
	}
}
