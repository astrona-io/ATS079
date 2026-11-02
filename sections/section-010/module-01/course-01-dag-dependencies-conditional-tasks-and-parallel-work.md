---
draft: true
exam_objectives:
- Continuous Integration Pipelines Overview
---
# DAG Dependencies, Conditional Tasks And Parallel Work

A Directed Acyclic Graph expresses tasks and the dependency relationships that govern their eligibility. Argo Workflows can use a DAG template to run independent branches concurrently and join them when prerequisites are satisfied. The graph describes execution order, not a universal transaction that reverses every effect when one branch fails.

## Dependencies Establish Eligibility

A task can depend on the successful or otherwise specified outcome of earlier work under the supported dependency syntax. Acyclic means that following dependencies never returns to the same task. A circular dependency would leave no valid forward order for the affected cycle.

Independent tasks can become eligible in parallel, while a join task waits for its required conditions. Eligibility does not guarantee immediate execution because resource capacity, parallelism controls and Kubernetes placement still apply. A graph can be logically ready while its next Pod remains unscheduled.

## Data And Scheduling Must Agree

A downstream task can consume a producer's parameter or artifact output. Its reference identifies the intended data, while the dependency relationship establishes when the consumer may proceed. Review both contracts rather than assume a text reference automatically explains every possible scheduling condition.

Suppose two branches produce regional datasets and a final task combines them. The final task should wait for the required branch outcomes and reference the correct outputs. If one branch is deliberately skipped, the combination logic needs an explicit behavior for the missing data. A syntactically valid reference does not manufacture an output from a task that never ran.

## Conditions Can Describe More Than Success

Supported dependency expressions can distinguish task results and combine conditions. This allows cleanup, alternatives or aggregation behavior appropriate to the pipeline. Older dependency forms and enhanced result expressions have different contracts, so select examples matching the intended version.

A condition should state the business reason for continuing. Proceeding after a failure can be appropriate for collecting diagnostics, but inappropriate for publishing incomplete data as success. The graph's terminal target and final status should reflect what the pipeline actually requires.

## Fail-Fast Affects Scheduling

Fail-fast behavior can stop scheduling additional eligible work after a failure according to the DAG's configuration. Disabling it can allow other independent branches to complete. Neither choice automatically cancels every already running operation or rolls back external side effects.

A branch may have written data before failing, and another may still be completing. Recovery needs to know which outputs are valid and which operations are safe to retry. Use idempotent writes, run identity or another deliberate deduplication model where repeated work can cause harm.

## Bound Parallelism And Interpret Status

A wide DAG can create many eligible tasks. Workflow parallelism and cluster resources constrain actual concurrency. An unavailable node or storage dependency can delay one branch while others progress. Distinguish dependency waiting from infrastructure waiting and application failure.

Task-level status and outputs help reconstruct the first failed transition. Review the graph, result condition, produced data and execution prerequisites in order. This keeps the correction specific and avoids rewriting a valid graph to compensate for unrelated image access or resource exhaustion. A useful DAG makes order, data ownership and failure behavior explicit.

## A Dependency Join

```yaml
dag:
  tasks:
  - name: east
    template: process-region
  - name: west
    template: process-region
  - name: combine
    template: combine-results
    dependencies: [east, west]
```

This template fragment describes two independent branches and a dependent join. The referenced task templates and input or artifact mappings are omitted and must be defined elsewhere. It illustrates ordering rather than a runnable pipeline or output-transfer guarantee.

A continuous integration pipeline uses an execution graph to validate integrated changes and produce known artifacts. A DAG can represent independent checks and prerequisite tasks: source acquisition and dependency resolution precede compatible build work, while publication should depend on required verification. A failed check should not be hidden by a later successful upload. Artifact identity connects the result to the source revision and build inputs. The Argo Workflows example supplies a concrete dependency model; the same reasoning applies to other CI engines. CI proves selected checks over defined inputs rather than automatic production release. Target deployment and continuous runtime management remain separate responsibilities, and the pipeline should not receive unrelated production authority merely to compile code.

## Common pitfalls

> [!WARNING]
> DAG eligibility is not immediate placement or transaction rollback. Dependencies and output references must agree, and fail-fast does not erase already completed side effects.
