---
name: scaffold-category-stack
description: Create a new category stack (aggregator + service includes)
trigger: /scaffold-stack
---

## Usage

```
/scaffold-stack <category-name>
```

## Rules

- Append a blank new aggregator at `templates/<category> /docker-compose.<category>.yml`
- Always include `templates/_shared/networks.yml`
- Register in `templates/templates.json` as a `type: 3` entry
- Do NOT modify existing stacks

## Steps

1. Confirm the category directory does not yet exist (abort if it does).
2. Create `templates/<category>/docker-compose.<category>.yml` with:
   ```yaml
   include:
     - ../_shared/networks.yml
   ```
3. Add a `type: 3` entry to `templates/templates.json` with a unique `name` and appropriate `categories`.
4. Run `npx prettier --write "templates/**/*.yml" "templates/**/*.yaml" "*.json" "*.md"`.
