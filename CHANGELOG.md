# Changelog

All notable changes to this project are documented here in a format based on
[Keep a Changelog](https://keepachangelog.com). The project adheres to
[Semantic Versioning](https://semver.org).

## [Unreleased]

### Changed

- Switch design from container kustomize plugin to convenient kubectl plugin.

## [0.2.0] - 2025-11-25

### Added

- Support specifying Compose file paths with `spec.composeFiles`.
- Support specifying Compose profiles with `spec.profiles`.

### Changed

- Rename `spec.model` to `spec.composeFileInline` for clarity.
