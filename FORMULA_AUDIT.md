# DrillCalc Formula Audit & Corrections

Audit of the app's calculators against the source workbook
(`ALL IN 1 KILL SHEET- CLAUDE CORRECTED AS PER ORG.xlsx`) and standard
drilling-engineering references. Every numeric change below was verified
independently by hand calculation.

## Errors found in the WORKBOOK itself (fixed in the app)

| Location | Problem | Correction |
| --- | --- | --- |
| `Bits & LCM` B7 | Nozzle pressure drop computed as `MW*Q^2/(10858*TFA)` — missing the square on TFA. The workbook's own `Bingham` sheet (G5) uses the correct `TFA^2`. Sample case: workbook said 278 psi, correct value is 186 psi. | App now uses `MW*Q^2/(10858*TFA^2)`. |
| `Bits & LCM` B28/B29 (optimum hydraulics) | `2/(m+2)*Pmax` and `1/(m+1)*Pmax` are the optimum **parasitic** losses, but were labeled as optimum **bit** pressure drops. The associated "optimum flow rate" cells were dimensionally wrong (returned ~3 gpm). | App reports the true optimum bit drops: impact force `m/(m+2)*Pmax`, bit HHP `m/(m+1)*Pmax`. |
| `KILL SHEET` G59/G61/K61 | KRP cell points at `'INPUT DATA'!#REF!`, so ICP, FCP, total pressure drop, and the whole step-down schedule show `#REF!`. | App takes slow circulating pressure as an input and computes ICP/FCP/schedule correctly. |
| `Influx Analysis` H19 | With pit gain = 0 the gradient defaults to 0 and the sheet declares "GAS KICK" even when there is no influx at all. | App now reports "NO INFLUX (pit gain = 0)" and flags physically impossible gradients (outside 0 to mud gradient) as unreliable instead of classifying them. |
| `Influx Analysis` H19 vs reference table | Classification formula used 0.45 psi/ft as the saltwater/brine boundary while the sheet's own reference table says 0.40-0.47 saltwater, >0.47 heavy brine. | App uses 0.47. |
| `FIT CALC` D6 | Hole volume hard-codes `12.375^2` regardless of the entered hole size. | App uses the hole-diameter input. |

## Errors found in the previous APP version (fixed)

| Calculator | Problem | Correction |
| --- | --- | --- |
| Bits & LCM | Copied the workbook's missing `TFA^2` (nozzle dP ~49% too high for the sample). | Corrected formula; HHP/HSI now follow. |
| FASDRILL | Copied the workbook's mislabeled optimums (would push TFA selection the wrong way). | Optimum bit drops `m/(m+2)`, `m/(m+1)` of Pmax. |
| Liner Cementation | Overlap annulus used hole x liner OD; the overlap is liner inside the **previous casing**. Displacement used liner capacity over the full length, ignoring the drill pipe above the liner top and the shoe track. | Added previous casing ID, liner top, shoe track and DP capacity inputs; displacement = DP cap x liner top + liner cap x (liner length - shoe track), matching workbook `Liner cementation` C29. |
| Casing Hydraulic Force | Reported only `P x ID-area` with no weight balance, so it couldn't answer the question the workbook answers (will pressure lift the casing?). | Full force balance per the workbook: OD piston area, air/buoyed weight (BF = 1-(MW/8.33)/7.85), upward force, net force, and pressure-to-lift = buoyed weight / piston area. |
| FIT Calc | `4 x MW` was labeled "Approx PV/FV" in cP — it is the funnel-viscosity rule of thumb in seconds. | Relabeled with correct unit; added psi/bbl response. |
| Hole Cleaning | Max safe ROP could go negative; cuttings-concentration check from the sheet was missing. | Clamped at 0; added cuttings concentration (<5% ideal). |
| Well Control schedule | Step-down table could end above FCP and step count was unbounded. | Schedule now closes exactly at FCP at surface-to-bit strokes; capped at 400 rows. |
| API 13D | Annular pressure-loss could divide by zero (NaN) for degenerate geometry. | Guarded. |
| All calculators | A regression test now feeds all-zero inputs to every calculator and asserts no NaN/Infinity output. | — |

## Verified as correct (unchanged)

Kill mud weight `MW + SIDPP/(0.052 x TVD)`, ICP/FCP, MAASP, kick tolerance
(max influx height, DP/DC volumes, max kill MW `LOT x shoeTVD/TD-TVD`),
volumetric method (hydrostatic per bbl, bleed volumes, margins), mud mixing
(barite weight-up `V*(1470-42W1)/(1470-42W2)` and dilution), pipe stretch /
free point (E = 30e6 psi), buoyancy `(65.5-MW)/65.5`, balanced plug (incl.
the 3 bbl under-displacement from the sheet), wiper plug, cementing
calculator, minimum-curvature directional math, Bingham PV/YP, hydraulics
ECD/lag time, thickening time (matches SPE-188119-MS-based sheet), stuck
pipe scoring, whipstock geometry, squeeze calculators, cutting skips.

## Notes

- The thickening-time PV/YP quick check intentionally follows the sheet's
  300/200-rpm convention (`PV = 300-200`, `YP = 200-PV`) from its SPE source.
- Workbook tabs that are data tables or rig-specific trackers (STRING DATA,
  Loss monitoring tracker grid, FASDRILL squeeze tracker, etc.) are
  represented by simplified calculators, same as before.
