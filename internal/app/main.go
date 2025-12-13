package app

import (
	"context"

	"github.com/urfave/cli/v3"
)

func Main(arguments []string) error {
	// For CLI design ideas, see also:
	// - https://docs.docker.com/reference/cli/docker/compose/
	// - https://docs.docker.com/reference/cli/docker/compose/down/
	// - https://docs.docker.com/reference/cli/docker/compose/up/
	// - https://kubernetes.io/docs/reference/kubectl/generated/kubectl_apply/
	// - https://kubernetes.io/docs/reference/kubectl/generated/kubectl_delete/
	// - https://kubernetes.io/docs/reference/kubectl/generated/kubectl/

	command := &cli.Command{
		Usage:   "TODO",
		Version: "TODO",

		Flags: []cli.Flag{
			&cli.StringSliceFlag{
				Name:    "file",
				Aliases: []string{"f"},
				Usage:   "Compose config files",
			},
			&cli.StringSliceFlag{
				Name:  "profile",
				Usage: "Enabled Compose profiles",
			},
		},

		Commands: []*cli.Command{
			{
				Name:  "apply",
				Usage: "Apply Compose config to Kubernetes",
				Flags: []cli.Flag{
					&cli.StringFlag{ // TODO: Consider support on upper level.
						Name:    "namespace",
						Aliases: []string{"n"},
						Usage:   "Kubernetes namespace",
					},
					&cli.BoolFlag{
						Name:  "with-debug-annotations",
						Usage: "Whether to annotate Kubernetes manifests with optional metadata",
					},
				},
				Action: func(_ context.Context, command *cli.Command) error {
					return apply(applyOptions{
						Files:                command.StringSlice("file"),
						Namespace:            command.String("namespace"),
						Profiles:             command.StringSlice("profile"),
						WithDebugAnnotations: command.Bool("with-debug-annotations"),
					})
				},
			},
		},
	}

	return command.Run(context.Background(), arguments)
}
