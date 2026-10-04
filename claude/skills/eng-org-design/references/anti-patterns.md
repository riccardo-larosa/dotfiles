# Org Design Anti-Patterns at Scale (200-400 Engineers)

## Table of Contents
1. The Component Team Trap
2. The Platform Team That Isn't
3. The Shadow Org
4. The Dependency Web
5. The Reorg Carousel
6. The Architect Bottleneck
7. The "DevOps Team" Fallacy
8. The Feature Factory

---

## 1. The Component Team Trap

**What it looks like:** Teams organized by technical layer — "the frontend team," "the backend team," "the database team," "the mobile team." Every feature requires coordination across 3-4 teams.

**Why it happens:** It feels efficient — specialists working with specialists. Early-stage companies often start here because it maps to hiring (you hire frontend devs, backend devs, etc.) and it's simple to understand.

**Why it fails at scale:** Every feature becomes a cross-team project. Teams compete for priority on each other's backlogs. Delivery speed is gated by the slowest team in the chain. Nobody owns the customer outcome — each team owns a technical slice.

**The fix:** Reorganize around value streams or business domains. Each stream-aligned team should include the skills needed to deliver their domain end-to-end (frontend, backend, and ideally some infrastructure autonomy via platform self-service). This doesn't mean every team needs every specialty — it means the team shouldn't be blocked by another team for most of their routine work.

**Transition approach:** Start with one domain. Take 2-3 people from the frontend team and 2-3 from the backend team who already work on the same features. Form a stream-aligned team. Hire into the gap. Expand from there.

---

## 2. The Platform Team That Isn't

**What it looks like:** A team called "Platform" that is actually a shared services team fielding tickets from other teams. No self-service capabilities, no product thinking, no roadmap. They're an internal service desk with a fancy name.

**Why it happens:** Someone read about platform teams and renamed the infrastructure team without changing how it works. Or the platform team started with good intentions but got pulled into firefighting and ticket work.

**Why it fails:** Stream-aligned teams still can't move independently. They file tickets, wait in a queue, negotiate priority. The "platform" creates a bottleneck instead of removing one. Cognitive load hasn't actually shifted — it's just been moved to a JIRA board.

**The fix:** Platform teams must operate like internal product teams. They need a product manager (or product-minded tech lead), a roadmap, and a north star of reducing friction for stream-aligned teams. Their primary delivery mechanism should be self-service — golden paths, templates, CLIs, internal developer portals — not ticket resolution.

**Key metric:** How many stream-aligned team requests can be fulfilled without human intervention from the platform team? If it's below 80%, the platform isn't self-service enough.

---

## 3. The Shadow Org

**What it looks like:** The org chart says one thing, but the actual work flows differently. "Dotted line" reporting creates confusion about who makes decisions. Influential ICs or informal leaders hold more sway than the nominal team leads. Important decisions happen in Slack DMs or hallway conversations, not in the structures designed for them.

**Why it happens:** The formal structure hasn't kept up with how work actually gets done. Or a reorg happened on paper but people kept working the old way because the new structure didn't match reality.

**Why it fails:** New hires can't figure out how things actually work. Decision-making is unpredictable. People who aren't in the informal network get excluded. Accountability is diffuse — when something goes wrong, it's unclear who owned the decision.

**The fix:** Make the shadow org the real org. If certain people are de facto decision-makers, formalize that authority. If work flows across team boundaries in a consistent pattern, redraw the boundaries. The org chart should describe reality, not aspirations.

---

## 4. The Dependency Web

**What it looks like:** To ship a feature, a team needs changes from 3 other teams. Planning involves complex dependency mapping. Quarterly planning is a multi-week negotiation. Teams spend more time coordinating than building.

**Why it happens:** Team boundaries were drawn around technical components rather than business capabilities. Or a shared monolith forces teams to coordinate deployments. Or "shared" services are owned by one team but required by many.

**Why it fails:** Delivery speed is limited by the most constrained team in the chain. Cross-team work requires synchronization, meetings, handoffs, and waiting. Innovation is impossible when every change requires buy-in from four teams.

