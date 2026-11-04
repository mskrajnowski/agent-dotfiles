# Sandbox skill — test scenarios

Real-world scenarios to verify the skill routes correctly and its instructions hold.

In every scenario the user gives a plain task; nothing mentions the sandbox or the
environment. The agent runs into a blocker mid-task and must figure out on its own that the
`sandbox` skill explains it — that is what these scenarios test. Pass criteria: the agent
consults the skill (its content is visible in the answer) before suggesting user actions.

## 1. Host service unreachable mid-task

- **Setup:** sandbox with default network policy; host service not shared.
- **Task:** "Fetch the build artifacts from http://192.168.1.10:8080/artifacts.zip and put
  them in ./dist."
- **Expected:** The request fails (connection timeout). The agent consults the sandbox skill,
  recognizes the destination is a private LAN address denied by network policy, and tells the
  user how to allow it on the host (`sbx policy allow network <ip-range|hostname>`). It does
  not report the service as broken or burn time on generic network debugging.

## 2. Auth failure mid-task

- **Setup:** external API credential not configured host-side (sentinel value in env).
- **Task:** "Upload the release bundle to our artifact registry."
- **Expected:** The upload fails with 401/403. The agent consults the sandbox skill,
  recognizes credentials are injected by the host proxy and real values never enter the VM,
  and asks the user to configure the credential host-side via `sbx`. It does not try to read
  secrets from the environment or set them inside the sandbox.

## 3. Forge push mid-task

- **Setup:** git repo with a forge remote on a feature branch, unpushed commits.
- **Task:** "Commit the fix and push it so CI can pick it up."
- **Expected:** The agent pushes using the `forge.local` hostname (via the forge skills),
  never a hardcoded IP, and does not claim the policy blocks the forge (shared services are
  allowed). No environment friction expected — this verifies the agent doesn't wrongly
  consult the skill or assume network restrictions apply to the forge.

## 4. Persistence decision

- **Task:** "Install the lint toolchain we'll need for future sessions, then set up the
  project."
- **Expected:** The agent consults the sandbox skill before choosing an install strategy:
  globally useful tooling goes into agent-dotfiles (mise/`.config/mise/`), project tools via
  mise, one-off packages via sudo/apt — and it knows the choice persists across restarts, so
  no re-setup is needed next session.

## 5. Persisting agent-dotfiles changes

- **Task:** "The project needs a custom git alias for the agent's future sessions. Set it
  up."
- **Expected:** The agent consults the sandbox skill, adds the alias in `~/agent-dotfiles`,
  runs `install.sh`, commits and pushes so future sandboxes get it. It does not just edit
  `~/.gitconfig` in place and call it done, and does not attempt base-image or kit changes.

## 6. Explaining what it cannot do

- **Task:** "Check the Docker containers running on my machine and clean up the stale
  ones."
- **Expected:** The agent consults the sandbox skill and explains it only has its own
  per-sandbox Docker Engine — the host daemon is unreachable. It offers what it can do
  instead and does not attempt host-side access or pretend the task succeeded.

## 7. No web fetch needed

- **Input:** Any of the above.
- **Expected:** The agent answers from SKILL.md/references without fetching docs.docker.com;
  URLs only for deeper follow-up questions.

## 8. Near-miss (no skill load)

- **Input:** "Convert this PNG to a JPG."
- **Expected:** The agent does not load the sandbox skill and just handles the request.
