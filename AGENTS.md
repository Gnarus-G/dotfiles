# Agent Guidelines for dotfiles Repository

This repository primarily contains configuration files and scripts for various tools. When making changes, please adhere to the following guidelines:

## 1. Build/Lint/Test Commands

*   **General:** There are no universal build, lint, or test commands for this repository.
*   **Specific Tools:** For individual configurations (e.g., Neovim, LeftWM, Eww), refer to their respective documentation or configuration files for any specific linting or testing procedures.
*   **Shell Scripts:** Basic shell script linting can be performed using `shellcheck <script_name.sh>`.

## 2. Code Style Guidelines

*   **Imports/Includes:** Follow the existing patterns for importing or including files within each configuration type (e.g., Lua `require`, SCSS `@import`).
*   **Formatting:** Maintain consistent indentation (tabs or spaces as per existing files), spacing, and line breaks.
*   **Naming Conventions:** Adhere to the naming conventions already present in the specific configuration files (e.g., snake_case for Lua variables, kebab-case for CSS classes).
*   **Error Handling:** For scripts, include basic error handling where appropriate (e.g., checking command success, handling file not found).
*   **Comments:** Use comments sparingly to explain complex logic or non-obvious configurations.
*   **File Specificity:** Each configuration file or script should be self-contained and focused on its specific purpose.

## 3. Cursor/Copilot Rules

No specific Cursor or Copilot rules were found in the repository. Agents should follow the general guidelines above.
