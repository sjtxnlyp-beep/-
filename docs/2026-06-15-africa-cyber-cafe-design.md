# Africa Cyber Cafe Tycoon v2.0 Design

Date: 2026-06-15
Status: Design approved for review
Scope: Reframe the existing Tap Maker / UrhoX project around a stronger first-30-days experience, without rebuilding the game from scratch.

## 1. Product Direction

The game should not be a pure cyber cafe simulator, and it should not become a generic esports manager.

The core fantasy is:

> A young Chinese person fails to find work at home, is talked into going to Africa for one last chance, and accidentally takes over a broken cyber cafe. At first they only want to survive. Through the local street, a gifted Delta Force player, and the people around the cafe, they slowly decide what kind of boss they will become.

The game has three pillars:

- Survival pressure: cash, rent, power, broken equipment, weak traffic, and business competition.
- Local street stories: neighbors, students, food stalls, repair shops, landlords, regular customers, parents, and gray-market traders.
- Dragon Force: a Delta Force team born from one gifted local teenager and gradually supported by the street.

The player's central question is not "Can I get rich?" It is:

> In a place where survival is hard, do I become a trusted street boss, a ruthless winner, or another Victor?

## 2. Current Project Strategy

Do not restart the project.

The current codebase already contains valuable production assets:

- Day/action loop
- Event systems
- Training and match systems
- NPC storylines
- Market and item systems
- Prestige/city systems
- Ads and save/load
- Existing UI framework
- Image/audio/promo assets

The correct strategy is a major v2.0 experience refactor, not a blank rewrite.

The refactor should:

- Preserve the existing Tap Maker / UrhoX runtime structure.
- Reuse current UI panels and event presentation patterns.
- Reorganize content around the first 30 days.
- Reframe current systems under a clearer main arc.
- Avoid adding large new systems before the core loop is emotionally coherent.

Recommended version theme:

> v2.0: Exile, Survival, and the Birth of Dragon Force

## 3. Story Premise

### Opening

The protagonist cannot find work in China. They have debt, family pressure, or a personal sense of failure. A familiar contact says there is a cyber cafe opportunity in Africa: low cost, high demand, easy upside.

The protagonist uses their last money to go.

When they arrive, the "mature business" is a rusted tin-roof cafe with old PCs, unstable power, unpaid rent, and almost no customers.

The previous owner or landlord, Musa, is not a simple villain. He hid the risk, but he was also desperate. The first major choice should let the player decide whether to:

- Pressure Musa and renegotiate hard.
- Accept the loss and start working.
- Make a human compromise, such as lower rent, shared risk, or delayed payment.

### Kofi and Dragon Force

The player meets a local teenager, Kofi, who plays Delta Force on bad hardware with shocking skill. This should be the moment the game changes from "survive in a broken cafe" to "maybe this place has unseen talent."

Dragon Force is not a menu unlocked on day one. It is born from story:

- First free play or discounted play for Kofi.
- First small street challenge.
- First moment where someone says this could be a team.
- First naming of Dragon Force.

### Victor

Victor begins as a clear pressure source: richer cafe, better equipment, local connections, and contempt for the protagonist's broken operation.

Over time he becomes a mirror. He also came from difficulty, but chose money, control, and gray methods. His role is to ask the player:

- Can kindness pay rent?
- Will you protect players if it costs you a win?
- Do rules matter when rich people wrote them?
- Are you building something different, or only replacing him?

## 4. Core Loop

The core loop is:

> 3 daily actions + 1 weekly major node

This is suitable for mobile and Tap Maker. Pressure comes from choosing what not to do.

### Daily Start

Each day should show:

- Cafe status: cash, equipment condition, power/fuel, traffic, reputation.
- Team status: player mood, fatigue, training progress, match countdown.
- Street status: urgent local story, current relationship tension, Victor pressure.
- One main goal: the single most important next step.

### Daily Actions

The player has 3 action points per day. Action categories:

