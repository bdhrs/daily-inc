# Kamma Workflow

This file defines the standard task structure for all threads in this project.

---

## Task Structure

Each thread is broken into **Phases**. Each phase contains a set of **Tasks**.

### Task Format
```
- [ ] Task description
```

### Phase Format
```
## Phase N: Phase Name
- [ ] Task 1
- [ ] Task 2
- [ ] PHASE COMPLETE: verify all tasks done, no regressions
```

---

## Phase Completion Protocol

At the end of every phase, append a final verification task:
```
- [ ] PHASE COMPLETE: verify all tasks done and no regressions introduced
```

---

## General Rules

- Tasks should be small and focused — completable in one sitting.
- One concern per task.
- Phases group related tasks toward a single outcome.
- Do not move to the next phase until the current one is complete.
