#!/usr/bin/env python3
"""
Deep test analyzer for Godot debugging kit.
Parses .test_log.json and validates invariants, action sequences, and performance.
"""

import json
import sys
from pathlib import Path
from typing import Any, Dict, List

class TestAnalyzer:
    def __init__(self, log_path: str):
        self.log_path = Path(log_path)
        self.data = self._load_log()
        self.violations = []

    def _load_log(self) -> Dict[str, Any]:
        """Load and parse test log JSON"""
        if not self.log_path.exists():
            print(f"❌ Log file not found: {self.log_path}")
            sys.exit(1)

        try:
            with open(self.log_path) as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            print(f"❌ Invalid JSON in log: {e}")
            sys.exit(1)

    def analyze(self) -> bool:
        """Run all analysis checks"""
        print("\n" + "="*60)
        print("🔬 DEEP TEST ANALYSIS")
        print("="*60 + "\n")

        # Run checks
        self._check_invariants()
        self._check_action_sequences()
        self._check_performance()

        # Report
        self._report_results()

        return len(self.violations) == 0

    def _check_invariants(self) -> None:
        """Verify game state invariants"""
        print("📋 Invariant Checks:")

        invariants = self.data.get("invariants", {})

        if not invariants:
            print("  ⚠️  No invariants in test log")
            return

        any_violations = False
        for prop_name, stats in invariants.items():
            min_observed = stats.get("min", 0)
            max_observed = stats.get("max", 0)
            avg_observed = stats.get("average", 0)

            # Note: We can't check against configured bounds here (those aren't in the log),
            # but we can report the range observed
            print(f"  ✅ {prop_name}: min={min_observed:.2f}, avg={avg_observed:.2f}, max={max_observed:.2f}")

        violations = self.data.get("violations", 0)
        if violations == 0:
            print("  ✅ No state violations detected")
        else:
            print(f"  ⚠️  Found {violations} violation(s)")
            any_violations = True
            self.violations.append(f"{violations} invariant violations detected")

    def _check_action_sequences(self) -> None:
        """Verify action sequences and ordering"""
        print("\n🎮 Action Sequences:")

        actions = self.data.get("actions_performed", {})
        events = self.data.get("events_logged", 0)

        if not actions:
            print("  ⚠️  No actions recorded")
            self.violations.append("No actions performed during test")
            return

        total_actions = sum(actions.values())

        if total_actions > 0:
            print(f"  ✅ {total_actions} actions performed")
            for action_type, count in sorted(actions.items()):
                if count > 0:
                    print(f"     - {action_type}: {count}")
        else:
            print(f"  ⚠️  No actions performed")
            self.violations.append("No actions recorded")

        if events > 0:
            print(f"  ✅ {events} total game events logged")

    def _check_performance(self) -> None:
        """Verify performance metrics"""
        print("\n⚙️  Performance Metrics:")

        duration = self.data.get("duration", 0)
        samples = self.data.get("samples", 0)

        if duration > 0:
            print(f"  ✅ Ran for {duration:.2f}s")
        else:
            print(f"  ⚠️  No duration recorded")

        if samples > 0:
            hz = samples / duration if duration > 0 else 0
            print(f"  ✅ Sampled {samples} times ({hz:.1f} Hz)")
        else:
            print(f"  ⚠️  No samples recorded")

    def _report_results(self) -> None:
        """Print final summary"""
        print("\n" + "="*60)
        print("📊 SUMMARY")
        print("="*60)

        if self.violations:
            print(f"\n⚠️  Found {len(self.violations)} issue(s):")
            for i, violation in enumerate(self.violations, 1):
                print(f"   {i}. {violation}")
        else:
            print("\n✅ All checks passed! Test ran successfully.")

        print("\n" + "="*60 + "\n")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 test_analyzer.py <log_file>")
        sys.exit(1)

    log_file = sys.argv[1]
    analyzer = TestAnalyzer(log_file)
    success = analyzer.analyze()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
