#!/bin/bash
# Task management for self-organizing agent teams
# Source after config.sh: source "$TORC_BIN/../lib/tasks.sh"
#
# File layout:
#   ~/.tmux-orchestrator/tasks/<team>.json   task list
#   ~/.tmux-orchestrator/tasks/<team>.lock   flock lock file

# ── Path helpers ──────────────────────────────────────────────────────────────

tasks_dir() {
    echo "$TORC_STATE_DIR/tasks"
}

tasks_file() {
    echo "$(tasks_dir)/${1}.json"
}

tasks_lock_file() {
    echo "$(tasks_dir)/${1}.lock"
}

ensure_tasks_dir() {
    mkdir -p "$(tasks_dir)"
}

# ── Read-only helpers (no lock needed) ────────────────────────────────────────

# tasks_list <team>
# Print a human-readable task table.
tasks_list() {
    local file
    file="$(tasks_file "$1")"
    [ ! -f "$file" ] && { echo "No task list for team '$1'"; return 1; }

    python3 - "$file" <<'EOF'
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

done_ids = {t['id'] for t in data['tasks'] if t['status'] == 'done'}

STATUS = {'pending': '○', 'in_progress': '◑', 'done': '●'}
PLAN   = {'submitted': ' [PLAN↑]', 'approved': ' [PLAN✓]', 'rejected': ' [PLAN✗]'}

for t in data['tasks']:
    blocked_by = t.get('blocked_by', [])
    is_blocked = t['status'] == 'pending' and not all(d in done_ids for d in blocked_by)
    icon       = '⊘' if is_blocked else STATUS.get(t['status'], '?')
    plan_note  = PLAN.get(t.get('plan_status'), '')
    owner_note = f" [{t['owner']}]" if t.get('owner') else ''
    dep_note   = f" (needs: {', '.join(blocked_by)})" if is_blocked else ''
    print(f"  {icon} {t['id']}  {t['title']}{owner_note}{plan_note}{dep_note}")
EOF
}

# tasks_get <team> <task-id>
# Print JSON of a single task; exits 1 if not found.
tasks_get() {
    local file
    file="$(tasks_file "$1")"
    python3 -c "
import json, sys
with open('$file') as f:
    data = json.load(f)
for t in data['tasks']:
    if t['id'] == '$2':
        print(json.dumps(t, indent=2))
        sys.exit(0)
sys.exit(1)
"
}

# tasks_pending_count <team>
tasks_pending_count() {
    local file
    file="$(tasks_file "$1")"
    python3 -c "
import json
with open('$file') as f:
    d = json.load(f)
print(sum(1 for t in d['tasks'] if t['status'] == 'pending'))
"
}

# tasks_all_done <team>
# Exits 0 if every task is done, 1 otherwise.
tasks_all_done() {
    local file
    file="$(tasks_file "$1")"
    python3 -c "
import json, sys
with open('$file') as f:
    d = json.load(f)
sys.exit(0 if all(t['status'] == 'done' for t in d['tasks']) else 1)
"
}

# ── Write operations (exclusive lock via Python fcntl — works on macOS + Linux) ─

# _tasks_py_locked <lock-file> <python-script-args...>
# Internal: run a Python heredoc with an exclusive fcntl lock held.
# Callers embed their logic; the lock file path is always the last argv element
# passed by the wrapper functions below.

# tasks_claim <team> <owner>
# Atomically claim the next available (pending + unblocked) task.
# Prints the claimed task JSON on success; exits 1 if nothing claimable.
tasks_claim() {
    local team="$1" owner="$2"
    local file lock
    file="$(tasks_file "$team")"
    lock="$(tasks_lock_file "$team")"

    python3 - "$file" "$owner" "$lock" <<'EOF'
import json, sys, fcntl, datetime

tasks_file, owner, lock_path = sys.argv[1], sys.argv[2], sys.argv[3]
now = datetime.datetime.utcnow().isoformat() + 'Z'

with open(lock_path, 'w') as lock_f:
    fcntl.flock(lock_f, fcntl.LOCK_EX)
    with open(tasks_file) as f:
        data = json.load(f)
    done = {t['id'] for t in data['tasks'] if t['status'] == 'done'}
    for t in data['tasks']:
        if t['status'] == 'pending' and all(d in done for d in t.get('blocked_by', [])):
            t['status']     = 'in_progress'
            t['owner']      = owner
            t['claimed_at'] = now
            if not t.get('require_plan', False):
                t['started_at'] = now
            with open(tasks_file, 'w') as f:
                json.dump(data, f, indent=2)
            print(json.dumps(t))
            sys.exit(0)
    sys.exit(1)
EOF
}

