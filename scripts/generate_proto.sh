#!/usr/bin/env bash
# =================================================================
# generate_proto.sh
# Mengenerate kode Go dan Python dari .proto files
#
# Prerequisites:
#   Go:     go install google.golang.org/protoc-gen-go@latest
#           go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
#   Python: pip install grpcio-tools
#   System: brew install protobuf (macOS) / apt install protobuf-compiler (Linux)
#
# Usage: ./scripts/generate_proto.sh
# =================================================================

set -e

PROTO_DIR="proto"
GO_OUT="apps/api-gateway/gen/go"
PYTHON_OUT="apps/debate-engine/gen/python"

echo "🔧 Generating protobuf code..."

# Buat output directories
mkdir -p "$GO_OUT"
mkdir -p "$PYTHON_OUT"

# ── Go codegen ────────────────────────────────────────────────
echo "📦 Generating Go code..."
protoc \
  --proto_path=. \
  --go_out="$GO_OUT" \
  --go_opt=paths=source_relative \
  --go-grpc_out="$GO_OUT" \
  --go-grpc_opt=paths=source_relative \
  "$PROTO_DIR/messages.proto" \
  "$PROTO_DIR/debate.proto" \
  "$PROTO_DIR/knowledge.proto"

echo "✅ Go code generated at $GO_OUT"

# ── Python codegen ────────────────────────────────────────────
echo "🐍 Generating Python code..."
python -m grpc_tools.protoc \
  --proto_path=. \
  --python_out="$PYTHON_OUT" \
  --grpc_python_out="$PYTHON_OUT" \
  --pyi_out="$PYTHON_OUT" \
  "$PROTO_DIR/messages.proto" \
  "$PROTO_DIR/debate.proto" \
  "$PROTO_DIR/knowledge.proto"

# Fix Python import paths (protoc menghasilkan absolute imports)
echo "🔧 Fixing Python imports..."
find "$PYTHON_OUT" -name "*.py" -exec sed -i \
  's/^import messages_pb2/from debateai.v1 import messages_pb2/g' {} \;
find "$PYTHON_OUT" -name "*.py" -exec sed -i \
  's/^import debate_pb2/from debateai.v1 import debate_pb2/g' {} \;
find "$PYTHON_OUT" -name "*.py" -exec sed -i \
  's/^import knowledge_pb2/from debateai.v1 import knowledge_pb2/g' {} \;

echo "✅ Python code generated at $PYTHON_OUT"
echo ""
echo "🎉 Proto generation complete!"
echo ""
echo "Next steps:"
echo "  Go    : cd apps/api-gateway && go build ./..."
echo "  Python: cd apps/debate-engine && python main.py"