- Business: repair, upgrade, flyers, stock, rent, cashflow.
- Street: help NPCs, resolve disputes, build trust, gather information.
- Team: train, recruit, review matches, choose tactics, handle player life issues.
- Gray: black-market hardware, underground matches, fake reviews, poaching, sabotage.
- Recovery: rest, team meal, talk to parents, reduce pressure, rebuild morale.

### End of Day

End-of-day should resolve:

- Revenue and expense
- Equipment wear
- Power/fuel risk
- Player growth and pressure
- Street relationship changes
- Victor/AEL progress
- Tomorrow preview

Avoid stacking too many popups. The daily close should emphasize one important consequence and one next hook.

### Weekly Nodes

Every 7 days there is a memorable event:

- Week 1: Survive the broken cafe and form the idea of Dragon Force.
- Week 2: Victor notices and starts pressure.
- Week 3: First official match.
- Week 4: AEL attention and moral route split.
- Later weeks: city expansion, underground temptation, major street crisis, away matches.

## 5. Street Story System

Street stories have three layers.

### Daily Street Events

Short, frequent, reactive events. They provide smoke, texture, and immediate decisions.

Examples:

- Mama B cannot afford stock for her food stall.
- The repair shop wants to borrow power.
- A student wants to use the cafe for homework but actually wants to train.
- A regular asks to pay later.
- A power outage makes the cafe the only lit place on the street.

Each event should affect at least two things:

- Visible result: cash, reputation, traffic, equipment, mood.
- Hidden ledger: humanity, integration, exploitation, gray conduct, team pressure.

### NPC Arcs

Core NPCs should each have 3-5 stages. Initial roster:

- Kofi: first gifted teenager and emotional spark.
- Mama B: food stall owner and street information center.
- Grace: calm player or gifted girl facing family/social pressure.
- Repair shop owner: equipment ally and practical street support.
- Ama: student interested in technology, data, and the future.
- Musa: landlord/previous owner who begins as a source of conflict.
- Victor: rival and mirror.

NPC arcs should change gameplay:

- Kofi resolved well: better clutch/pressure handling.
- Mama B close relationship: match-day morale and traffic.
- Repair shop ally: repair discount, emergency power/equipment help.
- Ama arc: unlocks better review, automation, or tactical analysis.
- Musa reconciliation: rent relief or protection from eviction.

### Chapter Street Mainline

Each week or chapter centers on one street problem:

- Survival
- Competition
- First match
- AEL scrutiny
- Expansion
- City departure or return

Every important story should change one of:

- How an NPC sees the player.
- How the street supports or resists the cafe.
- How Dragon Force trains, competes, or handles pressure.

## 6. Dragon Force Team System

The team system should be medium strategy with small minigame accents.

It should not become a full real-time shooter. It should feel like managing people under pressure.

### Player Attributes

Each team member should have:

- Technical ability: aim, reaction, awareness, teamwork.
- Role: entry, scout, sniper, caller, support.
- Mental traits: stable, impulsive, clutch, self-blaming, stubborn.
- Life pressure: family, school, money, prejudice, gray ties.
- Bonds: protagonist, teammates, street NPCs.

### Training

Training is a tradeoff:

- Hard training improves skills but raises fatigue/pressure.
- Rest slows growth but protects morale.
- Underground practice gives fast progress but creates gray risk.
- Street support can improve morale, focus, or equipment.

Training should often ask:

- Do we train Kofi hard or solve his home problem?
- Do we repair PCs or practice before the match?
- Do we take a risky underground opportunity?
- Do we give the team a break before burnout?

### Match Structure

Match flow:

1. Pre-match decisions:
   - Lineup
   - Tactical style
   - Handling a sudden problem
2. Match moments:
   - 1-2 key situation choices
3. Result:
   - Money
   - Reputation
   - Team mood/fatigue
   - Street reaction
   - Victor/AEL response

Possible match moments:

