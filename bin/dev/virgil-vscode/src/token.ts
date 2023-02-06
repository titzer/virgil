import * as vscode from 'vscode';
import * as Parser from 'tree-sitter';
import * as Virgil from 'tree-sitter-virgil/bindings/node/index.js';

const parser = new Parser();
parser.setLanguage(Virgil);

export const tokenTypes = ['keyword', 'namespace', 'class', 'enum', 'enumMember', 'property', 'method', 'typeParameter', 'parameter', 'type', 'variable'] as const;
export type TokenType = typeof tokenTypes[number];
export const tokenModifiers = ['declaration', 'defaultLibrary'] as const;
export type TokenModifier = typeof tokenModifiers[number];

const BUILT_IN_TYPES = ['bool', 'string', 'int', 'long', 'byte', 'void', 'float', 'double', 'Array', 'Range', 'short', 'Ref'];

export type SemanticToken = {
    range: vscode.Range,
    type: TokenType,
    modifiers?: TokenModifier[],
}

type SyntaxNode = Parser.SyntaxNode & {
    [fieldName: `${string}Node`]: SyntaxNode,
    [fieldName: `${string}Nodes`]: SyntaxNode[],
};

function pointToPosition(point: Parser.Point): vscode.Position {
    return new vscode.Position(point.row, point.column);
}

export function buildTokens(builder: vscode.SemanticTokensBuilder, tree: Parser.Tree): vscode.SemanticTokens {
    const addNodeAsSemanticToken = (node: SyntaxNode, type: TokenType, modifiers?: TokenModifier[]) => {
        builder.push(
            new vscode.Range(pointToPosition(node.startPosition), pointToPosition(node.endPosition)),
            type,
            modifiers,
        );
    }

    const visitArray = (nodes: SyntaxNode[]) => {
        for (const node of nodes) {
            visit(node);
        }
    }

    const visitNamedChildren = (node: SyntaxNode) => {
        if (!node) return;
        const numDecls = node.namedChildCount;
        for (let i = 0; i < numDecls; i++) {
            const child = node.namedChild(i);
            visit(child as SyntaxNode);
        }
    }

    const visitParamDecl = ({ nameNode, typeNode }: SyntaxNode) => {
        addNodeAsSemanticToken(nameNode, 'parameter');
        visit(typeNode);
    }

    const visitIdentParam = (node: SyntaxNode, identifierType: TokenType, modifiers?: TokenModifier[]) => {
        const { nameNode, typeArgsNode } = node;
        addNodeAsSemanticToken(nameNode, identifierType, modifiers);

        if (typeArgsNode) {
            const openNode = node.child(1) as SyntaxNode;
            const closeNode = node.child(3) as SyntaxNode;

            addNodeAsSemanticToken(openNode, 'keyword');
            addNodeAsSemanticToken(closeNode, 'keyword');
            visitNamedChildren(typeArgsNode);
        }
    }

    const visitVarDecl = ({ nameNode, restNodes }: SyntaxNode, identifierType: TokenType) => {
        addNodeAsSemanticToken(nameNode, identifierType);
        visitArray(restNodes);
    }

    const visitorFunctions: {
        [nodeType: string]: (node: SyntaxNode) => void;
    } = {
        var_param_decls: visitNamedChildren,
        param_decls: visitNamedChildren,
        new_param_decls: visitNamedChildren,

        var_param_decl: visitParamDecl,
        param_decl: visitParamDecl,
        new_param_decl: visitParamDecl,

        type_ref(node) {
            const { tupleNode, memberNodes, functionNodes } = node;
            if (tupleNode)
                visitNamedChildren(tupleNode as SyntaxNode);
            
            if (memberNodes) {
                if (memberNodes.length === 1) {
                    const typeNode = memberNodes[0];
                    const typeName = typeNode.nameNode.text;
                    
                    const builtIn = BUILT_IN_TYPES.includes(typeName)
                        || typeName.match(/^[iu]([1-9]|[1-5][0-9]|6[0-4])$/);

                    visitIdentParam(typeNode, 'type', builtIn ? ['defaultLibrary'] : undefined)
                } else {
                    visitArray(memberNodes);
                }
            }

            if (functionNodes)
                visitArray(functionNodes);
        },

        component_decl({ nameNode, membersNodes }) {
            addNodeAsSemanticToken(nameNode, 'namespace', ['declaration']);
            visitArray(membersNodes);
        },

        class_decl({ nameNode, parametersNode, extendsTypeNode, extendsTypeParamsNode, membersNodes }) {
            visitIdentParam(nameNode, 'class', ['declaration']);
            visit(parametersNode);
            visit(extendsTypeNode);
            visit(extendsTypeParamsNode);
            visitArray(membersNodes);
        },

        enum_decl({ nameNode, parametersNode, casesNode }) {
            addNodeAsSemanticToken(nameNode, 'enum', ['declaration']);
            if (parametersNode)
                visit(parametersNode);
            if (casesNode)
                visitNamedChildren(casesNode);
        },

        enum_case({ nameNode }) {
            addNodeAsSemanticToken(nameNode, 'enumMember');
        },

        variant_decl({ nameNode, declsNode, membersNodes }) {
            addNodeAsSemanticToken(nameNode, 'enum', ['declaration']);
            visit(declsNode);
            visitArray(membersNodes);
        },

        variant_case({ nameNode, declsNode, methodNodes }) {
            addNodeAsSemanticToken(nameNode, 'enumMember');
            visit(declsNode);
            visitArray(methodNodes);
        },

        var_member({ declsNode }) {
            const numDecls = declsNode.namedChildCount;
            for (let i = 0; i < numDecls; i++) {
                const declNode = declsNode.namedChild(i) as SyntaxNode;
                visitVarDecl(declNode, 'property');
            }
        },

        method({ nameNode, parametersNode, returnTypeNode, bodyNode }) {
            visitIdentParam(nameNode, 'method');
            visit(parametersNode);
            visit(returnTypeNode);
            visit(bodyNode);
        },

        var_decl(node) {
            visitVarDecl(node, 'variable');
        },

        apply_suffix(node) {
            const identParamNode = node.parent?.previousNamedSibling?.child(0)?.namedChild(0);
            if (identParamNode && identParamNode.type === 'ident_param')
                visitIdentParam(identParamNode as SyntaxNode, 'method');
            visitNamedChildren(node);
        }
    }
    
    function visit(currentNode: SyntaxNode) {
        if (!currentNode) return;

        if (currentNode.type in visitorFunctions) {
            visitorFunctions[currentNode.type](currentNode);
        } else {
            visitNamedChildren(currentNode);
        }
    }

    visit(tree.rootNode as SyntaxNode);
    return builder.build();
}