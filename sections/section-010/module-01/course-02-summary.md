---
draft: true
exam_objectives:
- Continuous Integration Pipelines Overview
---
# Summary

A DAG orders work through acyclic dependency relationships while allowing independent eligible tasks to run concurrently. Data references and dependency conditions must agree so consumers do not start before their required outputs exist.

Failure propagation and fail-fast settings affect scheduling rather than reverse completed effects. Parallelism and resource capacity bound execution, and retries need a safe task contract when work can repeat.