- Kofi is being targeted. Keep him as carry or shift strategy?
- Grace sees the enemy habit. Trust her call?
- Referee seems biased. Protest or stay focused?
- A teammate offers gray intel. Use it or refuse?

Winning should not always mean the best outcome. A clean, honorable loss can increase street support. A gray win can damage long-term trust.

## 7. Consequence and Ending System

The consequence model:

> Short-term sweetness, long-term cost; immediate feedback as support, ending ledger as final reckoning.

### Hidden Axes

Do not expose them as a moral score UI. Track them behind the scenes and reflect them in diary, NPC reactions, and endings.

Axes:

- Money vs relationships
- Results vs player lives
- Integration vs extraction
- Legal vs gray

### Consequence Timing

- Immediate: money, reputation, traffic, equipment, mood.
- 3-7 days later: NPC attitude, pressure, rumors, Victor reaction.
- Weekly node: street support, team trust, crisis result.
- Ending: route and final state.

### Ending Families

Initial ending set:

- Street Light: not necessarily richest, but trusted by the street and team.
- Champion Factory: wins a lot, but players are damaged or alienated.
- Money Machine: expands successfully, but the street remains only a market.
- African Esports Bridge: high integration, clean methods, strong team, sustainable ecosystem.
- Underground Empire: fast gray expansion; Victor falls, but the player becomes worse.
- Failed but Held: business collapses, but if relationships are strong, the street helps the player restart.

Victor should be used to compare the player's route. The best ending is not just defeating Victor. It is defeating him without becoming him.

## 8. First 4 Weeks

### Day 0: Failure and Departure

Format: comic/dialogue intro.

Events:

- Job rejection in China.
- Last money and debt/family pressure.
- Contact suggests an African cafe opportunity.
- Player chooses an opening attitude: desperate, defiant, pragmatic.

Impact:

- Mostly flavor.
- Small hidden initial tendency.

### Week 1: Survive the Broken Cafe

Goals:

- Learn business survival.
- Meet local street.
- Discover Kofi.

Key beats:

- Take over broken cafe.
- First customer.
- Kofi's talent scene.
- Mama B, Musa, repair shop owner appear.
- First small challenge.
- Dragon Force name appears.

Representative choices:

- Charge Kofi normally, discount him, or let him play free.
- Fix hardware now or save cash.
- Help Mama B or protect cashflow.
- Fight Musa or negotiate.

Weekly node:

- Kofi joins, or commits to trying.

### Week 2: Victor Notices

Goals:

- Add pressure.
- Introduce competitor.
- Show route split.

Key beats:

- Gold Net price war.
- Suspicious photo of equipment.
- Fake bad reviews.
- Regular customers start comparing cafes.
- Second/third recruit appears.
- Victor first confrontation.

Choices:

- Compete on quality, discounts, street trust, or gray retaliation.
- Protect team morale or chase quick wins.
- Use street support or use dirty tricks.

Weekly node:

- Victor tells the player the street runs on money, not dreams.

### Week 3: First Official Match

Goals:

- Make Dragon Force the main hope.
- Stress the team as people.

Key beats:

- Local league or AEL invite.
- Kofi's family pressure.
- Grace or another player faces a personal barrier.
- Training conflicts with cashflow.
- Street support depends on earlier choices.

Match:

- Select lineup.
- Select tactic.
- Resolve 1-2 key match moments.

Weekly node:

- Dragon Force becomes visible to the street, win or lose.

### Week 4: AEL Scrutiny and Route Split

Goals:

- Begin long-term moral accounting.
- Create mid-game direction.

Key beats:

- AEL notices the cafe/team.
- Sponsorship is possible.
- AEL checks gray behavior, equipment source, player welfare.
- Victor becomes more complex.
- Street reaction diverges based on player conduct.

Weekly node:

- Gain AEL bronze sponsorship, miss it, or lean into underground route.

## 9. Content Volume Plan

