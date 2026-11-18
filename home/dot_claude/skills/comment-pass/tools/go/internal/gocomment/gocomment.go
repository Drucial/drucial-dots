// Package gocomment finds and classifies every comment in a Go file.
package gocomment

import (
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
)

// Group is one comment group with what it is attached to.
type Group struct {
	File      string
	StartLine int
	EndLine   int
	Text      string
	Kind      string
	Decl      string
	Exported  bool
	Test      bool
	Directive bool
	Comments  []*ast.Comment
}

// Lines is how many source lines the group spans.
func (g Group) Lines() int { return g.EndLine - g.StartLine + 1 }

// Limit is the longest the rules allow this group to be, in lines.
func (g Group) Limit() int {
	if g.Exported && g.Kind != "package" {
		return 3
	}
	return 1
}

// Violation names the rule a group breaks, or returns empty.
func (g Group) Violation() string {
	switch {
	case g.Directive:
		return ""
	case g.Kind == "in-body":
		return "inside a function body"
	case g.Kind == "floating":
		return "not attached to a declaration"
	case g.Lines() > g.Limit():
		return "over its length limit"
	}
	return ""
}

var directivePrefixes = []string{"//go:", "//nolint", "//lint:", "//export ", "//extern ", "//line ", "// +build"}

// IsDirectiveText reports whether a single comment is tooling rather than prose.
func IsDirectiveText(text string) bool {
	for _, p := range directivePrefixes {
		if strings.HasPrefix(text, p) {
			return true
		}
	}
	return strings.Contains(text, "nolint:") || strings.Contains(text, "//nolint")
}

// ParseFile parses path with comments, returning nil for a generated file.
func ParseFile(fset *token.FileSet, path string, src []byte) (*ast.File, error) {
	f, err := parser.ParseFile(fset, path, src, parser.ParseComments)
	if err != nil {
		return nil, err
	}
	if ast.IsGenerated(f) {
		return nil, nil
	}
	return f, nil
}

// Classify returns every comment group in f, directives marked.
func Classify(fset *token.FileSet, f *ast.File, rel string) []Group {
	test := strings.HasSuffix(rel, "_test.go")
	owners := owners(f, test)
	bodies := bodies(f)
	cgo := cgoPreambles(f)

	var out []Group
	for _, cg := range f.Comments {
		g := Group{
			File:      rel,
			StartLine: fset.Position(cg.Pos()).Line,
			EndLine:   fset.Position(cg.End()).Line,
			Text:      rawText(cg),
			Test:      test,
			Comments:  cg.List,
		}
		g.Directive = cgo[cg] || exampleOutput(cg, test) || allDirectives(cg)
		switch {
		case inBody(cg, bodies):
			g.Kind = "in-body"
		case cg == f.Doc:
			g.Kind, g.Decl = "package", f.Name.Name
		default:
			if o, ok := owners[cg]; ok {
				g.Kind, g.Decl, g.Exported = o.kind, o.name, o.exported
			} else {
				g.Kind = "floating"
			}
		}
		out = append(out, g)
	}
	return out
}

