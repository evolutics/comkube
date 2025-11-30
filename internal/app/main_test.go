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

	for _, check := range []struct {
		file        string
		indentation int
	}{
		{"../../examples/basic/kustomization.yaml", 3},
		{"../../examples/basic/my-k8s-compose-app.yaml", 3},
		{"../../examples/container_environment_config/my-k8s-compose-app.yaml", 0},
	} {
		contents, err := os.ReadFile(check.file)
		if err != nil {
			test.Fatal(err)
		}
		codeBlock := fmt.Sprintf("```yaml\n%s```", contents)

		lineStart := regexp.MustCompile(`(^|\n)`)
		indentedBlock := lineStart.ReplaceAllString(
			codeBlock,
			fmt.Sprintf("$1%v", strings.Repeat(" ", check.indentation)),
		)

		if !strings.Contains(readme, indentedBlock) {
			test.Errorf("File not in readme: %v\n%v", check.file, indentedBlock)
		}
	}
}
