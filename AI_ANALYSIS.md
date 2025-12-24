# Cribbage AI Competitiveness Analysis

## Current Performance
- **Player Win Rate:** 55.8% (5,575/10,000 games)
- **Computer Win Rate:** 44.2% (4,425/10,000 games)
- **Average Player Score:** 9.1
- **Average Computer Score:** 8.0

## Current AI Strategy

### Discard Strategy
**Strengths:**
- Evaluates all 15 possible 2-card discard combinations
- Considers hand value (fifteens within remaining 4 cards)
- Weighs crib ownership (1.5x weight for computer's crib, -1.5x for opponent's)

**Limitations:**
- Only evaluates fifteens and pairs in discards
- Doesn't consider flush potential (4-card flushes worth 4-5 points)
- Doesn't count runs (3+ card sequences worth 3+ points)
- Doesn't evaluate "nobs" (Jack matching cut card suit)
- Incomplete hand scoring (only looks at 2-card fifteens, not counting all patterns)

### Play Strategy
**Strengths:**
- Prioritizes immediate scoring (31 = 2 points, 15 = 2 points)
- Avoids setting up opponent for 31
- Plays safer lower cards when needed

**Limitations:**
- No lookahead/simulation of opponent's response
- Doesn't track which cards opponent likely has remaining
- Doesn't consider building runs or pairs for future points
- Binary danger detection (31 only) - doesn't account for other patterns
- Doesn't consider defensive strategy (e.g., breaking up opponent's potential runs)

## Recommended Improvements (Priority Order)

### Priority 1: Better Discard Evaluation (HIGH IMPACT)
The discard phase is crucial since it happens 10 times per game. Incomplete evaluation leaves significant points on the table.

**Improvements:**
1. **Full hand scoring simulation** - Evaluate actual cribbage scoring for remaining 4 cards
   - Count all fifteens (not just pairs)
   - Count pairs
   - Count runs
   - Consider flush potential
   - Estimate nobs probability

2. **Better crib estimation** - Instead of just 15s and pairs:
   - Simulate crib scoring with all possible cut cards
   - Weight by cut card probability
   - Consider flush potential in crib

**Expected Impact:** +2-3% win rate (100-300 games)

### Priority 2: Improved Play Strategy (MEDIUM IMPACT)
Play phase happens 6-8 times per round, with 4-8 cards played per phase.

**Improvements:**
1. **Pair/Run awareness** - Track cards already played
   - Avoid playing cards that let opponent make pairs/runs
   - Build potential runs/pairs for yourself
   
2. **Better danger detection**
   - Check for 15 patterns (not just 31)
   - Consider opponent's remaining cards
   - Weight danger by likelihood of opponent having specific cards

3. **Defensive play**
   - If opponent has shown interest in certain ranks (e.g., played pairs), avoid playing complements
   - Play cards strategically to minimize opponent's scoring opportunities

**Expected Impact:** +1-2% win rate (100-200 games)

### Priority 3: Advanced Lookahead (LOWER IMPACT)
Simulating opponent response could improve play decisions but is computationally expensive.

**Improvements:**
1. **One-move lookahead** - For critical decisions:
   - Simulate 2-3 best opponent responses
   - Evaluate outcome of each
   - Choose play that minimizes opponent advantage

2. **Card tracking** - Maintain probability distribution of opponent's remaining cards
   - Update based on plays made
   - Use to estimate danger/opportunity

**Expected Impact:** +0.5-1% win rate (50-100 games)

## Implementation Recommendation

Focus on **Priority 1** (better discard evaluation) first since:
- Discard happens early and affects entire round
- Reuses existing scoring functions
- Relatively easy to implement
- Highest expected ROI

Then implement **Priority 2** improvements to play strategy incrementally.

## Code Changes Needed

### For Better Discard Evaluation:
```javascript
selectComputerDiscard() {
    // Instead of simple 15 check:
    // 1. For each discard pair, evaluate remaining 4-card hand fully
    // 2. Score against multiple possible cut cards (weighted by probability)
    // 3. Also evaluate crib potential using full scoring
    // 4. Compare total expected value of each discard option
}
```

### For Better Play Strategy:
```javascript
selectBestPlayCard(playableCards) {
    // Add detection for:
    // 1. Cards that form pairs/runs with already-played cards
    // 2. Cards that prevent opponent from forming pairs/runs
    // 3. Better "dangerous" detection beyond just 31
    // 4. Tactical card preservation (save cards for better future plays)
}
```

## Competitive Potential

With these improvements, the computer could potentially achieve:
- **Best case:** 50%+ win rate (truly competitive)
- **Realistic case:** 48-50% win rate with full optimization
- **Current ceiling:** ~45-47% without major architectural changes

The 55.8% player advantage is likely due to:
- Basic player strategy in simulation still winning some games
- Inherent luck in card deals
- Crib advantage (worth 5-10 points/game on average)
