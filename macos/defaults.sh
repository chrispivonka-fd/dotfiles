#!/usr/bin/env bash
# =============================================================================
# macOS system defaults — opinionated settings for a developer Mac
# Safe to run multiple times. Changes take effect after logout/restart
# or after killing the relevant process (noted per section).
# =============================================================================

set -euo pipefail

info()    { printf '\033[1;34m[info]\033[0m %s\n' "$1"; }
success() { printf '\033[1;32m[ok]\033[0m   %s\n' "$1"; }

# Close System Settings (macOS Ventura+) / System Preferences (older) to
# prevent it from overwriting defaults written below when it later quits
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

# =============================================================================
# General UI/UX
# =============================================================================
info "General UI/UX..."

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Set dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

success "General UI/UX done"

# =============================================================================
# Keyboard & Input
# =============================================================================
info "Keyboard & Input..."

# Enable full keyboard access (tab through all controls)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set a fast key repeat rate (lower = faster; 2 is the fastest)
defaults write NSGlobalDomain KeyRepeat -int 2

# Set a short delay until key repeat (lower = shorter; 15 = 225ms)
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

success "Keyboard & Input done"

# =============================================================================
# Trackpad & Mouse
# =============================================================================
info "Trackpad & Mouse..."

# Enable tap to click for the trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Enable three-finger drag
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

# Set tracking speed (0–3, 3 is fastest)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.5

success "Trackpad & Mouse done"

# =============================================================================
# Finder
# =============================================================================
info "Finder..."

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path in window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Use list view in all windows by default (Nlsv = list, icnv = icon, clmv = column, glyv = gallery)
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show the ~/Library folder
chflags nohidden ~/Library 2>/dev/null || true

# Expand the following File Info panes: "General", "Open with", and "Sharing & Permissions"
defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true

success "Finder done"

# =============================================================================
# Dock
# =============================================================================
info "Dock..."

# Set Dock icon size (pixels)
defaults write com.apple.dock tilesize -int 48

# Enable Dock magnification
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 64

# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Remove the auto-hide delay
defaults write com.apple.dock autohide-delay -float 0

# Speed up the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0.5

# Don't show recent applications in the Dock
defaults write com.apple.dock show-recents -bool false

# Position Dock on the left
defaults write com.apple.dock orientation -string "left"

success "Dock done"

# =============================================================================
# Screen
# =============================================================================
info "Screen..."

# Require password immediately after sleep or screen saver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to ~/Desktop/Screenshots
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

success "Screen done"

# =============================================================================
# Activity Monitor
# =============================================================================
info "Activity Monitor..."

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

success "Activity Monitor done"

# =============================================================================
# Terminal & iTerm2
# =============================================================================
info "Terminal..."

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

success "Terminal done"

# =============================================================================
# Restart affected applications
# =============================================================================
info "Restarting affected applications..."

for app in "Finder" "Dock" "SystemUIServer" "cfprefsd"; do
    killall "$app" &>/dev/null || true
done

success "macOS defaults applied — some changes require a logout/restart to take full effect"
