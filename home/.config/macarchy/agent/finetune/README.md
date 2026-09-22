# Fine-tuning the workspace agent

The runner uses Cactus Needle 3, a 14 MB on-device tool-calling model, fine-tuned
on synthetic examples of these tools. Nothing here touches the network except
`pip` and the one-time base-weight download from Hugging Face.

    python3 -m venv .venv && . .venv/bin/activate
    pip install "cactus-needle[train]"            # CPU JAX; add jax-rocm7-plugin on an AMD Linux box
    python finetune/gen_data.py --n 2000          # -> finetune/data.jsonl (templated, deterministic)
    NEEDLE_TELEMETRY=0 needle finetune finetune/data.jsonl --epochs 3 --lr 2e-4 --max-len 900 \
        --batch-size 16 --val-split 0.1 --seed 42 --out finetune/adapter.safetensors
    needle build --lora finetune/adapter.safetensors --out workspace-agent.cact
    python finetune/eval.py --weights workspace-agent.cact --include-suppressed

Install the result: copy `workspace-agent.cact` to
`~/.local/share/macarchy/models/workspace-agent.cact` (or set `MACARCHY_AGENT_MODEL`).

Numbers from 2026-09-21 (exact match on 150 template rows + 14 hand-written):
base 35%, round 3 67%; single-action sentences 80%. The runner splits compound
sentences into clauses, so real use lands above the eval number.

Adding a tool: add a `@needle.tool` function in `../tools.py`, a generator in
`gen_data.py`, an executor branch in `../ws.py`, regenerate, retrain.
Renaming or re-describing a tool changes the schema and needs a retrain.
