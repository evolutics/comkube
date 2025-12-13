package kompose

import (
	"errors"
	"fmt"
	"io"
	"os"

	"github.com/kubernetes/kompose/cmd"
)

type ConvertOptions struct {
	Files                 []string
	Namespace             string
	Profiles              []string
	WithKomposeAnnotation bool
}

func Convert(options ConvertOptions) ([]byte, error) {
	// TODO: Consider Kompose convert option `--controller`.
	// TODO: Consider Kompose convert option `--generate-network-policies`.
	// TODO: Consider Kompose convert option `--pvc-request-size`.
	// TODO: Consider Kompose convert option `--secrets-as-files`.
	// TODO: Consider Kompose convert option `--volumes`.
	// TODO: Consider Kompose global option `--error-on-warning`.
	// TODO: Consider Kompose global options `--suppress-warnings`, `--verbose`.
	// TODO: Test that Compose file contents can be given on stdin.

	originalOsArgs := os.Args
	os.Args = append([]string{"kompose"}, convertArguments(options)...)
	defer func() { os.Args = originalOsArgs }()
	return captureStdout(cmd.Execute)
}

func convertArguments(options ConvertOptions) []string {
	var arguments []string

	for _, file := range options.Files {
		arguments = append(arguments, "--file", file)
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

// captureStdout is not thread-safe.
func captureStdout(run func() error) ([]byte, error) {
	reader, writer, err := os.Pipe()
	if err != nil {
		return nil, fmt.Errorf("opening pipe: %w", err)
	}

	errorChannel := make(chan error, 1)

	go func() {
		defer func() { close(errorChannel) }()
		defer func() {
			err := writer.Close()
			if err != nil {
				errorChannel <- fmt.Errorf("closing writer: %w", err)
			}
		}()

		originalStdout := os.Stdout
		defer func() { os.Stdout = originalStdout }()
		os.Stdout = writer

		err := run()
		if err != nil {
			errorChannel <- err
		}
	}()

	var errs []error

	stdout, err := io.ReadAll(reader)
	if err != nil {
		errs = append(errs, fmt.Errorf("reading pipe: %w", err))
	}

	for err := range errorChannel {
		errs = append(errs, err)
	}

	err = errors.Join(errs...)
	if err != nil {
		return nil, err
	}
	return stdout, nil
}