The first release target should support at least 30 in-game days.

Minimum content plan:

- Main weeks: 4
- Daily street events: 60+
- Core NPC arcs: 7 NPCs x 4 stages = 28 stages
- Recruitable team members: 6-8
- Match situation events: 30+
- Victor pressure events: 12-16
- Gray temptation events: 15+
- Street crisis events: 8-10
- Ending families: 6, each with 2-3 variants
- Tomorrow preview hooks: D1-D30, at least one per day or condition group

Event pools:

- Survival/business
- Street relationships
- Team growth
- Victor pressure
- Gray opportunity
- Local culture/flavor

Content quality rules:

- No repeated core event in the first 7 days.
- Mainline hook every day through day 14.
- At least one memorable event every 3 days through day 30.
- Every core NPC has one fate-changing choice.
- Every gray route has at least one sweet payoff and one later backlash.

## 10. UI Style Guide

The UI should express:

- Heat, dust, neon, tin-roof survival.
- Warm local street life.
- Tactical esports energy.
- Clear mobile-first decisions.

Avoid making the UI look like a generic idle game or a cold esports dashboard.

### Global Visual Language

Style keywords:

- Tin-roof startup
- African street evening
- Warm pixel realism
- Worn metal and hand-painted signs
- Neon esports accents used sparingly

Core palette:

- Background: deep warm brown / near-black coffee.
- Surface: dark wood, worn metal, smoky amber.
- Primary action: warm gold or burnt orange.
- Positive: vivid but grounded green.
- Danger: dusty red, not pure alarm red.
- Tactical highlight: limited cyan/blue for esports/AEL moments.

Typography:

- Chinese UI text should be highly readable.
- Use bold display text only for title, chapter, and weekly nodes.
- Avoid excessive mixed Chinese/English in core UI. English can be used for team names, AEL, Dragon Force, and branding.

Icon style:

- Use simple, readable emoji/icons where current Tap Maker UI benefits from them.
- Keep icons consistent by category:
  - Business: house, wrench, cash, power.
  - Street: chat, food, people, hand.
  - Team: crosshair, shield, headset, trophy.
  - Gray: mask, warning, black-market tag.

Page hierarchy rules:

- Every main page should have one primary action or one primary decision.
- Secondary systems should be reachable but visually quieter than today's main goal.
- Ads, freebies, market pulls, rankings, achievements, and collection tabs must not compete with survival/team/story actions.
- Red dots should mean urgency, not "anything new."
- If a screen needs more than one scroll length on a normal phone, it should be split, folded, or summarized.

Mobile constraints:

- Design for portrait first.
- Keep primary buttons at thumb-friendly height.
- Avoid more than 5 visible action buttons in the main management action area.
- Important choice text should fit in two lines where possible.
- Consequence hints should be short and consistent: "Immediate" result first, "Risk" second.
- Popups should never chain more than two layers deep.

### Title / Opening Screen

Purpose:

- Sell the premise immediately.
- Show exile and opportunity, not just "tycoon."

Recommended layout:

- Full-screen background: African street/cafe exterior at dusk.
- Main title: "非洲网吧大亨".
- Subtitle: "背井离乡，开一间破网吧，养出一支三角洲战队".
- Primary button: "开始这一搏".
- Secondary button: "继续经营".

Tone:

- Warm but pressured.
- The player should feel "I have no way back" more than "I am already a boss."

### Comic / Story Intro Screen

Purpose:

- Deliver the China failure -> Africa arrival -> broken cafe setup.

Layout:

- Vertical comic panel stack.
- Bottom dialogue/choice panel.
- Choices should express personality, not optimal math.

Example choices:

- "我已经没退路了"
- "就赌这一次"
- "先活下来再说"

UI notes:

- Keep text blocks short.
- Do not mix too many fonts.
- Let panels breathe; this is emotional onboarding.

### Main Management Screen

Purpose:

- Let the player know what matters today.

Top area:

