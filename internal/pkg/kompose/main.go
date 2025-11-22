package kompose

import (
	"bytes"
	"io"
	"log"
	"os/exec"
	"strings"
)

type ConversionOptions struct {
	Namespace string
	Stdin     io.Reader
}

func Convert(options ConversionOptions) ([]byte, error) {
	// TODO: Support more Kompose options.

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
	arguments = append(arguments, "--stdout", "--with-kompose-annotation=false")

	return arguments
}
