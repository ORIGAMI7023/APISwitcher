# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run Commands

```bash
# Restore dependencies
dotnet restore APISwitcher/APISwitcher.csproj

# Build the project (Debug)
dotnet build APISwitcher/APISwitcher.csproj

# Build the project (Release)
dotnet build APISwitcher/APISwitcher.csproj -c Release

# Run the application
dotnet run --project APISwitcher/APISwitcher.csproj

# Publish for distribution
dotnet publish APISwitcher/APISwitcher.csproj -c Release
```

## Architecture Overview

This is a WPF desktop application using MVVM pattern with dependency injection.

### Key Architecture Patterns

**MVVM with CommunityToolkit.Mvvm**
- ViewModels use `ObservableObject` base class and source generators (`[ObservableProperty]`, `[RelayCommand]`)
- Commands are automatically generated from methods with `[RelayCommand]` attribute
- Two-way data binding between Views (XAML) and ViewModels

**Dependency Injection**
- `App.xaml.cs` configures services using `Microsoft.Extensions.DependencyInjection`
- All services and ViewModels are registered as singletons
- MainWindow receives MainViewModel through constructor injection

**Configuration Management**
- `ConfigService` handles two JSON files:
  - `app_profiles.json` (app directory): stores available profiles
  - `~/.claude/settings.json` (user directory): Claude Code's active settings
- Profile activation is determined by comparing JSON structures using subset matching
- The `IsJsonSubset` method recursively compares JSON elements to identify active profiles

### Data Flow

1. **Startup**: App → DI Container → MainWindow → MainViewModel.InitializeAsync()
2. **Load Profiles**: ConfigService reads both JSON files → compares to mark active profile
3. **Switch Profile**: User clicks → SwitchProfileCommand → ConfigService writes to `~/.claude/settings.json`
4. **Refresh**: RefreshCommand → reloads both files → updates active status

### Important Implementation Details

**JSON Handling**
- Uses `JsonSerializerOptions` with `PropertyNameCaseInsensitive = true` to handle property name variations
- `ClaudeSettings.ExtensionData` captures all JSON properties dynamically using `[JsonExtensionData]`
- This allows profiles to contain any Claude Code settings without defining explicit properties

**Active Profile Detection**
- Compares profile settings as a subset of current Claude settings
- A profile is active if ALL its settings exist in the current settings with matching values
- Handles nested objects, arrays, and primitive values recursively

## File Locations

- **Profile definitions**: `APISwitcher/app_profiles.json` (copied to output directory)
- **Claude settings**: `~/.claude/settings.json` (user's home directory)
- **Application icon**: `APISwitcher/app_icon.ico`

## Modifying UI

The main window layout is defined in `MainWindow.xaml`:
- Uses `ItemsControl` with `WrapPanel` to display profile cards
- Profile cards change appearance based on `IsActive` property (green border/background when active)
- Status bar shows loading indicator and messages from ViewModel

## Adding New Features

When adding features that modify settings:
1. Update `ClaudeSettings` model if new top-level properties are needed (or use ExtensionData for dynamic properties)
2. Add methods to `ConfigService` for reading/writing
3. Add commands to `MainViewModel` with `[RelayCommand]`
4. Bind UI elements in XAML to ViewModel properties/commands
