#!/bin/bash
set -e

V3_DIR="/app/data/所有对话/主对话/agent-passport/contracts/v3"
BUILD_DIR="${V3_DIR}/build"
mkdir -p "${BUILD_DIR}"

echo "=== V3 Compilation ==="
echo "Output: ${BUILD_DIR}"

# Find solc
SOLC=$(command -v solc 2>/dev/null || command -v solc-0.8.24 2>/dev/null || echo "")
if [ -z "$SOLC" ]; then
    echo "ERROR: solc not found"
    exit 1
fi
echo "Using: $SOLC ($($SOLC --version | head -1))"

# We need OpenZeppelin imports. Check if there's a node_modules anywhere
PROJECT_ROOT="/app/data/所有对话/主对话/agent-passport"
OZ_PATH=""
for p in \
    "${PROJECT_ROOT}/node_modules" \
    "${PROJECT_ROOT}/contracts/node_modules" \
    "${PROJECT_ROOT}/contracts/v3/node_modules"; do
    if [ -d "$p/@openzeppelin" ]; then
        OZ_PATH="$p"
        break
    fi
done

# If no node_modules, try to find it with find
if [ -z "$OZ_PATH" ]; then
    OZ_PATH=$(find /app/data -type d -name "@openzeppelin" -path "*/node_modules/*" 2>/dev/null | head -1 | sed 's|/@openzeppelin||')
fi

if [ -z "$OZ_PATH" ]; then
    echo "ERROR: @openzeppelin not found in node_modules"
    exit 1
fi
echo "OZ: $OZ_PATH"

# Compile each contract
cd "${V3_DIR}"
for sol in AgentRegistry.sol AgentPassport.sol CompliancePassport.sol AccessGateway.sol; do
    echo ""
    echo "--- Compiling ${sol} ---"
    $SOLC \
        --via-ir --optimize \
        --bin --abi \
        --base-path . \
        --include-path "${OZ_PATH}" \
        -o "${BUILD_DIR}" \
        --overwrite \
        "${sol}" 2>&1 || {
            echo "FAILED: ${sol}"
            exit 1
        }
    echo "OK: ${sol}"
done

echo ""
echo "=== Build artifacts ==="
ls -la "${BUILD_DIR}"/*.bin "${BUILD_DIR}"/*.abi 2>/dev/null
echo "=== Done ==="
