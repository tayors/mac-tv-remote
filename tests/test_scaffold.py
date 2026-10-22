import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('scaffold', ROOT / 'scripts/create_remote.py')
scaffold = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(scaffold)


class ScaffoldTests(unittest.TestCase):
    def test_standalone_project_contains_transport_ui_build_and_tests(self):
        with tempfile.TemporaryDirectory() as directory:
            project = scaffold.create(Path(directory) / 'remote')
            for name in ['Remote.swift', 'remote_bridge.py', 'tv.py', 'build.sh', 'tests/test_tv.py', 'LICENSE']:
                self.assertTrue((project / name).is_file(), name)
            self.assertFalse(list(project.rglob('__pycache__')))

    def test_existing_project_is_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            sentinel = Path(directory) / 'keep.txt'
            sentinel.write_text('user content')
            with self.assertRaises(FileExistsError):
                scaffold.create(directory)
            self.assertEqual(sentinel.read_text(), 'user content')

    def test_destination_inside_app_is_rejected(self):
        with self.assertRaises(ValueError):
            scaffold.create(ROOT / 'app/nested-copy')


if __name__ == '__main__':
    unittest.main()
