---
draft: true
exam_objectives:
- GitOps Basics and Workflows
---
# Managed Runtimes, Agents And Policy Boundaries

A GitOps-managed software system includes more than desired-state files. It contains one or more runtime environments, management agents and policies governing access and operation. A state store supplies authoritative versions, while agents obtain those versions and act on assigned targets. The system boundary should identify these responsibilities clearly so a repository is not mistaken for the complete control mechanism.

Runtime environments can be Kubernetes clusters or other supported targets. Each has resources that agents may manage and resources outside their scope. An agent can be located within a target environment or serve several targets from another location. Placement changes access and availability concerns, but it does not by itself decide whether the system follows the GitOps principles.

Policies define source access, review requirements, target authority and lifecycle behavior. A system can use version control while allowing an overprivileged agent to change unrelated resources. That design may be operationally risky even if its desired files are well structured. GitOps is a management model, not an automatic substitute for least privilege or application security.

Consider a central delivery service managing two application clusters. It reads approved configuration and uses separate target identities. Each identity should have only the intended management scope. A failure in the central service can affect both targets, while a target-specific credential failure may affect only one. Understanding these failure domains helps explain why placement and identity design matter.

Bootstrap establishes the initial trusted path. The first agent, its source reference and necessary credentials must exist before it can manage later changes. Some systems subsequently manage portions of their own configuration, but that does not remove the initial bootstrap and recovery problem. Operators need a known way to restore management if the source credential or agent installation is lost.

Source and target credentials serve different roles. Reading a desired-state repository should not automatically grant permission to modify a cluster. Conversely, a target service identity does not necessarily need write access to the source store. Separating these roles narrows the consequences of compromise and makes audit evidence easier to interpret.

External systems remain important. A declaration can refer to an image registry, secret store or cloud provider. Those services have their own availability and permission contracts. The agent should report blocked dependencies accurately rather than imply that keeping configuration in version control makes every external capability reproducible or always available.

Ownership prevents competing control. Two agents can manage separate namespaces or fields through a deliberate agreement. Two agents imposing incompatible values on the same field can oscillate indefinitely. The management design should establish which source and agent own each relevant resource, including what happens when a declaration is removed or a target is retired.

Observability should connect intent with outcomes. Useful status includes source revision, target identity, reconciliation result and relevant health conditions. A repository commit is evidence of a declared change, not of successful runtime convergence. An agent's process health is evidence of its own operation, not of every application user journey. These distinctions keep the management system's claims precise.

The resulting model is a set of trust and control relationships that students can trace. They should be able to identify who approves intent, who obtains it, who acts, what is managed and which failures remain outside scope. That explanation is more useful than defining GitOps as any workflow that happens to mention Git.

## Common pitfalls

> [!WARNING]
> A repository is not the whole managed system. Bootstrap, recovery, access policy and ownership still need explicit design. Do not give source readers unrelated target authority or assume that referenced external systems inherit the agent's management guarantees.
