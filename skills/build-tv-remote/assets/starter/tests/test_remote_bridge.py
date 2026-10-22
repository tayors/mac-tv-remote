import contextlib
import io
import json
import subprocess
import sys
import unittest
from unittest.mock import patch

import remote_bridge as bridge


class RemoteTransportTests(unittest.TestCase):
    def invoke(self, command):
        with patch.object(sys, 'argv', ['remote_bridge.py', '--device', '192.0.2.10:5555', '--mac', '02:00:00:00:00:01', '--broadcast', '192.0.2.255', command]):
            with contextlib.redirect_stdout(io.StringIO()) as output:
                bridge.main()
            return json.loads(output.getvalue())

    def test_status_reads_without_sending_keys_or_launching_apps(self):
        with patch.object(bridge, 'RemoteTV') as factory:
            tv = factory.return_value
            tv.status.return_value = {'power': 'Asleep'}
            self.assertEqual(self.invoke('status')['power'], 'Asleep')
            tv.key.assert_not_called()
            tv.watch.assert_not_called()

    def test_play_pause_sends_android_media_toggle(self):
        with patch('tv.adb_executable', return_value='/test/adb'):
            tv = bridge.TV('192.0.2.10:5555')
        with patch.object(tv, 'shell') as shell:
            tv.key('toggle-playback')
            shell.assert_called_once_with('input', 'keyevent', '85')

    def test_wake_retries_after_adb_timeout(self):
        with patch.object(bridge, 'RemoteTV') as factory, patch.object(bridge, 'wake_packet') as wake, patch.object(bridge.time, 'sleep'):
            tv = factory.return_value
            tv.connect.side_effect = [subprocess.TimeoutExpired('adb', 15), None]
            self.invoke('wake')
            self.assertEqual(tv.connect.call_count, 2)
            tv.key.assert_called_once_with('wake')
            wake.assert_called_once()

    def test_adb_connect_failure_in_stdout_is_reported(self):
        with patch('tv.adb_executable', return_value='/test/adb'):
            tv = bridge.RemoteTV('192.0.2.10:5555')
        result = subprocess.CompletedProcess([], 0, "failed to connect: No route to host", "")
        with patch.object(bridge.subprocess, 'run', return_value=result):
            with self.assertRaisesRegex(RuntimeError, 'No route to host'):
                tv.run('connect', tv.endpoint)

    def test_connected_transport_is_reused(self):
        with patch('tv.adb_executable', return_value='/test/adb'):
            tv = bridge.RemoteTV('192.0.2.10:5555')
        with patch.object(tv, 'run', return_value='device') as run:
            tv.connect()
            run.assert_called_once_with('-s', tv.endpoint, 'get-state')

    def test_reconnect_repairs_daemon_only_when_no_other_devices(self):
        with patch.object(bridge, 'RemoteTV') as factory, patch.object(bridge.socket, 'create_connection'):
            tv = factory.return_value
            tv.endpoint = '192.0.2.10:5555'
            tv.connect.side_effect = [RuntimeError('No route to host'), None]
            tv.run.side_effect = ['', 'List of devices attached\n', '', '']
            bridge.reconnect(tv)
            self.assertIn(unittest.mock.call('kill-server'), tv.run.call_args_list)
            self.assertEqual(tv.connect.call_count, 2)

    def test_reconnect_keeps_other_device_sessions(self):
        with patch.object(bridge, 'RemoteTV') as factory, patch.object(bridge.socket, 'create_connection'):
            tv = factory.return_value
            tv.endpoint = '192.0.2.10:5555'
            tv.connect.side_effect = RuntimeError('No route to host')
            tv.run.side_effect = ['', 'List of devices attached\nphone123\tdevice\n']
            with self.assertRaisesRegex(RuntimeError, 'Another device'):
                bridge.reconnect(tv)
            self.assertNotIn(unittest.mock.call('kill-server'), tv.run.call_args_list)

    def test_wake_without_network_details_uses_adb_only(self):
        with patch.object(bridge, 'RemoteTV') as factory, patch.object(bridge, 'wake_packet') as wake:
            with patch.object(sys, 'argv', ['remote_bridge.py', '--device', '192.0.2.10:5555', 'wake']):
                with contextlib.redirect_stdout(io.StringIO()):
                    bridge.main()
            wake.assert_not_called()
            factory.return_value.key.assert_called_once_with('wake')

    def test_partial_wake_config_is_rejected_without_sending_packets(self):
        with patch.object(bridge, 'RemoteTV'), patch.object(bridge, 'wake_packet') as wake:
            with patch.object(sys, 'argv', ['remote_bridge.py', '--device', '192.0.2.10:5555', '--mac', '02:00:00:00:00:01', 'wake']):
                with self.assertRaisesRegex(ValueError, 'both'):
                    bridge.main()
            wake.assert_not_called()

    def test_discovery_is_read_only(self):
        with patch.object(bridge, 'RemoteTV') as factory:
            tv = factory.return_value
            tv.status.return_value = {'power': 'Awake'}
            tv.capabilities.return_value = {'model': 'Example TV', 'available_apps': ['youtube']}
            with patch.object(sys, 'argv', ['remote_bridge.py', '--device', '192.0.2.10:5555', '--discover', 'status']):
                with contextlib.redirect_stdout(io.StringIO()) as output:
                    bridge.main()
            self.assertEqual(json.loads(output.getvalue())['available_apps'], ['youtube'])
            tv.key.assert_not_called()
            tv.watch.assert_not_called()

    def test_wake_packet_format(self):
        with patch.object(bridge.socket, 'socket') as factory:
            connection = factory.return_value.__enter__.return_value
            bridge.wake_packet('02:00:00:00:00:01', '192.0.2.255')
            packet = b'\xff' * 6 + bytes.fromhex('020000000001') * 16
            self.assertEqual(connection.sendto.call_args_list[0].args, (packet, ('192.0.2.255', 9)))
            self.assertEqual(connection.sendto.call_args_list[1].args, (packet, ('192.0.2.255', 7)))


if __name__ == '__main__':
    unittest.main()
