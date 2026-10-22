"""Small, read-only-by-default ADB remote transport; Python standard library only."""
import re
import shutil
import subprocess

# Add other TV apps here, after checking their package IDs on the target device.
APPS = {
    'youtube': 'com.google.android.youtube.tv',
    'stremio': 'com.stremio.one',
    'netflix': 'com.netflix.ninja',
    'prime': 'com.amazon.amazonvideo.livingroom',
    'disney': 'com.disney.disneyplus',
    'apple': 'com.apple.atve.androidtv.appletv',
}
KEYS = {
    'wake': 224, 'sleep': 223, 'home': 3, 'back': 4,
    'up': 19, 'down': 20, 'left': 21, 'right': 22, 'select': 23,
    'play': 126, 'pause': 127, 'toggle-playback': 85,
    'volume-up': 24, 'volume-down': 25, 'mute': 164,
}


def adb_executable():
    # GUI apps often have a shorter PATH than an interactive shell.
    for path in [shutil.which('adb'), '/opt/homebrew/bin/adb', '/usr/local/bin/adb']:
        if path and shutil.which(path):
            return path
    raise RuntimeError('ADB was not found. Install Android Platform Tools, then reopen the remote.')


class TV:
    def __init__(self, endpoint):
        self.endpoint = endpoint
        self.adb = adb_executable()

    def run(self, *args):
        result = subprocess.run([self.adb, *args], capture_output=True, text=True, timeout=5)
        output = result.stdout.strip()
        # adb connect can report a failure while returning exit status zero.
        if result.returncode or output.lower().startswith(('failed to connect', 'cannot connect', 'unable to connect')):
            raise RuntimeError(result.stderr.strip() or output or 'ADB command failed.')
        return output

    def connect(self):
        try:
            if self.run('-s', self.endpoint, 'get-state') == 'device':
                return
        except (RuntimeError, subprocess.TimeoutExpired):
            pass
        self.run('connect', self.endpoint)
        if self.run('-s', self.endpoint, 'get-state') != 'device':
            raise RuntimeError('TV is unavailable or requires ADB authorization.')

    def shell(self, *args):
        return self.run('-s', self.endpoint, 'shell', *args)

    def key(self, name):
        self.shell('input', 'keyevent', str(KEYS[name]))

    def status(self):
        power = self.shell('dumpsys', 'power')
        activity = self.shell('dumpsys', 'activity', 'activities')
        awake = re.search(r'mWakefulness=(\w+)', power)
        foreground = re.search(r'(?:topResumedActivity|mResumedActivity)=.*? u\d+ ([^ /}]+)/', activity)
        return {'endpoint': self.endpoint, 'power': awake.group(1) if awake else 'unknown',
                'foreground_app': foreground.group(1) if foreground else None}

    def capabilities(self):
        packages = self.shell('pm', 'list', 'packages', '--user', '0', '-e')
        installed = {line.removeprefix('package:').strip() for line in packages.splitlines()}
        model = self.shell('getprop', 'ro.product.model').strip() or 'Android TV'
        return {'model': model, 'available_apps': [name for name, package in APPS.items() if package in installed]}

    def watch(self, app):
        package = APPS[app]
        if re.fullmatch(r'[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)+', package) is None:
            raise ValueError('Invalid Android app package ID.')
        resolved = self.shell('cmd', 'package', 'resolve-activity', '--brief',
                              '-a', 'android.intent.action.MAIN',
                              '-c', 'android.intent.category.LEANBACK_LAUNCHER', package)
        components = [line.strip() for line in resolved.splitlines()
                      if re.fullmatch(re.escape(package) + r'/[A-Za-z0-9_.$]+', line.strip())]
        if len(components) != 1:
            raise RuntimeError('No launchable TV activity found for ' + app + '.')
        self.key('wake')
        output = self.shell('am', 'start', '-n', components[0])
        if re.search(r'(?im)^(?:Error|Exception)', output):
            raise RuntimeError(output)
        return output
