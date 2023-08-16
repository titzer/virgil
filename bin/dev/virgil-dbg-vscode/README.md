# Virgil Debug

Provide a debugger extension with Virgil debugger using the Debug Adaptor Protocol.

## Install

Install the extension by right click `virgil-debug-0.0.1.vsix` and choose `Install Extension VSIX`.

## Usage

The simpliest way is "Dynamic Launch". Click the dropdown at the top of the Run and Debug view and choose "Virgil Debugger" for a dynamic config.
It will debug the current opened file. To use this setting, the workspace should be the virgil repository.

You can also add configuration by choosing "Virgil: Launch debug" in `launch.json`.
The default setting asks for the program name to be debugged each time before debug.

