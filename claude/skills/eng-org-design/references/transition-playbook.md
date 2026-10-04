# Org Transition Playbook

## Table of Contents
1. Before You Start: The Pre-Transition Checklist
2. Communication Strategy
3. Transition Patterns (Small to Large)
4. Managing the Productivity Dip
5. What to Do When It's Not Working
6. Sequencing Multiple Changes

---

## 1. Before You Start: The Pre-Transition Checklist

Before making any structural change, you should be able to answer these questions clearly:

**The Problem**
- What specific problem is this change solving? (Not "we need to modernize" — the actual pain: "Team X can't ship without waiting 3 weeks for Team Y")
- How do we know this is a structural problem and not a process, tooling, or people problem?
- What happens if we don't make this change?

**The Target State**
- What does the new structure look like? (Team names, ownership, reporting lines)
- How does it solve the identified problem?
- What does it sacrifice? (Every structure optimizes for something and gives up something else)

**The Transition**
- Who is affected? (Direct team changes, reporting line changes, scope changes)
- What's the timeline?
- What's the rollback plan if it doesn't work?

**The People**
- Have the affected engineers and managers been consulted (not just informed)?
- Are there career path implications? (Someone losing a direct report, a tech lead role disappearing)
- Is anyone likely to leave because of this change?

If you can't answer these questions, you're not ready to make the change. Do more homework.

## 2. Communication Strategy

The way you communicate an org change matters as much as the change itself. Poor communication turns a good structural decision into a morale disaster.

**Before the announcement:**
- Talk to directly affected people first, privately, before any public announcement. Nobody should learn about their team changing from an all-hands email.
- Talk to the managers first. They need to be prepared to answer questions from their teams.
- Give people time to process. A 1:1 conversation on Monday, team discussions mid-week, broader announcement on Friday.

**The announcement itself:**
- Lead with the why. Not "we're moving to Team Topologies" but "teams have been telling us they can't ship independently because of dependencies on the infrastructure team — here's how we're fixing that."
- Be honest about tradeoffs. "This change optimizes for team autonomy. It means some duplication of effort across teams, and we're accepting that tradeoff."
- Acknowledge the disruption. "This will be uncomfortable for a few months. That's normal and expected."
- Provide a clear timeline. "Week 1: new teams form. Week 2-3: knowledge transfer. Week 4: old structure formally retired."

**After the announcement:**
- Hold explicit Q&A sessions. People will have questions they didn't think of immediately.
- Check in with affected people at 2 weeks, 6 weeks, and 3 months.
- Be open to adjustments. "We got this wrong" is better than stubbornly sticking with a broken plan.

## 3. Transition Patterns (Small to Large)

### Pattern A: The Team Split
**When to use:** A team has grown past 9 people or owns too much.

**How to execute:**
1. Identify the natural seam — usually a domain boundary or a clear separation of concerns in the codebase.
2. Name the two new teams and define their ownership clearly. Write it down.
3. Let the team self-select where possible. Most people have a preference. Only force assignment if self-selection creates an imbalance.
4. Keep both teams in the same physical/virtual space for the first month. They'll need to coordinate the separation.
5. After 1 month, the teams should be operating independently for most of their work.

**Common mistake:** Splitting by technical layer (frontend/backend) instead of by domain. This creates two teams that depend on each other for everything.

### Pattern B: The Team Merge
**When to use:** Two teams are too small to be effective, or their ownership overlaps significantly.

**How to execute:**
1. Be honest about why. If one team is being absorbed, say so. Don't pretend it's a "merger of equals" if it isn't.
2. Decide which team's ways of working will be the default. Trying to blend everything creates chaos.
3. Assign clear ownership. A merged team with two tech leads and overlapping codebases needs someone to make the call on how to consolidate.
4. Budget 4-6 weeks for the merged team to actually merge — align on practices, share context, build trust.

### Pattern C: The New Team
**When to use:** A new initiative, product, or capability that doesn't fit cleanly into any existing team.

