package v1alpha1

import (
	"bytes"
	"io"
	"log"
	"os/exec"
	"strings"

	"sigs.k8s.io/kustomize/kyaml/errors"
	"sigs.k8s.io/kustomize/kyaml/kio"
	"sigs.k8s.io/kustomize/kyaml/yaml"
)

type App struct {
	Spec interface{} `json:"spec" yaml:"spec"`
}

func (app App) Filter(items []*yaml.RNode) ([]*yaml.RNode, error) {
	var stdin *bytes.Reader
	if app.Spec != nil {
		composeConfig, err := yaml.Marshal(app.Spec)
		if err != nil {
			return nil, errors.WrapPrefixf(err, "serializing Compose config")
		}
		stdin = bytes.NewReader(composeConfig)
	}

	stdout, err := convertComposeToK8sWithKompose(stdin)
	if err != nil {
		return nil, errors.WrapPrefixf(err, "converting with Kompose")
	}

	k8sManifests, err := (&kio.ByteReader{Reader: stdout}).Read()
	if err != nil {
		return nil, errors.WrapPrefixf(err, "deserializing K8s manifests")
	}

	return append(items, k8sManifests...), nil
}

func convertComposeToK8sWithKompose(stdin *bytes.Reader) (io.Reader, error) {
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
	return &stdout, nil
}
