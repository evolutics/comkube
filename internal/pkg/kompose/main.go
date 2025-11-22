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
	Namespace             string
	Stdin                 io.Reader
	WithKomposeAnnotation bool
}

func Convert(options ConversionOptions) ([]byte, error) {
	// TODO: Consider Kompose convert option `--controller`.
	// TODO: Consider Kompose convert option `--generate-network-policies`.
	// TODO: Consider Kompose convert option `--profile`.
	// TODO: Consider Kompose convert option `--pvc-request-size`.
	// TODO: Consider Kompose convert option `--replicas`.
	// TODO: Consider Kompose convert option `--secrets-as-files`.
	// TODO: Consider Kompose convert option `--volumes`.
	// TODO: Consider Kompose global option `--error-on-warning`.
	// TODO: Consider Kompose global option `--file`.
	// TODO: Consider Kompose global option `--provider`.
	// TODO: Consider Kompose global options `--suppress-warnings`, `--verbose`.

	command := exec.Command("kompose", conversionArguments(options)...)
	if options.Stdin != nil {
		command.Stdin = options.Stdin
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

	if options.Stdin != nil {
		arguments = append(arguments, "--file", "-")
	}
	arguments = append(arguments, "convert")
	if options.Namespace != "" {
		arguments = append(arguments, "--namespace", options.Namespace)
	}
	arguments = append(
		arguments,
		"--stdout",
		fmt.Sprintf("--with-kompose-annotation=%v", options.WithKomposeAnnotation),
	)

	return arguments
}