# tasks_submit_plan <team> <task-id> <plan-text>
# Agent submits a plan; sets plan_status=submitted.
tasks_submit_plan() {
    local team="$1" task_id="$2" plan_text="$3"
    local file lock
    file="$(tasks_file "$team")"
    lock="$(tasks_lock_file "$team")"

    python3 - "$file" "$task_id" "$lock" <<EOF
import json, sys, fcntl, datetime

tasks_file, task_id, lock_path = sys.argv[1], sys.argv[2], sys.argv[3]
plan_text = """$plan_text"""
now = datetime.datetime.utcnow().isoformat() + 'Z'

with open(lock_path, 'w') as lock_f:
    fcntl.flock(lock_f, fcntl.LOCK_EX)
    with open(tasks_file) as f:
        data = json.load(f)
    for t in data['tasks']:
        if t['id'] == task_id:
            t['plan']              = plan_text
            t['plan_status']       = 'submitted'
            t['plan_submitted_at'] = now
            with open(tasks_file, 'w') as f:
                json.dump(data, f, indent=2)
            sys.exit(0)
    print(f"Task {task_id} not found", file=sys.stderr)
    sys.exit(1)
EOF
}

# tasks_approve_plan <team> <task-id>
# Lead approves a plan; sets plan_status=approved, started_at=now.
tasks_approve_plan() {
    local team="$1" task_id="$2"
    local file lock
    file="$(tasks_file "$team")"
    lock="$(tasks_lock_file "$team")"

    python3 - "$file" "$task_id" "$lock" <<'EOF'
import json, sys, fcntl, datetime

tasks_file, task_id, lock_path = sys.argv[1], sys.argv[2], sys.argv[3]
now = datetime.datetime.utcnow().isoformat() + 'Z'

with open(lock_path, 'w') as lock_f:
    fcntl.flock(lock_f, fcntl.LOCK_EX)
    with open(tasks_file) as f:
        data = json.load(f)
    for t in data['tasks']:
        if t['id'] == task_id:
            if t.get('plan_status') != 'submitted':
                print(f"Task {task_id} has no submitted plan (plan_status={t.get('plan_status')})", file=sys.stderr)
                sys.exit(1)
            t['plan_status']     = 'approved'
            t['plan_decided_at'] = now
            t['started_at']      = now
            t['plan_feedback']   = None
            with open(tasks_file, 'w') as f:
                json.dump(data, f, indent=2)
            print(json.dumps(t, indent=2))
            sys.exit(0)
    print(f"Task {task_id} not found", file=sys.stderr)
    sys.exit(1)
EOF
}

# tasks_reject_plan <team> <task-id> <feedback>
# Lead rejects a plan; resets plan_status=null so agent revises.
tasks_reject_plan() {
    local team="$1" task_id="$2" feedback="$3"
    local file lock
    file="$(tasks_file "$team")"
    lock="$(tasks_lock_file "$team")"

    python3 - "$file" "$task_id" "$lock" <<EOF
import json, sys, fcntl, datetime

tasks_file, task_id, lock_path = sys.argv[1], sys.argv[2], sys.argv[3]
feedback = """$feedback"""
now = datetime.datetime.utcnow().isoformat() + 'Z'

with open(lock_path, 'w') as lock_f:
    fcntl.flock(lock_f, fcntl.LOCK_EX)
    with open(tasks_file) as f:
        data = json.load(f)
    for t in data['tasks']:
        if t['id'] == task_id:
            t['plan_status']     = None
            t['plan_feedback']   = feedback
            t['plan_decided_at'] = now
            with open(tasks_file, 'w') as f:
                json.dump(data, f, indent=2)
            sys.exit(0)
    print(f"Task {task_id} not found", file=sys.stderr)
    sys.exit(1)
EOF
}

# tasks_done <team> <task-id> [result-text]
# Mark a task complete.
tasks_done() {
    local team="$1" task_id="$2" result="${3:-}"
    local file lock
    file="$(tasks_file "$team")"
    lock="$(tasks_lock_file "$team")"

    python3 - "$file" "$task_id" "$lock" <<EOF
import json, sys, fcntl, datetime

tasks_file, task_id, lock_path = sys.argv[1], sys.argv[2], sys.argv[3]
result = """$result"""
now = datetime.datetime.utcnow().isoformat() + 'Z'

with open(lock_path, 'w') as lock_f:
    fcntl.flock(lock_f, fcntl.LOCK_EX)
    with open(tasks_file) as f:
        data = json.load(f)
    for t in data['tasks']:
        if t['id'] == task_id:
            t['status']  = 'done'
            t['done_at'] = now
            if result:
                t['result'] = result
            with open(tasks_file, 'w') as f:
                json.dump(data, f, indent=2)
            sys.exit(0)
    print(f"Task {task_id} not found", file=sys.stderr)
    sys.exit(1)
EOF
}
