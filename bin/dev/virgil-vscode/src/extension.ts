import * as vscode from 'vscode';
import * as Parser from 'tree-sitter';
import * as Virgil from 'tree-sitter-virgil/bindings/node/index.js';

import { buildTokens, tokenTypes, tokenModifiers } from './token';

const VIRGIL_LANGUAGE_ID = 'virgil';

const parser = new Parser();
const trees: {[uri: string]: Parser.Tree} = {};

async function open(editor: vscode.TextEditor) {
    if (editor.document.languageId == VIRGIL_LANGUAGE_ID) {
        const tree = parser.parse(editor.document.getText());
        trees[editor.document.uri.toString()] = tree;
    }
}

async function edit(edit: vscode.TextDocumentChangeEvent) {
    if (edit.document.languageId != VIRGIL_LANGUAGE_ID)
        return;

    const uri = edit.document.uri.toString();
    let oldTree = trees[uri];

    if (oldTree === undefined) {
        oldTree = parser.parse(edit.document.getText());
        trees[edit.document.uri.toString()] = oldTree;
    }
    
    for (const e of edit.contentChanges) {
        const startIndex = e.rangeOffset;
        const oldEndIndex = e.rangeOffset + e.rangeLength;
        const newEndIndex = e.rangeOffset + e.text.length;
        const startPos = edit.document.positionAt(startIndex);
        const oldEndPos = edit.document.positionAt(oldEndIndex);
        const newEndPos = edit.document.positionAt(newEndIndex);
        const startPosition = {row: startPos.line, column: startPos.character};
        const oldEndPosition = {row: oldEndPos.line, column: oldEndPos.character};
        const newEndPosition = {row: newEndPos.line, column: newEndPos.character};
        const delta = {startIndex, oldEndIndex, newEndIndex, startPosition, oldEndPosition, newEndPosition};
        oldTree.edit(delta);
    }
    const newTree = parser.parse(edit.document.getText(), oldTree);
    trees[uri] = newTree;
}

async function updateOpen() {
    for (const editor of vscode.window.visibleTextEditors) {
        await open(editor);
    }
}

async function close(document: vscode.TextDocument) {
    const uri = document.uri.toString();
    if (uri in trees) {
        delete trees[uri];
    }
}


const legend = new vscode.SemanticTokensLegend([...tokenTypes], [...tokenModifiers]);

const provider: vscode.DocumentSemanticTokensProvider = {
    provideDocumentSemanticTokens(document: vscode.TextDocument): vscode.ProviderResult<vscode.SemanticTokens> {
        const tokensBuilder = new vscode.SemanticTokensBuilder(legend);
        let tree = trees[document.uri.toString()];

        if (tree === undefined) {
            tree = parser.parse(document.getText());
            trees[document.uri.toString()] = tree;
        }

        return buildTokens(tokensBuilder, tree);
    }
};

const selector = { language: 'virgil', scheme: 'file' };
vscode.languages.registerDocumentSemanticTokensProvider(selector, provider, legend);

export function activate(context: vscode.ExtensionContext) {
	console.log('Activated');

    console.log('Activating tree-sitter parser...');
    parser.setLanguage(Virgil);

    context.subscriptions.push(vscode.window.onDidChangeVisibleTextEditors(updateOpen));
    context.subscriptions.push(vscode.workspace.onDidChangeTextDocument(edit));
    context.subscriptions.push(vscode.workspace.onDidCloseTextDocument(close));
}

export function deactivate() {}