- Day and time/week.
- Cash.
- AP.
- Power/equipment warning.

Hero area:

- Cafe image changes by state: empty, busy, blackout, match day.
- One-line street atmosphere.

Main goal card:

- Always visible.
- Shows one priority:
  - "周末比赛还剩 2 天：训练 Kofi 或修设备"
  - "Victor 正在打价格战：守住老顾客"
  - "Musa 明天来收租：准备 $300"

Action area:

- 3-5 visible actions only.
- Group by:
  - 经营
  - 街区
  - 战队
  - 风险机会

Avoid:

- Showing every system equally.
- Making ads brighter than main actions.
- Excess red dots.

### Daily Action Popup

Purpose:

- Present a meaningful choice quickly.

Layout:

- Title
- Situation text
- 2-3 choices
- Each choice shows visible cost/benefit.
- Consequence hint if long-term risk exists.

Example:

- "买黑市显卡"
- Visible: "-$200, 训练效率+15%"
- Hint: "来源不明，之后可能被查"

### Street Event Screen

Purpose:

- Make local stories feel human.

Layout:

- NPC portrait/avatar or street scene.
- Short dialogue.
- 2-3 choices.
- Result text after selection.

Tone:

- Natural, specific, local.
- Avoid generic "NPC needs help" wording.

UI behavior:

- Important NPC events can have warmer framing.
- Random street events should be compact and fast.

### NPC Relationship / Street Notebook

Purpose:

- Help players remember people and consequences.

Layout:

- NPC list with relationship status.
- Each NPC card:
  - Name
  - Role on street
  - Current attitude
  - Last important event
  - Next vague hook

Example:

- Mama B
- "烤鸡摊老板 / 街区情报中心"
- "信任你"
- "你帮她渡过了进货危机"
- "她说周末比赛日要给队员准备吃的"

### Team Screen

Purpose:

- Make Dragon Force feel like people, not cards.

Layout:

- Team overview: next match, team morale, fatigue.
- Member cards:
  - Name
  - Role
  - Technical rating
  - Mood/fatigue
  - Life pressure tag
  - Current personal hook

Example:

- Kofi
- Entry / high reaction / unstable under pressure
- "家里希望他去修车铺打工"

Primary actions:

- Train
- Talk
- Rest
- Review tactics
- Resolve personal issue

### Training Screen

Purpose:

- Show tradeoffs, not grind.

Layout:

- Choose training type:
  - Aim
  - Reaction
  - Teamwork
  - Review
  - Street scrim
- Show gains and pressure.

Example:

- "高强度枪法训练"
- "+枪法, +疲劳, Kofi 压力上升"

If minigames are used:

- Keep them short.
- Tie them to training flavor.
- Never make them mandatory for all progress.

### Match Preparation Screen

Purpose:

- Create anticipation before weekly matches.

Layout:

- Opponent profile
- Map/tactical notes
- Team readiness
- Street support
- Risk warnings

Choices:

- Lineup
- Tactical style
- Pre-match speech or prep

Tactical styles:

- Aggressive entry
- Stable economy
- Protect carry
- Info control
- Surprise strategy

### Match Moment Screen

Purpose:

- Let the player feel like a coach.

Layout:

- Round state summary.
- One tense situation.
- 2-3 choices.
- Show immediate round result and emotional consequence.

Example:

- "Kofi 被连续针对，他想继续硬冲。"
- Choices:
  - "相信他继续突破"
  - "让 Grace 接管指挥"
  - "叫暂停，稳住心态"

### End of Day Screen

Purpose:

- Close the day with consequence and hook.

Layout:

- Revenue and costs.
- One story consequence.
- One team consequence.
- One tomorrow hook.

Avoid:

- Overloading with every system result.
- Showing too many popups after end day.

### Weekly Node Screen

Purpose:

- Make each week memorable.

Layout:

- Full-screen chapter card.
- Short summary of what changed.
- Major choice/result.
- Next week's pressure.

