# Reuse Before Build

Before writing any new UI element, helper, hook, or validation, search first. The principle is stack-agnostic; the directory names below are React/Next.js examples — translate to the project's layout (`app/components/`, `app/helpers/`, `lib/`, `src/components/`, etc.).

## UI primitives (HIGHEST PRIORITY)

Grep the project's shared UI directory for the concept first. Common primitives:

- Buttons / inputs: `button`, `input`, `select`, `checkbox`, `radio`, `switch`, `slider`, `textarea`
- Tags / labels: `pill`, `badge`, `chip`, `tag`, `label`
- Containers: `card`, `panel`, `section`, `accordion`, `tabs`
- Overlays: `modal`, `dialog`, `tooltip`, `popover`, `dropdown`, `menu`, `toast`, `alert`
- Misc: `avatar`, `skeleton`, `spinner`, `breadcrumb`, `divider`

If found: compose with it. Pass props/variants instead of restyling.
If not found: confirm with the user before creating a new primitive.

## Helpers, hooks, validations

- Hooks (React): grep `hooks/**` for `use-{concept}` before creating one.
- Utilities: grep `lib/`, `utils/`, `app/helpers/`, or the project's equivalent before creating a new helper.
- Validations / schemas: grep the project's schema/validation home (e.g. `lib/validations.ts`, `app/schemas/`) before adding a new one.

## Never modify shared without an explicit ask

Files in the shared UI directory (`components/ui/`, `app/components/shared/`, etc.) are consumed by many places. Don't change their behavior or API without the user explicitly requesting it.
