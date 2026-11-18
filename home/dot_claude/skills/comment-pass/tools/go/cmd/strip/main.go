// Command strip deletes every comment from the given Go files except tooling directives, cgo preambles and example output.
package main

import (
	"fmt"
	"go/ast"
	"go/token"
	"os"
	"sort"
	"strings"

	"commentpass/internal/gocomment"
)

func main() {
	paths := splitArgs(os.Args[1:])
	if len(paths) == 0 {
		fmt.Fprintln(os.Stderr, "usage: strip <file.go>...")
		os.Exit(2)
	}
	failed := false
	for _, p := range paths {
		n, err := strip(p)
		switch {
		case err != nil:
			fmt.Fprintf(os.Stderr, "%s: %v\n", p, err)
			failed = true
		case n < 0:
			fmt.Printf("skipped (generated): %s\n", p)
		default:
			fmt.Printf("stripped %d comments: %s\n", n, p)
		}
	}
	if failed {
		os.Exit(1)
	}
}

func splitArgs(args []string) []string {
	var out []string
	for _, a := range args {
		out = append(out, strings.Fields(a)...)
	}
	return out
}

func strip(path string) (int, error) {
	src, err := os.ReadFile(path)
	if err != nil {
		return 0, err
	}
	fset := token.NewFileSet()
	f, err := gocomment.ParseFile(fset, path, src)
	if err != nil {
		return 0, err
	}
	if f == nil {
		return -1, nil
	}

	lines := strings.Split(string(src), "\n")
	gone := make([]bool, len(lines))
	touched := make([]bool, len(lines))
	var doomed []*ast.Comment
	for _, g := range gocomment.Classify(fset, f, path) {
		if g.Directive {
			continue
		}
		for _, c := range g.Comments {
			if !gocomment.IsDirectiveText(c.Text) {
				doomed = append(doomed, c)
			}
		}
	}
	sort.Slice(doomed, func(i, j int) bool { return doomed[i].Pos() > doomed[j].Pos() })

	for _, c := range doomed {
		s, e := fset.Position(c.Pos()), fset.Position(c.End())
		before := lines[s.Line-1][:s.Column-1]
		after := ""
		if e.Column-1 <= len(lines[e.Line-1]) {
			after = lines[e.Line-1][e.Column-1:]
		}
		if strings.TrimSpace(before) == "" && strings.TrimSpace(after) == "" {
			for l := s.Line; l <= e.Line; l++ {
				gone[l-1] = true
			}
			if s.Line >= 2 {
				touched[s.Line-2] = true
			}
			if e.Line < len(lines) {
				touched[e.Line] = true
			}
			continue
		}
		if s.Line == e.Line {
			lines[s.Line-1] = strings.TrimRight(before, " \t") + keepSpace(before, after) + after
			continue
		}
		lines[s.Line-1] = strings.TrimRight(before, " \t")
		for l := s.Line + 1; l < e.Line; l++ {
			gone[l-1] = true
		}
		lines[e.Line-1] = after
	}

	out := make([]string, 0, len(lines))
	for i, l := range lines {
		if gone[i] {
			continue
		}
		if strings.TrimSpace(l) == "" && touched[i] && redundantBlank(out, lines, gone, i) {
			continue
		}
		out = append(out, l)
	}
	return len(doomed), os.WriteFile(path, []byte(strings.Join(out, "\n")), 0o644)
}

func keepSpace(before, after string) string {
	if strings.TrimSpace(before) != "" && strings.TrimSpace(after) != "" {
		return " "
	}
	return ""
}

func redundantBlank(out, lines []string, gone []bool, i int) bool {
	prev := ""
	if len(out) > 0 {
		prev = strings.TrimSpace(out[len(out)-1])
	}
	next := ""
	for j := i + 1; j < len(lines); j++ {
		if !gone[j] {
			next = strings.TrimSpace(lines[j])
			break
		}
	}
	return prev == "" || strings.HasSuffix(prev, "{") || strings.HasSuffix(prev, "(") ||
		strings.HasPrefix(next, "}") || strings.HasPrefix(next, ")")
}
