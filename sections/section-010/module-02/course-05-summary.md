---
draft: true
exam_objectives:
- Continuous Integration Pipelines Overview
---
# Summary

A CI pipeline is a chain of stages ordered from cheap to expensive. Each stage answers one question about a change: does it fetch, lint, build, test, scan and package. A stage must fail for a reason the developer can act on, and the pipeline stops at the first failed stage so that later stages do not waste capacity. Deployment is not a CI stage. It starts from the artifact that the pipeline publishes.

Tasks run in separate pods, so they share data on purpose. A workspace volume carries files such as build output, and each workflow run gets its own volume. An output parameter carries a short value such as a version or an image reference, and the consumer must depend on the producer. Large values do not belong in parameters.

An artifact needs one identity. A tag can move, so the same tag can mean different builds at different times. A digest is calculated from the content and always names the same bytes. A pipeline builds once per commit, tags with a unique value, records the digest and passes that reference to delivery, so what was tested is what runs.

A repeatable build changes only when a commit changes it. Pinning base images, dependencies and tools removes silent changes, and automated updates keep the pins current through normal reviews. A cache speeds up the build when its key comes from the inputs, and the build must still give the same result without it.

Key facts:

- A tag can be moved by the repository owner, and a digest cannot.
- A parameter holds a short string, and a workspace holds files.
- Build once per commit and promote the same image.
- Pinned inputs change only through a commit.
- A cache key comes from a hash of the inputs.

<!-- astrona:playground:destroy -->
