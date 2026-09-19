import importlib.machinery
import importlib.util
import pathlib
import unittest
from unittest import mock


SCRIPT = pathlib.Path(__file__).parents[1] / "scripts" / "sunsetr-control"
loader = importlib.machinery.SourceFileLoader("sunsetr_control", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
control = importlib.util.module_from_spec(spec)
loader.exec_module(control)


class SunsetrControlTests(unittest.TestCase):
    def test_temperature_targets_keep_profiles_consistent(self):
        self.assertEqual(
            control.TARGETS["bedtime"],
            (("bedtime", "night_temp"), ("morning", "night_temp")),
        )

    @mock.patch.object(control, "apply_active")
    @mock.patch.object(control, "sunsetr")
    def test_sets_every_linked_target(self, sunsetr, apply_active):
        control.set_temperature("evening", 3750)
        self.assertEqual(
            sunsetr.call_args_list,
            [
                mock.call("set", "--target", "default", "night_temp=3750"),
                mock.call("set", "--target", "bedtime", "day_temp=3750"),
            ],
        )
        apply_active.assert_called_once_with()

    def test_rejects_unsafe_temperature(self):
        with self.assertRaisesRegex(ValueError, "between 1000 and 10000"):
            control.set_temperature("daylight", 999)

    def test_finds_temperature_in_nested_status(self):
        value = {"backend": {"current_temp": 4123}}
        self.assertEqual(control.find_number(value, {"temperature", "current_temp"}), 4123)


if __name__ == "__main__":
    unittest.main()
