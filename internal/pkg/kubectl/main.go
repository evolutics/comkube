package kubectl

import (
	"io"
	"os"
	"os/exec"
)

type ApplyOptions struct {
	Config io.Reader
}

func Apply(options ApplyOptions) error {
	// TODO: Consider kubectl global options.
	// TODO: Consider more kubectl apply options.
	command := exec.Command("kubectl", "apply", "--filename=-")

	command.Stdin = options.Config
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr

	return command.Run()
}
