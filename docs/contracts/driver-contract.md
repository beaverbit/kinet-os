# Driver Contract

Every driver, to be accepted, explicitly declares:

- **WCET** per exposed operation.
- **May block?** (yes/no, and for how long at most)
- **May allocate?** (yes/no — default: no)
- **Where it runs:** certifiable kernel (`certified/`) or partition (`partitioned/`).

Drivers that do not declare are rejected.
