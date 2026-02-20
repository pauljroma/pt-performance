# Quick reference for test persona login

All 10 test patient personas and the demo therapist. UUID prefix: `aaaaaaaa-bbbb-cccc-dddd-`

## Therapist
**Sarah Thompson** -- `00000000-0000-0000-0000-000000000100` (demo-pt@ptperformance.app)

## Patients

| # | Name | UUID suffix | Sport | Mode |
|---|------|-------------|-------|------|
| 1 | Marcus Rivera | `000000000001` | Baseball | rehab |
| 2 | Alyssa Chen | `000000000002` | Basketball | rehab |
| 3 | Tyler Brooks | `000000000003` | Football | performance |
| 4 | Emma Fitzgerald | `000000000004` | Soccer | rehab |
| 5 | Jordan Williams | `000000000005` | CrossFit | strength |
| 6 | Sophia Nakamura | `000000000006` | Swimming | rehab |
| 7 | Deshawn Patterson | `000000000007` | Track & Field | performance |
| 8 | Olivia Martinez | `000000000008` | Volleyball | strength |
| 9 | Liam O'Connor | `000000000009` | Hockey | rehab |
| 10 | Isabella Rossi | `00000000000a` | Tennis | strength |

## Auto-Login (Xcode scheme or XCUITest)

```
--uitesting --auto-login-user-id aaaaaaaa-bbbb-cccc-dddd-000000000001
```
For therapist, add: `--auto-login-role therapist`
Environment: `IS_RUNNING_UITEST = 1`

## In-App Debug Picker
`Views/Auth/TestUserPickerView.swift` -- DEBUG-only visual picker on the auth screen.

## By Mode
- **Rehab (5):** #1 Marcus, #2 Alyssa, #4 Emma, #6 Sophia, #9 Liam
- **Strength (3):** #5 Jordan, #8 Olivia, #10 Isabella
- **Performance (2):** #3 Tyler, #7 Deshawn
