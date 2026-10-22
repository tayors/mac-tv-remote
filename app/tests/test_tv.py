import unittest
from unittest.mock import patch
from tv import TV


class DeviceBehaviourTests(unittest.TestCase):
    def setUp(self):
        with patch('tv.adb_executable', return_value='/test/adb'):
            self.tv = TV('192.0.2.10:5555')

    def test_status_reads_power_and_older_foreground_format(self):
        with patch.object(self.tv, 'shell', side_effect=[
            'mWakefulness=Asleep',
            'mResumedActivity=ActivityRecord{123 u0 com.example.player/.Main t1}',
        ]) as shell:
            self.assertEqual(self.tv.status()['foreground_app'], 'com.example.player')
            self.assertEqual(shell.call_args_list[0].args, ('dumpsys', 'power'))
            self.assertEqual(shell.call_count, 2)

    def test_discovery_returns_enabled_recognised_apps(self):
        with patch.object(self.tv, 'shell', side_effect=[
            'package:com.google.android.youtube.tv\npackage:com.example.unrelated\npackage:com.disney.disneyplus',
            'Example Android TV',
        ]) as shell:
            result = self.tv.capabilities()
            self.assertEqual(result, {'model': 'Example Android TV', 'available_apps': ['youtube', 'disney']})
            shell.assert_any_call('pm', 'list', 'packages', '--user', '0', '-e')

    def test_missing_tv_activity_does_not_send_keys(self):
        with patch.object(self.tv, 'shell', return_value='No activity found') as shell:
            with self.assertRaisesRegex(RuntimeError, 'No launchable'):
                self.tv.watch('youtube')
            self.assertEqual(shell.call_count, 1)

    def test_resolved_activity_is_launched_after_explicit_wake(self):
        component = 'com.google.android.youtube.tv/.MainActivity'
        with patch.object(self.tv, 'shell', side_effect=[component, '', 'Starting: Intent']) as shell:
            self.tv.watch('youtube')
            self.assertEqual(shell.call_args_list[1].args, ('input', 'keyevent', '224'))
            self.assertEqual(shell.call_args_list[2].args, ('am', 'start', '-n', component))

    def test_malformed_component_is_never_sent_to_shell(self):
        with patch.object(self.tv, 'shell', return_value='com.google.android.youtube.tv/.Main;reboot') as shell:
            with self.assertRaisesRegex(RuntimeError, 'No launchable'):
                self.tv.watch('youtube')
            self.assertEqual(shell.call_count, 1)

    def test_android_launch_error_is_not_reported_as_success(self):
        with patch.object(self.tv, 'shell', side_effect=[
            'com.google.android.youtube.tv/.Main', '', 'Error: Activity not started',
        ]):
            with self.assertRaisesRegex(RuntimeError, 'Activity not started'):
                self.tv.watch('youtube')


if __name__ == '__main__':
    unittest.main()
