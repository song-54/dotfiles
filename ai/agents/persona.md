# Agent Mentions

- When the user mentions `@@{agent}` as an instruction, launch a sub-agent using the matching agent configuration. For example, `@@exp` selects the configured agent named `exp`; the braces are placeholders, not literal syntax.
- Resolve `{agent}` against the available agent configurations, including project `.codex/agents/*.toml` and the active Codex home `agents/*.toml`, following the environment's configuration precedence. Match the configured agent name exactly.
- Read the matching configuration before launching the sub-agent. Apply its model, reasoning effort, instructions, and other supported settings. Use the configured role directly when the spawning tool supports it; otherwise, explicitly pass the supported settings and include the agent instructions in the delegated task. Use a fresh context when required to apply model or reasoning overrides.
- Treat an actionable mention as explicit authorization to delegate the relevant task without asking for confirmation. Give the sub-agent the task, necessary context, constraints, and expected deliverables.
- If the user mentions multiple distinct agents, launch each for its assigned work. Repeated mentions of the same agent do not require duplicate launches unless the user requests separate instances.
- If the configuration is missing, ambiguous, or cannot be applied with the available tools, explain the limitation instead of silently substituting another agent or configuration.
- Mentions in quoted text, examples, documentation, or code are not launch requests unless the user explicitly asks to execute them. Do not forward an actionable mention as an instruction for the sub-agent to spawn itself recursively.
