#!/usr/bin/env bash
# reorganize.sh — reorganiza a árvore do KinetOS para refletir a filosofia
# de núcleo certificável + isolamento temporal.
#
# Estado atual: árvore não rastreada, apenas .gitkeep e docs.
# Estratégia: mv de diretórios e arquivos, recriação de .gitkeep onde sobrar vazio.
set -euo pipefail

cd "$(dirname "$0")"

echo "==> [1/5] Criando nova estrutura de diretórios..."

dirs=(
    "docs/design"
    "docs/contracts"

    "core/sched/edf"
    "core/sched/admission"
    "core/sched/deadline"
    "core/sched/policies"
    "core/time"
    "core/isolation/temporal"
    "core/isolation/spatial"
    "core/ipc"
    "core/exceptions"
    "core/sync"
    "core/syscall"

    "platform/hal/aarch64"
    "platform/hal/riscv64"
    "platform/hal/x86_64"
    "platform/hal/contracts"
    "platform/drivers/certified"
    "platform/drivers/partitioned"
    "platform/boot/bios"
    "platform/boot/uefi"
    "platform/boot/multiboot2"

    "services/fs"
    "services/net"
    "services/userspace"

    "lib/no-alloc"
    "lib/general"

    "validation/wcet"
    "validation/adversarial"
    "validation/chaos"
    "validation/benchmarks"
    "validation/conformance"
    "validation/unit"
    "validation/integration"
    "validation/stress"
    "validation/latency"

    "configs/hard-rt"
    "configs/soft-rt"
    "configs/minimal"

    "tools/build"
    "tools/debug"
    "tools/emulator"
    "tools/image"

    "include/kinet"
    "include/uapi"
)
for d in "${dirs[@]}"; do mkdir -p "$d"; done

# ---------------------------------------------------------------------
# Helper: move conteúdo real (ignora .gitkeep) de $1 para $2
# ---------------------------------------------------------------------
move_real() {
    local src="$1" dst="$2"
    [ -d "$src" ] || return 0
    mkdir -p "$dst"
    find "$src" -mindepth 1 -maxdepth 1 -not -name '.gitkeep' -exec mv {} "$dst/" \;
    rm -rf "$src"
}

# ---------------------------------------------------------------------
# Helper: move arquivo único se existir
# ---------------------------------------------------------------------
move_file() {
    local src="$1" dst="$2"
    [ -f "$src" ] || return 0
    mkdir -p "$(dirname "$dst")"
    mv "$src" "$dst"
}

echo "==> [2/5] Migrando núcleo temporal (kernel/ → core/)..."

move_real kernel/sched       core/sched
move_real kernel/time        core/time
move_real kernel/ipc         core/ipc
move_real kernel/irq         core/exceptions/irq
move_real kernel/panic       core/exceptions/panic
move_real kernel/sync        core/sync
move_real kernel/syscall     core/syscall
move_real kernel/mm          core/isolation/spatial
move_real kernel/core        core/
move_real kernel             core/

echo "==> [3/5] Migrando hardware (arch/, boot/, drivers/ → platform/)..."

# README do arch/ é documentação, não código — vai para docs/
move_file arch/README.md docs/hal-overview.md

move_real arch/aarch64       platform/hal/aarch64
move_real arch/riscv64       platform/hal/riscv64
move_real arch/x86_64        platform/hal/x86_64
move_real arch               platform/hal/

move_real drivers/timer      platform/drivers/partitioned/timer
move_real drivers/block      platform/drivers/partitioned/block
move_real drivers/char       platform/drivers/partitioned/char
move_real drivers/bus        platform/drivers/partitioned/bus
move_real drivers/net        platform/drivers/partitioned/net
move_real drivers/interrupt  platform/drivers/partitioned/interrupt
move_real drivers            platform/drivers/partitioned/

move_real boot               platform/boot/

echo "==> [4/5] Migrando serviços, libs e validação..."

move_real fs                 services/fs
move_real net                services/net
move_real userspace          services/userspace

move_real lib/bitmap         lib/no-alloc/bitmap
move_real lib/hash           lib/no-alloc/hash
move_real lib/list           lib/no-alloc/list
move_real lib/math           lib/no-alloc/math
move_real lib/printk         lib/no-alloc/printk
move_real lib/rbtree         lib/no-alloc/rbtree
move_real lib/string         lib/no-alloc/string
move_real lib                lib/no-alloc/

# READMEs de benchmarks/ e tests/ são doc — vão para validation/
move_file benchmarks/README.md validation/benchmarks/README.md
move_file tests/README.md      validation/README.md

move_real benchmarks/jitter     validation/benchmarks/jitter
move_real benchmarks/latency    validation/benchmarks/latency
move_real benchmarks/throughput validation/benchmarks/throughput
move_real benchmarks            validation/benchmarks/

move_real tests/unit        validation/unit
move_real tests/integration validation/integration
move_real tests/stress      validation/stress
move_real tests/latency     validation/latency
move_real tests             validation/

# Configs: renomeia defconfigs vazios para o perfil correto
move_file configs/defconfig_x86_64  configs/hard-rt/x86_64.defconfig
move_file configs/defconfig_latency configs/hard-rt/x86_64-latency.defconfig
move_file configs/defconfig_debug   configs/soft-rt/x86_64-debug.defconfig
rmdir configs 2>/dev/null || true

echo "==> [5/5] Aplicando .gitkeep em diretórios vazios..."

find . -type d \
    -not -path './.git' -not -path './.git/*' \
    -not -path './assets*' \
    -not -path './.github*' \
    -empty -exec touch {}/.gitkeep \;

echo "==> Migração concluída. Rode 'tree -L 3 -d' para conferir."
