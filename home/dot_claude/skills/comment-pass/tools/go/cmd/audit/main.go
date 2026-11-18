// Command audit counts and classifies the prose comments under a Go tree and lists what breaks the comment rules.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"go/ast"
	"go/token"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"commentpass/internal/gocomment"
)

type record struct {
	File      string `json:"file"`
	Line      int    `json:"line"`
	Lines     int    `json:"lines"`
	Kind      string `json:"kind"`
	Decl      string `json:"decl"`
	Exported  bool   `json:"exported"`
	Test      bool   `json:"test"`
	Violation string `json:"violation,omitempty"`
	Text      string `json:"text"`
}

func main() {
	jsonOut := flag.String("json", "", "write every prose comment group as JSON to this file")
	list := flag.String("list", "violations", "what to print in full: violations, in-body, all, none")
	match := flag.String("match", "", "only print groups whose text matches this regexp")
	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, "usage: audit [-json file] [-list violations|in-body|all|none] [-match regexp] <root>")
	}
	flag.Parse()
	if flag.NArg() != 1 {
		flag.Usage()
		os.Exit(2)
	}
	root := flag.Arg(0)

	var records []record
	err := gocomment.Walk(root, func(rel string, fset *token.FileSet, f *ast.File, _ []byte) {
		for _, g := range gocomment.Classify(fset, f, rel) {
			if g.Directive || onlyDirectives(g) {
				continue
			}
			records = append(records, record{
				File: rel, Line: g.StartLine, Lines: g.Lines(), Kind: g.Kind, Decl: g.Decl,
				Exported: g.Exported, Test: g.Test, Violation: g.Violation(), Text: g.Text,
			})
		}
	})
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	if *jsonOut != "" {
		b, _ := json.MarshalIndent(records, "", "  ")
		if err := os.WriteFile(*jsonOut, b, 0o644); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	}

	byDir(records)
	byKind(records)
	printList(records, *list, *match)
}

func onlyDirectives(g gocomment.Group) bool {
	for _, c := range g.Comments {
		if !gocomment.IsDirectiveText(c.Text) {
			return false
		}
	}
	return true
}

func byDir(records []record) {
	lines, groups := map[string]int{}, map[string]int{}
	total := 0
	for _, r := range records {
		d := filepath.Dir(r.File)
		lines[d] += r.Lines
		groups[d]++
		total += r.Lines
	}
	dirs := make([]string, 0, len(lines))
	for d := range lines {
		dirs = append(dirs, d)
	}
	sort.Slice(dirs, func(i, j int) bool { return lines[dirs[i]] > lines[dirs[j]] })
	fmt.Printf("== comment lines by package (total %d)\n", total)
	for _, d := range dirs {
		fmt.Printf("%6d lines %5d groups  %s\n", lines[d], groups[d], d)
	}
}

func byKind(records []record) {
	lines, groups := map[string]int{}, map[string]int{}
	for _, r := range records {
		k := r.Kind
		switch {
		case k == "package":
		case r.Test:
			k = "test " + k
		case r.Exported:
			k = "exported " + k
		default:
			k = "unexported " + k
		}
		lines[k] += r.Lines
		groups[k]++
	}
	kinds := make([]string, 0, len(lines))
	for k := range lines {
		kinds = append(kinds, k)
	}
	sort.Strings(kinds)
	fmt.Println("== by kind")
	for _, k := range kinds {
		fmt.Printf("%6d lines %5d groups  %s\n", lines[k], groups[k], k)
	}
}

func printList(records []record, list, match string) {
	var re *regexp.Regexp
	if match != "" {
		re = regexp.MustCompile(match)
	}
	violations := 0
	var picked []record
	for _, r := range records {
		if r.Violation != "" {
			violations++
		}
		keep := list == "all" || (list == "violations" && r.Violation != "") || (list == "in-body" && r.Kind == "in-body")
		if keep && (re == nil || re.MatchString(r.Text)) {
			picked = append(picked, r)
		}
	}
	fmt.Printf("== violations: %d\n", violations)
	if list == "none" {
		return
	}
	fmt.Printf("== %s (%d)\n", list, len(picked))
	for _, r := range picked {
		label := r.Kind
		if r.Decl != "" {
			label += " " + r.Decl
		}
		if r.Violation != "" {
			label += ", " + r.Violation
		}
		fmt.Printf("%s:%d [%s]\n", r.File, r.Line, label)
		for _, l := range strings.Split(r.Text, "\n") {
			fmt.Printf("    %s\n", l)
		}
	}
}
