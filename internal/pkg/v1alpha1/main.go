package v1alpha1

import (
	"bytes"
	"io"

	"github.com/evolutics/comkube/internal/pkg/kompose"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/kustomize/kyaml/errors"
	"sigs.k8s.io/kustomize/kyaml/kio"
	"sigs.k8s.io/kustomize/kyaml/yaml"
)

type App struct {
	metav1.ObjectMeta `json:"metadata"`
	Spec              Spec `json:"spec" yaml:"spec"`
}

type Spec struct {
	Model                any  `json:"model" yaml:"model"`
	WithDebugAnnotations bool `json:"withDebugAnnotations" yaml:"withDebugAnnotations"`
}

func (app App) Filter(items []*yaml.RNode) ([]*yaml.RNode, error) {
	// TODO: Give `envs` hint if required env vars are undefined.
	// TODO: Give `mounts` hint if Compose file is missing.

	var stdin io.Reader
	if app.Spec.Model != nil {
		composeModel, err := yaml.Marshal(app.Spec.Model)
		if err != nil {
			return nil, errors.WrapPrefixf(err, "serializing Compose model")
		}
		stdin = bytes.NewReader(composeModel)
	}

	// TODO: Pass `metadata.namespace` as `--namespace` if given.
	stdout, err := kompose.Convert(kompose.ConversionOptions{
		Namespace:             app.Namespace,
		Stdin:                 stdin,
		WithKomposeAnnotation: app.Spec.WithDebugAnnotations,
	})
	if err != nil {
		return nil, errors.WrapPrefixf(err, "converting with Kompose")
	}

	k8sManifests, err := kio.FromBytes(stdout)
	if err != nil {
		return nil, errors.WrapPrefixf(err, "deserializing K8s manifests")
	}

	return append(items, k8sManifests...), nil
}
