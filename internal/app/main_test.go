package main_test

import (
	"fmt"
	"os"
	"regexp"
	"strings"
	"testing"
)

func TestReadmeHasUpToDateFiles(test *testing.T) {
	rawReadme, err := os.ReadFile("../../README.md")
	if err != nil {
		test.Fatal(err)
	}
	readme := string(rawReadme)

	for _, file := range []string{
		"../../example/kustomization.yaml",
		"../../example/my-k8s-compose-app.yaml",
	} {
		contents, err := os.ReadFile(file)
		if err != nil {
			test.Fatal(err)
		}
		codeBlock := fmt.Sprintf("```yaml\n%s```", contents)

		lineStart := regexp.MustCompile(`(^|\n)`)
		indentedBlock := lineStart.ReplaceAllString(codeBlock, "$1   ")

		if !strings.Contains(readme, indentedBlock) {
			test.Errorf("File not in readme: %v\n%v", file, indentedBlock)
		}
	}
}
