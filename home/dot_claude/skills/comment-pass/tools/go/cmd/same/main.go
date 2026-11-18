// Command same proves Go files differ from a git ref by comments alone, and that no tooling directive was lost.
package main

import (
	"bytes"
	"fmt"
	"go/parser"
	"go/printer"
	"go/token"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"commentpass/internal/gocomment"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintln(os.Stderr, "usage: same <repo> <base-ref> [file.go...]")
		os.Exit(2)
	}
	repo, base := os.Args[1], os.Args[2]
	paths := splitArgs(os.Args[3:])
	if len(paths) == 0 {
		paths = changed(repo, base)
	}

	bad := 0
	for _, p := range paths {
		verdict := compare(repo, base, p)
		fmt.Printf("%s: %s\n", verdict, p)
		if verdict != "comments only" && verdict != "unchanged" {
			bad++
		}
	}
	fmt.Printf("%d files, %d failing\n", len(paths), bad)
	if bad > 0 {
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

func changed(repo, base string) []string {
	out, err := exec.Command("git", "-C", repo, "diff", "--name-only", base, "--", "*.go").Output()
	if err != nil {
		fmt.Fprintf(os.Stderr, "git diff: %v\n", err)
		os.Exit(2)
	}
	return strings.Fields(string(out))
}

func compare(repo, base, rel string) string {
	old, err := exec.Command("git", "-C", repo, "show", base+":"+rel).Output()
	if err != nil {
		return "CODE CHANGED (not in base)"
	}
	cur, err := os.ReadFile(filepath.Join(repo, rel))
	if err != nil {
		return "CODE CHANGED (deleted)"
	}
	if bytes.Equal(old, cur) {
		return "unchanged"
	}

	oldCode, oldDirectives, err := render(rel, old)
	if err != nil {
		return "PARSE ERROR in base: " + err.Error()
	}
	curCode, curDirectives, err := render(rel, cur)
	if err != nil {
		return "PARSE ERROR: " + err.Error()
	}
	if oldCode != curCode {
		return "CODE CHANGED"
	}
	if missing := lost(oldDirectives, curDirectives); len(missing) > 0 {
		return "DIRECTIVE REMOVED " + strings.Join(missing, ", ")
	}
	return "comments only"
}

func render(name string, src []byte) (string, []string, error) {
	fset := token.NewFileSet()
	withComments, err := parser.ParseFile(fset, name, src, parser.ParseComments)
	if err != nil {
		return "", nil, err
	}
	var directives []string
	for _, g := range gocomment.Classify(fset, withComments, name) {
		for _, c := range g.Comments {
			if g.Directive || gocomment.IsDirectiveText(c.Text) {
				directives = append(directives, strings.TrimSpace(c.Text))
			}
		}
	}

	bare, err := parser.ParseFile(token.NewFileSet(), name, src, 0)
	if err != nil {
		return "", nil, err
	}
	var b bytes.Buffer
	if err := printer.Fprint(&b, token.NewFileSet(), bare); err != nil {
		return "", nil, err
	}
	return b.String(), directives, nil
}

func lost(before, after []string) []string {
	have := map[string]int{}
	for _, d := range after {
		have[d]++
	}
	var missing []string
	for _, d := range before {
		if have[d] > 0 {
			have[d]--
			continue
		}
		missing = append(missing, d)
	}
	sort.Strings(missing)
	return missing
}
