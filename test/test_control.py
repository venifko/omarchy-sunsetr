import datetime as dt
import importlib.machinery
import importlib.util
import pathlib
import unittest


SCRIPT = pathlib.Path(__file__).parents[1] / "scripts" / "sunsetr-control"
loader = importlib.machinery.SourceFileLoader("sunsetr_control", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
control = importlib.util.module_from_spec(spec)
loader.exec_module(control)


class SunsetrControlTests(unittest.TestCase):
    def settings(self):
        values = dict(control.DEFAULTS)
        values.update({"scheduleMode": "clock", "wakeTime": "06:30",
                       "sleepTime": "22:30", "eveningTime": "18:30"})
        return values

    def at(self, hour, minute=0):
        return dt.datetime(2026, 9, 19, hour, minute, tzinfo=dt.timezone(dt.timedelta(hours=2)))

    def test_daylight_phase(self):
        result = control.schedule(self.settings(), self.at(12))
        self.assertEqual((result["phase"], result["temperature"]), ("daylight", 6500))

    def test_smooth_sunset_transition(self):
        result = control.schedule(self.settings(), self.at(19))
        self.assertEqual(result["phase"], "sunset")
        self.assertTrue(4000 < result["temperature"] < 6500)

    def test_wind_down_reaches_bedtime_temperature(self):
        result = control.schedule(self.settings(), self.at(22, 29))
        self.assertEqual(result["phase"], "wind-down")
        self.assertLess(result["temperature"], 3000)

    def test_sleep_wraps_across_midnight(self):
        self.assertEqual(control.schedule(self.settings(), self.at(2))["phase"], "sleep")

    def test_manual_solar_location_is_plausible(self):
        event = control.solar_event(dt.date(2026, 6, 21), 49.3961, 15.5912, True, 2)
        self.assertIsNotNone(event)
        self.assertGreater(event, 20 * 60)
        self.assertLess(event, 22 * 60)

    def test_rejects_invalid_time_and_location(self):
        with self.assertRaisesRegex(ValueError, "HH:MM"):
            control.validate_setting("wakeTime", "27:90")
        with self.assertRaisesRegex(ValueError, "latitude"):
            control.validate_setting("latitude", "120")

    def test_fullscreen_and_app_exclusions_disable_filter(self):
        values = self.settings()
        values["disableFullscreen"] = True
        window = {"class": "video", "title": "Movie", "fullscreen": True, "monitor": 0}
        self.assertEqual(control.desired(values, self.at(12), window)["overrideReason"], "fullscreen")

        values["disableFullscreen"] = False
        values["excludedApps"] = ["firefox"]
        window["class"] = "Firefox"
        self.assertEqual(control.desired(values, self.at(12), window)["overrideReason"], "app: Firefox")

    def test_wayland_output_name_maps_to_dbus_path(self):
        self.assertEqual(control.relay_path("eDP-1"), "/outputs/eDP_1")


if __name__ == "__main__":
    unittest.main()
