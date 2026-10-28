# AI feature — local rule-based target suggestion

**Method:** `recommendTarget` in `lib/smart_helper.dart` uses up to three most recent saved progress values. If their mean is at least 80%, suggest +5 points; if below 40%, suggest -5 points; otherwise keep the existing target. Clamp 1–100. This is **not trained ML**.

**Baseline:** `baselineTarget` retains the existing target. The app shows the suggestion and reason. **Apply** fills the progress slider, and **Not now** dismisses it; the user must explicitly save.

**No-data:** returns existing target with explanation. **Invalid:** throws an argument error. **Boundary:** clamped to 1–100. **Counterexample:** a single atypical day can mislead a 3-day mean. **Limitations:** no causal inference or general accuracy claim.

## Graduate held-out evaluation — must be executed and completed by the team

Use at least five genuinely held-out valid cases not used to tune the rules. Record real progress outcome, suggested target, baseline target, absolute errors for each, MAE for each method, and a reasoned error analysis. Do not enter invented measurements. The source tests demonstrate deterministic behavior but **are not held-out evaluation evidence**.

| Case | History | Current target | Actual next progress | Helper | Baseline | Helper error | Baseline error |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |
| 2 | | | | | | | |
| 3 | | | | | | | |
| 4 | | | | | | | |
| 5 | | | | | | | |

**Evaluation note:** current target and progress are different constructs; explain the limits of using next progress as a proxy for an appropriate target.
