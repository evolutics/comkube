package kompose

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os/exec"
	"strings"
)

type ConversionOptions struct {
	ComposeFileInline     io.Reader
	ComposeFiles          []string
	Namespace             string
	Profiles              []string
	WithKomposeAnnotation bool
}

func Convert(options ConversionOptions) ([]byte, error) {
	// TODO: Consider Kompose convert option `--controller`.
	// TODO: Consider Kompose convert option `--generate-network-policies`.
	// TODO: Consider Kompose convert option `--pvc-request-size`.
	// TODO: Consider Kompose convert option `--secrets-as-files`.
	// TODO: Consider Kompose convert option `--volumes`.
	// TODO: Consider Kompose global option `--error-on-warning`.
	// TODO: Consider Kompose global options `--suppress-warnings`, `--verbose`.

	command := exec.Command("kompose", conversionArguments(options)...)
	if options.ComposeFileInline != nil {
		command.Stdin = options.ComposeFileInline
	}

	var stderr strings.Builder
	command.Stderr = &stderr
	var stdout bytes.Buffer
	command.Stdout = &stdout

	err := command.Run()

	if stderr.Len() != 0 {
		log.Print(stderr.String())
	}
	if err != nil {
		return nil, err
	}
	return stdout.Bytes(), nil
}

func conversionArguments(options ConversionOptions) []string {
	var arguments []string

	if options.ComposeFileInline != nil {
		arguments = append(arguments, "--file", "-")
	}
	for _, composeFile := range options.ComposeFiles {
		if composeFile == "-" {
			composeFile = "./-"
		}
		arguments = append(arguments, "--file", composeFile)
	}
	arguments = append(arguments, "convert")
	if options.Namespace != "" {
		arguments = append(arguments, "--namespace", options.Namespace)
	}
	for _, profile := range options.Profiles {
		arguments = append(arguments, "--profile", profile)
	}
	arguments = append(
		arguments,
		"--stdout",
		fmt.Sprintf("--with-kompose-annotation=%v", options.WithKomposeAnnotation),
	)

	return arguments
}