**The fix:** Redesign team boundaries so that the most common work can be done within a single team. This often means giving teams more end-to-end ownership, even if it means some code duplication. A little duplication is cheaper than constant cross-team coordination. For genuinely shared capabilities, invest in making them true services with stable APIs that consuming teams can use without coordination.

---

## 5. The Reorg Carousel

**What it looks like:** Major org restructuring every 6-12 months. Each new VP brings a new model. Teams barely settle in before they're reshuffled. "We're reorganizing again" is met with eye-rolls.

**Why it happens:** Leaders mistake structural change for progress. Or the org keeps addressing symptoms (slow delivery, low morale) without diagnosing the root cause. Or leadership turnover brings conflicting visions.

**Why it fails:** Each reorg costs 2-3 months of reduced productivity. Teams never build the deep context and relationships needed for high performance. Good people leave because they're tired of the instability. Institutional knowledge gets lost in the shuffle.

**The fix:** Commit to stability. Set a minimum 18-month tenure for any org structure before considering major changes. Prefer small, incremental adjustments (moving one team, splitting one team) over wholesale restructuring. When a new leader joins, require them to observe for 90 days before making structural changes.

---

## 6. The Architect Bottleneck

**What it looks like:** A central architecture team or chief architect who must approve all significant technical decisions. Teams propose designs, wait for review, get feedback, revise, resubmit. The architect(s) become the critical path for every initiative.

**Why it happens:** Legitimate concern about architectural coherence as the system grows. Fear that autonomous teams will make inconsistent decisions. A strong individual contributor who accumulated authority over time.

**Why it fails at scale:** One person or team cannot review every decision for 200+ engineers without becoming a bottleneck. Decisions queue up. Teams learn to either wait (slow) or make decisions without approval and ask forgiveness later (inconsistent). The architects become disconnected from implementation reality.

**The fix:** Distribute architectural authority. Each stream-aligned team should have a senior engineer empowered to make architectural decisions within their domain. Establish lightweight architectural principles (not detailed rules) that guide decisions. Use RFCs or ADRs (Architecture Decision Records) for significant cross-cutting decisions, with review as a collaborative process rather than a gate. The architect role shifts from approver to advisor and pattern-recognizer.

---

## 7. The "DevOps Team" Fallacy

**What it looks like:** A team called "DevOps" that owns all CI/CD, deployment, monitoring, and infrastructure. Other teams throw code over the wall to DevOps for deployment. DevOps is overwhelmed and becomes a bottleneck.

**Why it happens:** The organization heard "you need DevOps" and interpreted it as "you need a DevOps team," missing the point that DevOps is a culture and set of practices, not a team.

**Why it fails:** It recreates the old dev/ops divide with a trendy name. Stream-aligned teams don't own their deployments or operational health. The DevOps team can't scale — adding one more service to manage means they need more people, indefinitely.

**The fix:** Enable stream-aligned teams to own their own deployment and operations via platform self-service. The platform team builds the CI/CD pipelines, deployment tools, and observability stack. Stream-aligned teams use these tools to deploy and monitor their own services. "You build it, you run it" — but with excellent platform support so running it isn't a cognitive overload.

---

## 8. The Feature Factory

**What it looks like:** Teams measured purely on feature output — story points completed, PRs merged, features shipped. No measurement of impact, quality, or customer outcomes. Teams churn through a backlog of feature requests without understanding why.

**Why it happens:** It's easier to count features than to measure impact. Product management passes down feature specs without sharing the strategic context. OKRs are written as output metrics ("ship X features") rather than outcome metrics ("reduce churn by Y%").

**Why it fails:** Teams build features nobody uses. Technical debt accumulates because there's no time allocated for quality work. Engineers are demoralized because they don't see the impact of their work. The system becomes increasingly fragile.

**The fix:** Give teams ownership of outcomes, not outputs. Each stream-aligned team should understand the business metric they're trying to move. Allocate explicit capacity for technical debt, reliability, and developer experience work — not as a favor, but as a first-class priority. Measure teams on customer impact, system health, and engineering effectiveness (DORA metrics are a good starting point) alongside delivery.
