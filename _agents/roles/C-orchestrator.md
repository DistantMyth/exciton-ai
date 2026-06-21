# YOUR ROLE: Orchestrator & Models Engineer (Role C) — @rohan

Read `_agents/masterplan.md` first. This overlay defines your ownership.

## You own (in `orchestrator/`, Python)
1. `delegate_task(goal, success_criteria, tools[], model_hint, max_turns)` — spawns a fresh
   isolated context with a SCOPED tool whitelist (least privilege), capped turns/tokens.
2. Subagent lifecycle + context isolation. On completion: DROP the context, inject ONLY the
   schema-validated summary into the main context.
3. The result envelope: `{status, summary, changes:[{element_id,before,after}], evidence,
   tokens_used}`.
4. `assert_state` consumption (the tool lives on B's MCP server; you call it in the verify
   gate). `success_criteria` MUST be DE-observable, never subjective.
5. Hybrid routing: always-on `qwen2.5:3b` handles list/count/route; multi-step reasoning
   escalates to the 8B (Ollama load/unload on demand).
6. Main-agent + subagent prompt templates (the discipline layer): main learns when to
   delegate; subagent learns finish → verify → clean summary. Subagents get a SLICED doc
   (only their tools).
7. Ollama setup + a 3-task benchmark to pick the 8B (`qwen2.5:7b` / `llama3.1:8b` /
   `qwen3:8b`) on tool-call accuracy, not vibes. Document the pick in an ADR.

## Your interfaces (the seams)
- You are an MCP CLIENT to Role B. Consume `docs/contracts/mcp-tools.json`.
- Emit task traces Role D's harness can parse (coordinate the format in `docs/contracts/`).
- Benchmark + routing config are yours; share results in `_agents/decisions/`.

## How you work & test
- Drive the orchestrator against Srujan's MCP server pointed at the `plasma-ai` nested session.
- Use Tarun's task harness to measure tokens + pass/fail; that's your quality signal.
- Claim tasks under `feat/C-*`.

## Your v0.1 focus (the order matters)
1. **Author the contract you own:** `delegate-task.schema.json` (the result envelope Srujan
   + Tarun consume). Sign-off is the gate.
2. Ollama setup on the 6 GB VRAM box: `OLLAMA_FLASH_ATTENTION=1`, `num_ctx 8192`. Preload
   `qwen2.5:3b` (triage) + the 3 8B candidates.
3. **3-task benchmark** to pick the 8B (`qwen2.5:7b` / `llama3.1:8b` / `qwen3:8b`) on
   tool-call accuracy. Document the pick in an ADR.
4. Orchestrator skeleton: MCP client to Srujan's server + main-agent loop (no subagents yet).
5. Main-agent prompt template (the discipline layer).
Layer 3 (`delegate_task` + `assert_state` + summary handback + hybrid routing) is **v0.3**.

## Out of scope
DE source (A), MCP server internals (B), test-session/CI plumbing (D).