Visual:

- More cinematic than daily events.
- Use wide cafe/street/team art where available.

### Map / City Expansion Screen

Purpose:

- Show long-term dream: from one broken cafe to a network across Africa.

Layout:

- Africa map with city nodes.
- Current city pulsing.
- Conquered cities lit.
- Locked cities with requirement.
- Each city has one story hook, not only income multiplier.

Important:

- This should feel like "the dream becoming real," not a spreadsheet.

### Market / Gray Opportunity Screen

Purpose:

- Separate normal second-hand market from risky gray choices.

Layout:

- Normal market: useful, colorful, street-life feeling.
- Gray market: darker framing, clear warning, stronger short-term reward.

Rules:

- Gray choices must show visible risk hints.
- Do not hide that consequences may come later.

### Ending Screen

Purpose:

- Reflect who the player became.

Layout:

- Ending title.
- Cafe/team/street final image.
- Three-part summary:
  - What happened to the cafe.
  - What happened to Dragon Force.
  - What the street says about you.
- Key NPC epilogues.
- Final Victor comparison where relevant.

Example:

- "街区之光"
- "你没有建成最赚钱的网吧，但当 Dragon Force 出征时，整条街都来送行。"

## 11. Technical Design for Tap Maker / UrhoX

The implementation should stay data-driven and light.

Recommended modules:

1. DayWeekRhythm
   - Day AP
   - Weekly nodes
   - Chapter advancement

2. StreetEvent
   - Event pools
   - Conditions
   - Choices
   - Immediate rewards
   - Hidden ledger impacts
   - Follow-up flags

3. NPCArc
   - Core NPC stage tracking
   - Relationship state
   - Stage unlock conditions
   - Gameplay benefits/penalties

4. TeamMatch
   - Player attributes
   - Training
   - Fatigue/pressure
   - Match preparation
   - Match moment choices
   - Result calculation

5. EndingLedger
   - Hidden axes
   - Key decisions
   - NPC fates
   - Team record
   - Ending selection

Implementation principles:

- Use Lua tables for content.
- Keep event structures consistent.
- Reuse current UI panels.
- Do not implement complex real-time combat.
- Let AI help expand text/content, not decide core rules.
- Keep save migration explicit for all new fields.

## 12. Refactor Priority

### P0: First 30 Days Backbone

- Rewrite opening premise.
- Establish day/week rhythm.
- Ensure day 1-14 have mainline hooks.
- Add main goal card.
- Bind Kofi discovery to team unlock.
- Reframe Victor as pressure/mirror.

### P1: Street and Team Binding

- Reclassify events into six pools.
- Add NPC arc stages for first seven core NPCs.
- Make street relationships affect team/training/matches.
- Add match moment events.

### P2: Consequence and Ending Ledger

- Add hidden axes.
- Add gray choices with delayed consequences.
- Add route-specific weekly feedback.
- Add six ending families.

### P3: UI Polish and Content Scale

- Improve page hierarchy.
- Reduce popup noise.
- Add city map dream layer.
- Add more events for days 15-30.
- Add ending variants.

## 13. Success Criteria

The v2.0 design succeeds if:

- A new player understands within 30 minutes:
  - Why the protagonist came to Africa.
  - Why the cafe matters.
  - Why Kofi matters.
  - Why Dragon Force exists.
- The player faces meaningful daily tradeoffs.
- The first 14 days have no dead zone.
- Local stories affect team growth and match outcomes.
- Gray choices feel tempting but dangerous.
- Endings reflect the kind of boss the player became.

## 14. Open Implementation Notes

- Existing systems should be audited before editing to map which files own current day rhythm, events, NPC progression, match flow, and ending logic.
- Existing event content can be reused, but should be tagged by pool and role.
- Existing UI should be simplified before adding more screens.
- Existing ad placements should be visually secondary to main actions.
- Save compatibility is mandatory because the game is already live.
