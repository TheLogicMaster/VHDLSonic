package com.thelogicmaster.vhdl_sonic;

import com.intellij.formatting.Alignment;
import com.intellij.formatting.Block;
import com.intellij.formatting.Indent;
import com.intellij.formatting.Spacing;
import com.intellij.formatting.SpacingBuilder;
import com.intellij.formatting.Wrap;
import com.intellij.formatting.WrapType;
import com.intellij.lang.ASTNode;
import com.intellij.psi.TokenType;
import com.intellij.psi.formatter.common.AbstractBlock;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.ArrayList;
import java.util.List;

public class AssemblyBlock extends AbstractBlock {

	private final SpacingBuilder spacingBuilder;

	public AssemblyBlock(@NotNull ASTNode node, @Nullable Wrap wrap, @Nullable Alignment alignment, SpacingBuilder spacingBuilder) {
		super(node, wrap, alignment);
		this.spacingBuilder = spacingBuilder;
	}

	@Override
	protected List<Block> buildChildren () {
		List<Block> blocks = new ArrayList<>();
		ASTNode child = myNode.getFirstChildNode();
		while (child != null) {
			if (child.getElementType() != TokenType.WHITE_SPACE) {
				Block block = new AssemblyBlock(child, Wrap.createWrap(WrapType.NONE, false), Alignment.createAlignment(), spacingBuilder);
				blocks.add(block);
			}
			child = child.getTreeNext();
		}
		return blocks;
	}

	@Override
	public Indent getIndent () {
		return Indent.getNoneIndent();
	}

	@Override
	public @Nullable Spacing getSpacing (@Nullable Block child1, @NotNull Block child2) {
		return spacingBuilder.getSpacing(this, child1, child2);
	}

	@Override
	public boolean isLeaf () {
		return myNode.getFirstChildNode() == null;
	}
}