**How to execute:**
1. Seed with 2-3 experienced people from existing teams. Don't start a new team entirely with new hires — they need institutional context.
2. Backfill the teams you pulled from. If you don't, you've weakened two teams instead of creating one strong one.
3. Define the new team's mission and boundaries explicitly. "You own X. You don't own Y. For the first 3 months, here are your key milestones."
4. Assign a manager who has bandwidth. Don't give a new team to an already-stretched manager as a "temporary" responsibility.

### Pattern D: The Reorg
**When to use:** Multiple teams need to change simultaneously because the current structure fundamentally doesn't match the work.

**How to execute:**
1. Design the target state completely before starting. Half-planned reorgs create chaos.
2. Announce the full plan at once. Rolling announcements create anxiety — people who haven't been told yet start speculating.
3. Execute in waves if needed (not all teams on the same day), but compress the timeline. A reorg that takes 3 months to complete is 3 months of ambiguity.
4. Assign "transition leads" — specific people responsible for making sure knowledge transfer happens, code ownership is updated, and nothing falls through the cracks.
5. Freeze non-critical hiring during the transition. You don't want to onboard new people into a structure that's actively changing.

## 4. Managing the Productivity Dip

Every org change causes a temporary productivity dip. This is normal and expected. The question is how deep and how long.

**Typical timeline:**
- Weeks 1-2: Excitement and/or anxiety. People are figuring out new relationships. Productivity drops 20-30%.
- Weeks 3-6: The trough. Old habits don't work, new habits haven't formed. People are frustrated. Productivity drops 30-50%.
- Weeks 7-12: Recovery. New patterns emerge. Teams start hitting their stride. Productivity returns to baseline.
- Months 4-6: If the change was good, productivity exceeds the old baseline. If it wasn't, you're still struggling.

**How to shorten the dip:**
- Explicit knowledge transfer sessions (don't assume it'll happen organically)
- Pair programming across old/new team boundaries
- Write down ownership boundaries so there's no ambiguity
- Protect teams from new commitments during the transition — don't pile on new projects during weeks 1-6
- Celebrate small wins early to build momentum

## 5. What to Do When It's Not Working

Sometimes an org change doesn't deliver the expected benefits. Signs to watch for:

**At 6 weeks:**
- Teams are still confused about ownership boundaries → Clarify in writing, hold explicit sessions
- People are frustrated → Expected. Listen, acknowledge, adjust where possible

**At 3 months:**
- Cross-team dependencies haven't improved → The boundaries might be wrong. Investigate which specific dependencies persist and why
- One team is struggling while others thrive → Might be a staffing or leadership issue, not a structural one
- People are leaving because of the change → Take seriously. Exit interviews. Understand if it's the change itself or how it was handled

**At 6 months:**
- The original problem still exists → The structural change wasn't the right intervention. Diagnose again. Consider reverting (which is expensive but better than doubling down on a bad decision)
- New problems have emerged → Expected. Every structure has different tradeoffs. Address the new problems without assuming another reorg is the answer

**The decision to revert:**
Reverting an org change is painful and demoralizing, so don't do it lightly. But if after 6 months the change hasn't delivered measurable improvement on the original problem, and you've given it genuine effort, reverting is better than pretending it's working.

## 6. Sequencing Multiple Changes

Sometimes you need to make several structural changes. The temptation is to do them all at once ("let's just rip off the band-aid"). Resist this unless the changes are tightly coupled.

**Recommended sequencing:**
1. Fix the highest-pain-point first. Get one win before moving on.
2. Wait for the first change to stabilize (usually 2-3 months minimum) before making the next one.
3. Let teams that weren't affected by Change 1 be the next to change. Don't reorganize the same people twice in 6 months.
4. Revisit the plan after each change. The second change might no longer be necessary, or might need to be different, based on what you learned from the first.

**Exception:** If the changes are tightly coupled (e.g., splitting Team A only makes sense if you also create Platform Team B to absorb some of A's current work), do them together. But be explicit about the coupling and plan accordingly.
