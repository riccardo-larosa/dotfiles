# Platform Team Design at Scale

## Table of Contents
1. What a Platform Team Actually Is
2. When to Create Platform Teams
3. Structuring a Platform Organization
4. The Internal Product Mindset
5. Golden Paths and Self-Service
6. Measuring Platform Team Success
7. Common Platform Org Structures at 200-400 Engineers

---

## 1. What a Platform Team Actually Is

A platform team exists to reduce the cognitive load on stream-aligned teams by providing self-service capabilities. The key word is *self-service*. If stream-aligned teams need to file tickets, attend meetings, or negotiate priority to use the platform, it's not functioning as a platform — it's a shared services team.

A true platform team:
- Treats stream-aligned teams as internal customers
- Has a product roadmap driven by those customers' needs
- Delivers capabilities through APIs, CLIs, templates, and documentation — not through human intervention
- Measures success by the speed and autonomy of consuming teams, not by the number of tickets resolved

## 2. When to Create Platform Teams

Don't create platform teams prematurely. A common mistake is to form a "platform team" at 30 engineers because it sounds sophisticated. At that size, you don't have enough consuming teams to justify the investment, and the overhead of maintaining a platform exceeds the coordination cost of just doing things ad hoc.

**Create a platform team when:**
- Multiple stream-aligned teams are independently solving the same infrastructure problems (CI/CD, deployment, observability, data pipelines)
- The cognitive load of "running your own stuff" is measurably slowing down stream-aligned teams
- You have at least 5-6 stream-aligned teams that would benefit from shared capabilities
- You can staff the platform team with senior engineers who understand both the technical domain and the user experience of developer tooling

**Don't create a platform team when:**
- You have fewer than 30-40 engineers total
- The "platform" would serve only 1-2 teams
- You're creating it to centralize control rather than to enable autonomy

## 3. Structuring a Platform Organization

At 200-400 engineers, a single "platform team" won't cut it. You need a platform *organization* — multiple teams, each owning a different layer of the developer experience. A common structure:

**Developer Experience (DX) Team**
- Owns: CI/CD pipelines, development environments, code quality tooling, developer portal
- Goal: A new engineer can go from "git clone" to "deployed in staging" in under an hour
- Key metric: Time from commit to production deploy

**Infrastructure / Cloud Platform Team**
- Owns: Cloud infrastructure (IaC), Kubernetes/container orchestration, networking, cost optimization
- Goal: Stream-aligned teams provision and manage infrastructure through self-service without understanding the underlying cloud provider details
- Key metric: Percentage of infrastructure changes that are self-service (no ticket required)

**Data Platform Team**
- Owns: Data pipelines, data warehouse, event streaming, analytics infrastructure
- Goal: Stream-aligned teams can produce and consume data without building custom pipelines
- Key metric: Time from "I need this data" to "I have this data"

**Security / Compliance Platform Team**
- Owns: Security scanning, secrets management, compliance automation, access management
- Goal: Security is built into the golden path, not bolted on as a gate
- Key metric: Percentage of deployments that pass security checks without manual intervention

**Observability Team**
- Owns: Logging, metrics, tracing, alerting infrastructure
- Goal: Any team can understand their service's health without building custom dashboards
- Key metric: Mean time to detect (MTTD) issues

Not every org needs all of these as separate teams. Start with the areas causing the most pain and combine responsibilities where the cognitive load is manageable for a single team.

## 4. The Internal Product Mindset

The most critical shift for platform teams is treating their work as a product, not a project. This means:

**User research:** Regularly interview stream-aligned teams about their pain points. Don't assume you know what they need — ask. Observe how they use (or work around) your tools.

**Roadmap:** Maintain a visible roadmap that consuming teams can see and influence. Prioritize based on impact across the most teams, not on what's technically interesting.

**Documentation as product:** If consuming teams can't figure out how to use your platform without asking you, your documentation is a bug. Treat docs with the same rigor as code.

**Adoption over mandate:** Prefer making your platform so good that teams want to use it, over mandating adoption. Mandates create resentment and workarounds. Good developer experience creates pull.

**Deprecation discipline:** Platform capabilities that are no longer needed or have been superseded should be explicitly deprecated with a migration path. Don't let the platform become a graveyard of abandoned tools.

## 5. Golden Paths and Self-Service

A golden path is a well-supported, opinionated way to accomplish a common task. It's not the only way — teams can diverge if they have a good reason — but it's the default path that "just works."

Examples:
- "To create a new microservice, run `create-service --template standard` and you get a repo with CI/CD, observability, and deployment pre-configured."
- "To add a new database, use the Terraform module in the shared library. It handles provisioning, backup, and access control."
- "To expose a new API endpoint externally, add it to the API gateway config — the platform handles rate limiting, auth, and monitoring."

Golden paths reduce cognitive load because teams don't have to make dozens of incidental decisions for every new project. They also improve consistency — services built on the golden path are easier to operate because they follow predictable patterns.

**Design principles for golden paths:**
- Optimize for the 80% case. Don't try to cover every edge case — that makes the path too complex
- Make it easy to get started and hard to get wrong
- Include observability and security by default, not as add-ons
- Allow teams to eject from the golden path when they need to, but make the on-ramp back smooth

## 6. Measuring Platform Team Success

Platform teams are notoriously hard to measure because their impact is indirect — they make other teams faster, not themselves. Avoid measuring platform teams on output metrics (features shipped, tickets closed) and focus on impact metrics.

**Leading indicators:**
- Developer satisfaction score (survey quarterly)
- Time from commit to production
- Percentage of self-service vs. ticket-based requests
- Onboarding time for new engineers
- Number of stream-aligned teams using the golden path (adoption)

**Lagging indicators:**
- DORA metrics across the organization (deployment frequency, lead time, change failure rate, MTTR)
- Incident rate correlated with platform-provided capabilities
- Infrastructure cost per engineer or per transaction

**Anti-metrics (things that look good but aren't):**
- Number of platform features shipped (output, not outcome)
- Number of tickets resolved (means teams aren't self-service)
- Uptime of the platform itself (necessary but not sufficient — a stable platform nobody uses is still a failure)

## 7. Common Platform Org Structures at 200-400 Engineers

**Structure A: Centralized Platform Group**
All platform teams report to a single platform engineering leader (Director or VP).
- Pro: Clear ownership, unified roadmap, efficient resource allocation
- Con: Can become disconnected from stream-aligned teams' reality

**Structure B: Embedded Platform Pods**
Platform engineers are distributed across business domains, with a dotted line to a central platform lead.
- Pro: Close to the customer, deeply understands domain needs
- Con: Inconsistency across domains, harder to maintain shared standards

**Structure C: Hybrid (Recommended for 200-400)**
A central platform group owns core capabilities (infrastructure, CI/CD, security). Each major business domain has 1-2 "platform liaisons" or "developer advocates" who bridge between the central platform and domain-specific needs.
- Pro: Balances consistency with domain awareness
- Con: The liaison role requires strong people who can context-switch

The right choice depends on how heterogeneous your technology landscape is. If most teams use the same stack, centralized works well. If different domains have fundamentally different technology needs (e.g., ML-heavy vs. CRUD-heavy), embedded or hybrid is better.
