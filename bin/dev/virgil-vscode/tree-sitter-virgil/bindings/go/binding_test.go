package tree_sitter_virgil_test

import (
	"testing"

	tree_sitter "github.com/smacker/go-tree-sitter"
	"github.com/tree-sitter/tree-sitter-virgil"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_virgil.Language())
	if language == nil {
		t.Errorf("Error loading Virgil grammar")
	}
}
