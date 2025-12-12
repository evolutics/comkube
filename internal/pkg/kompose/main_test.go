package kompose

import (
	"fmt"
	"os"
	"testing"
)

func TestCaptureStdout(test *testing.T) {
	fmt.Println("Before")
	stdout, err := captureStdout(func() error {
		fmt.Println("Hello")
		_, err := fmt.Fprintln(os.Stderr, "Hi")
		if err != nil {
			return err
		}
		_, err = fmt.Fprintln(os.Stdout, "world")
		if err != nil {
			return err
		}
		return nil
	})
	fmt.Println("After")

	if err != nil {
		test.Error(err)
	}
	if string(stdout) != "Hello\nworld\n" {
		test.Errorf("stdout: %q", stdout)
	}
}
