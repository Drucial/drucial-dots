---
alwaysApply: true
---

# Reuse Before Build

Before writing any new UI element, hook, util, or validation:

## UI primitives (HIGHEST PRIORITY)

Grep `components/ui/` for the concept first. Common primitives include:

- Buttons / inputs: `button`, `input`, `select`, `checkbox`, `radio`, `switch`, `slider`, `textarea`
- Tags / labels: `pill`, `badge`, `chip`, `tag`, `label`
- Containers: `card`, `panel`, `section`, `accordion`, `tabs`
- Overlays: `modal`, `dialog`, `tooltip`, `popover`, `dropdown`, `menu`, `toast`, `alert`
- Misc: `avatar`, `skeleton`, `spinner`, `breadcrumb`, `divider`

If found: compose with it. Pass props/variants instead of restyling.
If not found: confirm with the user before creating a new primitive.

## Hooks, utils, validations

- Hooks: grep `hooks/**` for `use-{concept}` before creating one.
- Utils: grep `lib/`, `utils/` for the function before creating one.
- Validations: grep `lib/validations.ts` (or equivalent) before adding a new Zod schema.

## Never modify shared without an explicit ask

Files in `components/ui/` are shared. Don't change their behavior or API without the user explicitly requesting it.
