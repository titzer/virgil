import * as vscode from 'vscode';
import { WorkspaceFolder, DebugConfiguration, ProviderResult } from 'vscode';
import { DbgAdapter } from './dbgAdaptor';


export function activate(context: vscode.ExtensionContext) {
	console.log("Starting extension...");

	context.subscriptions.push(vscode.commands.registerCommand('extension.virgil-debug.getProgramName', config => {
		return vscode.window.showInputBox({
			placeHolder: "Please enter the program name in the workspace folder",
			value: "mytest.v3"
		});
	}));

	// register a dynamic configuration provider
	context.subscriptions.push(vscode.debug.registerDebugConfigurationProvider('virgil', {
		provideDebugConfigurations(folder: WorkspaceFolder | undefined): ProviderResult<DebugConfiguration[]> {
			return [
				{
					name: "Dynamic Launch",
					request: "launch",
					type: "virgil",
					debugger: "${workspaceFolder}/bin/v3c",
					program: "${file}",
					stopOnEntry: true
				}
			];
		}
	}, vscode.DebugConfigurationProviderTriggerKind.Dynamic));

	let factory = new InlineDebugAdapterFactory();
	context.subscriptions.push(vscode.debug.registerDebugAdapterDescriptorFactory('virgil', factory));

}

export function deactivate() {
	// nothing to do
}

class InlineDebugAdapterFactory implements vscode.DebugAdapterDescriptorFactory {
	createDebugAdapterDescriptor(_session: vscode.DebugSession): ProviderResult<vscode.DebugAdapterDescriptor> {
		return new vscode.DebugAdapterInlineImplementation(new DbgAdapter());
	}
}
