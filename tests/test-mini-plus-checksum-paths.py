#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "repair", Path(__file__).resolve().parents[1] / "scripts/repair-mini-plus-checksum-paths.py")
repair = importlib.util.module_from_spec(spec)
spec.loader.exec_module(repair)


class ChecksumPaths(unittest.TestCase):
    def test_paths_restored_hashes_and_local_changes_retained(self):
        original = f"{'a'*64}  icons/Acorn\n{'b'*64}  bin/live-edited\n"
        reference = f"{'a'*64}  icons/Acorn - Risc PC.png\n{'c'*64}  bin/live-edited\n"
        output, changes = repair.repair(original, reference)
        self.assertEqual(output, f"{'a'*64}  icons/Acorn - Risc PC.png\n{'b'*64}  bin/live-edited\n")
        self.assertEqual(len(changes), 1)
        self.assertEqual(repair.repair(output, reference), (output, []))

    def test_ambiguous_prefix_fails_closed(self):
        with self.assertRaises(ValueError):
            repair.repair(f"{'a'*64}  prefix\n",
                          f"{'a'*64}  prefix one\n{'a'*64}  prefix two\n")

    def test_wrong_digest_cannot_restore_path(self):
        original = f"{'a'*64}  prefix\n"
        self.assertEqual(repair.repair(original, f"{'b'*64}  prefix one\n"),
                         (original, []))

    def test_complete_duplicate_hash_multiset_restored(self):
        output, changes = repair.repair(f"{'a'*64}  Atari\n" * 2,
                                       f"{'a'*64}  Atari one\n{'a'*64}  Atari two\n")
        self.assertEqual(len(changes), 2)
        self.assertEqual(output, f"{'a'*64}  Atari one\n{'a'*64}  Atari two\n")

    def test_unsafe_path_rejected(self):
        with self.assertRaises(ValueError):
            repair.entries(f"{'a'*64}  ../config\n")


if __name__ == "__main__":
    unittest.main()