// Walk calls fn for every non-generated .go file under root, skipping vendor, testdata and dot directories.
func Walk(root string, fn func(rel string, fset *token.FileSet, f *ast.File, src []byte)) error {
	return filepath.WalkDir(root, func(p string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			name := d.Name()
			if p != root && (name == "vendor" || name == "testdata" || strings.HasPrefix(name, ".") || name == "node_modules") {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(p, ".go") {
			return nil
		}
		src, err := os.ReadFile(p)
		if err != nil {
			return err
		}
		fset := token.NewFileSet()
		f, err := ParseFile(fset, p, src)
		if err != nil || f == nil {
			return nil
		}
		rel, _ := filepath.Rel(root, p)
		fn(rel, fset, f, src)
		return nil
	})
}

type owner struct {
	kind     string
	name     string
	exported bool
}

func owners(f *ast.File, test bool) map[*ast.CommentGroup]owner {
	m := map[*ast.CommentGroup]owner{}
	set := func(cg *ast.CommentGroup, kind, name string, exported bool) {
		if cg != nil {
			m[cg] = owner{kind, name, exported && !test}
		}
	}
	for _, decl := range f.Decls {
		switch d := decl.(type) {
		case *ast.FuncDecl:
			kind, exported := "func", ast.IsExported(d.Name.Name)
			if d.Recv != nil && len(d.Recv.List) > 0 {
				kind = "method"
				exported = exported && ast.IsExported(receiverName(d.Recv.List[0].Type))
			}
			set(d.Doc, kind, d.Name.Name, exported)
		case *ast.GenDecl:
			if len(d.Specs) > 0 {
				name := specName(d.Specs[0])
				set(d.Doc, d.Tok.String(), name, anyExported(d.Specs))
			}
			for _, s := range d.Specs {
				switch s := s.(type) {
				case *ast.TypeSpec:
					exported := ast.IsExported(s.Name.Name)
					set(s.Doc, "type", s.Name.Name, exported)
					set(s.Comment, "trailing", s.Name.Name, exported)
					fields(s.Type, exported, set)
				case *ast.ValueSpec:
					exported := ast.IsExported(s.Names[0].Name)
					set(s.Doc, d.Tok.String(), s.Names[0].Name, exported)
					set(s.Comment, "trailing", s.Names[0].Name, exported)
				case *ast.ImportSpec:
					set(s.Doc, "import", s.Path.Value, false)
					set(s.Comment, "trailing", s.Path.Value, false)
				}
			}
		}
	}
	return m
}

func fields(expr ast.Expr, parentExported bool, set func(*ast.CommentGroup, string, string, bool)) {
	var list *ast.FieldList
	switch t := expr.(type) {
	case *ast.StructType:
		list = t.Fields
	case *ast.InterfaceType:
		list = t.Methods
	}
	if list == nil {
		return
	}
	for _, fl := range list.List {
		name := "embedded"
		exported := parentExported
		if len(fl.Names) > 0 {
			name = fl.Names[0].Name
			exported = parentExported && ast.IsExported(name)
		}
		set(fl.Doc, "field", name, exported)
		set(fl.Comment, "trailing", name, exported)
		fields(fl.Type, exported, set)
	}
}

func receiverName(expr ast.Expr) string {
	switch t := expr.(type) {
	case *ast.StarExpr:
		return receiverName(t.X)
	case *ast.IndexExpr:
		return receiverName(t.X)
	case *ast.IndexListExpr:
		return receiverName(t.X)
	case *ast.Ident:
		return t.Name
	}
	return ""
}

func specName(s ast.Spec) string {
	switch s := s.(type) {
	case *ast.TypeSpec:
		return s.Name.Name
	case *ast.ValueSpec:
		return s.Names[0].Name
	case *ast.ImportSpec:
		return s.Path.Value
	}
	return "?"
}

func anyExported(specs []ast.Spec) bool {
	for _, s := range specs {
		if ast.IsExported(specName(s)) {
			return true
		}
	}
	return false
}

func bodies(f *ast.File) []*ast.BlockStmt {
	var out []*ast.BlockStmt
	ast.Inspect(f, func(n ast.Node) bool {
		switch fn := n.(type) {
		case *ast.FuncDecl:
			if fn.Body != nil {
				out = append(out, fn.Body)
			}
		case *ast.FuncLit:
			out = append(out, fn.Body)
		}
		return true
	})
	return out
}

func inBody(cg *ast.CommentGroup, bodies []*ast.BlockStmt) bool {
	for _, b := range bodies {
		if cg.Pos() > b.Lbrace && cg.End() < b.Rbrace {
			return true
		}
	}
	return false
}

func cgoPreambles(f *ast.File) map[*ast.CommentGroup]bool {
	m := map[*ast.CommentGroup]bool{}
	for _, decl := range f.Decls {
		d, ok := decl.(*ast.GenDecl)
		if !ok || d.Tok != token.IMPORT {
			continue
		}
		for _, s := range d.Specs {
			if is := s.(*ast.ImportSpec); is.Path.Value == `"C"` {
				if d.Doc != nil {
					m[d.Doc] = true
				}
				if is.Doc != nil {
					m[is.Doc] = true
				}
			}
		}
	}
	return m
}

func exampleOutput(cg *ast.CommentGroup, test bool) bool {
	if !test {
		return false
	}
	first := strings.TrimSpace(strings.TrimPrefix(cg.List[0].Text, "//"))
	return strings.HasPrefix(first, "Output:") || strings.HasPrefix(first, "Unordered output:")
}

func allDirectives(cg *ast.CommentGroup) bool {
	for _, c := range cg.List {
		if !IsDirectiveText(c.Text) {
			return false
		}
	}
	return true
}

func rawText(cg *ast.CommentGroup) string {
	parts := make([]string, len(cg.List))
	for i, c := range cg.List {
		parts[i] = c.Text
	}
	return strings.Join(parts, "\n")
}
