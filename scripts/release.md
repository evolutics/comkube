1. Update [changelog](../CHANGELOG.md).

1. Replace old version (e.g., 2.4.1) by new version (e.g, 3.0.0) in code.

1. Commit:

   ```bash
   git commit --all --message 'Bump version'
   ```

1. Tag:

   ```bash
   git tag --annotate v3.0.0 --message 'v3.0.0'
   ```

1. Test:

   ```bash
   scripts/test.sh
   ```

1. Review.

1. Push commit with tag in one go:

   ```bash
   git push --atomic origin main v3.0.0
   ```

1. Check [image release](https://github.com/evolutics/comkube/actions).
