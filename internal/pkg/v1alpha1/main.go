package v1alpha1

import (
	"bytes"
	"io"

	"github.com/evolutics/comkube/internal/pkg/kompose"
	"sigs.k8s.io/kustomize/kyaml/errors"
	"sigs.k8s.io/kustomize/kyaml/kio"
	"sigs.k8s.io/kustomize/kyaml/yaml"
)

type App struct {
	Spec any `json:"spec" yaml:"spec"`
}

func (app App) Filter(items []*yaml.RNode) ([]*yaml.RNode, error) {
	var stdin io.Reader
	if app.Spec != nil {
		composeConfig, err := yaml.Marshal(app.Spec)
		if err != nil {
			return nil, errors.WrapPrefixf(err, "serializing Compose config")
		}
		stdin = bytes.NewReader(composeConfig)
	}

	stdout, err := kompose.Convert(stdin)
	if err != nil {
		return nil, errors.WrapPrefixf(err, "converting with Kompose")
	}

	k8sManifests, err := kio.FromBytes(stdout)
	if err != nil {
		return nil, errors.WrapPrefixf(err, "deserializing K8s manifests")
	}

	return append(items, k8sManifests...), nil
}
