# Agent instructions (sisrv-platform)

## Git identity

- Author and committer must be:
  - **Name:** Kiran Tathekalva
  - **Email:** kiranreddi.t@gmail.com
- Never use Synaptics (or any employer) names or email addresses in commits, tags, docs, or metadata.

## No co-authored trailers

- **Never** add `Co-authored-by:` (or similar) trailers to commit messages.
- This includes Cursor, Copilot, Claude, or any other agent/bot.
- Commit messages should contain only the subject/body that describes the change.

## Commits

- Use clear, descriptive commit messages without trailers that attribute authorship to tools.
- Prefer `git commit` with the identity above; do not rewrite author to a bot account.
