package kompose

import (
	"fmt"
	"io"
	"os"

	"github.com/kubernetes/kompose/cmd"
)

type ConversionOptions struct {
	Files                 []string
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
	// TODO: Test that Compose file contents can be given on stdin.

	os.Args = append([]string{"kompose"}, conversionArguments(options)...)
	return captureStdout(cmd.Execute)
}

type result[T any] struct {
	value T
	err   error
}

func conversionArguments(options ConversionOptions) []string {
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

	originalStdout := os.Stdout
	defer func() { os.Stdout = originalStdout }()
	os.Stdout = writer

	channel := make(chan result[[]byte])

	go func() {
		stdout, err := io.ReadAll(reader)
		if err != nil {
			channel <- result[[]byte]{err: fmt.Errorf("copying from reader: %w", err)}
			return
		}
		channel <- result[[]byte]{value: stdout}
	}()

	runErr := run()

	err = writer.Close()
	runStdout := <-channel

	if runErr != nil {
		return nil, runErr
	}
	if err != nil {
		return nil, fmt.Errorf("closing writer: %w", err)
	}

	return runStdout.value, runStdout.err
}
