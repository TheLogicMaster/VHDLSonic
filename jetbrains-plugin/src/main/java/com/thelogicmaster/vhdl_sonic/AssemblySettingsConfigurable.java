package com.thelogicmaster.vhdl_sonic;

import com.intellij.openapi.options.Configurable;
import com.intellij.ui.EditorNotifications;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;

public class AssemblySettingsConfigurable implements Configurable {

	private AssemblySettingsComponent settingsComponent;

	@Override
	public String getDisplayName() {
		return "Custom Assembly Settings";
	}

	@Override
	public JComponent getPreferredFocusedComponent () {
		return settingsComponent.getPreferredFocusedComponent();
	}

	@Override
	public @Nullable JComponent createComponent() {
		settingsComponent = new AssemblySettingsComponent();
		return settingsComponent.getPanel();
	}

	@Override
	public boolean isModified() {
		AssemblySettingsState settings = AssemblySettingsState.getInstance();
		return !settingsComponent.getAssemblerPath().equals(settings.assemblerPath) || !settingsComponent.getEmulatorPath().equals(settings.emulatorPath);
	}

	@Override
	public void apply() {
		AssemblySettingsState settings = AssemblySettingsState.getInstance();
		settings.assemblerPath = settingsComponent.getAssemblerPath();
		settings.emulatorPath = settingsComponent.getEmulatorPath();
		EditorNotifications.updateAll();
	}

	@Override
	public void reset() {
		AssemblySettingsState settings = AssemblySettingsState.getInstance();
		settingsComponent.setAssemblerPath(settings.assemblerPath);
		settingsComponent.setEmulatorPath(settings.emulatorPath);
	}

	@Override
	public void disposeUIResources() {
		settingsComponent = null;
	}
}
