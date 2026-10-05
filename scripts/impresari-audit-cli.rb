#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

def capture(*command)
  stdout, stderr, status = Open3.capture3(*command)
  [stdout, stderr, status]
end

audit_json, audit_stderr, = capture(
  "cargo", "audit", "--json"
)
abort("cargo audit produced no JSON: #{audit_stderr}") if audit_json.empty?

begin
  audit = JSON.parse(audit_json)
rescue JSON::ParserError => e
  abort("cargo audit produced invalid JSON: #{e.message}\n#{audit_stderr}")
end

tree, tree_stderr, tree_status = capture(
  "cargo", "tree", "--locked", "-p", "yara-x-cli",
  "--edges", "normal,build", "--prefix", "none"
)
abort("cargo tree failed: #{tree_stderr}") unless tree_status.success?

reachable_pairs = tree.each_line.each_with_object([]) do |line, pairs|
  match = line.match(/\A([^ ]+) v([^ ]+)/)
  pairs << [match[1], match[2]] if match
end
reachable = reachable_pairs.to_h { |name, version| [[name, version], true] }

findings = []
audit.dig("vulnerabilities", "list")&.each do |item|
  package = item.fetch("package")
  advisory = item.fetch("advisory")
  findings << {
    kind: "vulnerability",
    id: advisory.fetch("id"),
    name: package.fetch("name"),
    version: package.fetch("version")
  }
end

audit.fetch("warnings", {}).each do |kind, items|
  items.each do |item|
    package = item.fetch("package")
    findings << {
      kind: kind,
      id: item.dig("advisory", "id") || "no-advisory-id",
      name: package.fetch("name"),
      version: package.fetch("version")
    }
  end
end

reachable_findings, excluded_findings = findings.partition do |finding|
  reachable.key?([finding.fetch(:name), finding.fetch(:version)])
end

excluded_findings.each do |finding|
  warn format(
    "excluded unreachable workspace finding: %<kind>s %<id>s %<name>s %<version>s",
    **finding
  )
end

unless reachable_findings.empty?
  reachable_findings.each do |finding|
    warn format(
      "reachable CLI finding: %<kind>s %<id>s %<name>s %<version>s",
      **finding
    )
  end
  abort("Impresari YARA-X CLI dependency assurance failed")
end

puts format(
  "Impresari YARA-X CLI dependency assurance passed: reachable=%<reachable>d excluded_workspace_findings=%<excluded>d advisory_db=%<database>s",
  reachable: reachable.length,
  excluded: excluded_findings.length,
  database: audit.dig("database", "last-commit")
)
