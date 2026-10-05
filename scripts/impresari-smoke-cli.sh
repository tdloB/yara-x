#!/usr/bin/env bash
set -euo pipefail

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

printf '%s\n' \
  'rule impresari_smoke_v1 {' \
  '  strings: $marker = "IMPRESARI_FORK_SMOKE_MARKER" ascii' \
  '  condition: $marker' \
  '}' > "$scratch/rule.yar"
printf '%s\n' 'IMPRESARI_FORK_SMOKE_MARKER' > "$scratch/positive"
printf '%s\n' 'ordinary repository text' > "$scratch/negative"

target/debug/yr compile --output "$scratch/rules.yarc" "$scratch/rule.yar"
target/debug/yr scan --compiled-rules --no-mmap --threads 1 --timeout 5 \
  --output-format ndjson "$scratch/rules.yarc" "$scratch/positive" \
  > "$scratch/positive.ndjson"
target/debug/yr scan --compiled-rules --no-mmap --threads 1 --timeout 5 \
  --output-format ndjson "$scratch/rules.yarc" "$scratch/negative" \
  > "$scratch/negative.ndjson"

ruby -rjson -e '
  positive = File.readlines(ARGV.fetch(0), chomp: true).reject(&:empty?)
    .flat_map { |line| JSON.parse(line).fetch("rules", []) }
    .map { |rule| rule.fetch("identifier") }
  negative = File.readlines(ARGV.fetch(1), chomp: true).reject(&:empty?)
    .flat_map { |line| JSON.parse(line).fetch("rules", []) }
    .map { |rule| rule.fetch("identifier") }
  abort "positive mismatch: #{positive.inspect}" unless positive == ["impresari_smoke_v1"]
  abort "negative mismatch: #{negative.inspect}" unless negative.empty?
' "$scratch/positive.ndjson" "$scratch/negative.ndjson"

echo "Impresari module-free CLI smoke test passed"
