package kompose

import (
	"bytes"
	"io"
	"log"
	"os/exec"
	"strings"
)

func Convert(stdin io.Reader) ([]byte, error) {
	// TODO: Support more Kompose options.

	command := exec.Command("kompose")
	if stdin != nil {
		command.Args = append(command.Args, "--file", "-")
		command.Stdin = stdin
	}
	command.Args = append(command.Args, "convert", "--stdout")

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
