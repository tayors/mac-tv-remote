"""Bounded ADB transport for the native menu-bar remote."""
import argparse
import ipaddress
import json
import socket
import subprocess
import sys
import time
from tv import TV, APPS, KEYS

RemoteTV = TV


def wake_packet(mac, broadcast):
    octets = bytes.fromhex(mac.replace(':', '').replace('-', ''))
    if len(octets) != 6:
        raise ValueError('Wake address must contain six hexadecimal octets.')
    ipaddress.IPv4Address(broadcast)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as connection:
        connection.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        for port in (9, 7):
            connection.sendto(b'\xff' * 6 + octets * 16, (broadcast, port))


def reconnect(tv):
    """Reset this TV transport; repair a broken daemon only if it has no devices."""
    tv.run('disconnect', tv.endpoint)
    try:
        tv.connect()
    except RuntimeError as error:
        if 'No route to host' not in str(error):
            raise
        host, port = tv.endpoint.rsplit(':', 1)
        # Only repair if the TV is actually reachable and no other device uses ADB.
        with socket.create_connection((host, int(port)), timeout=2):
            pass
        if any(line.strip() for line in tv.run('devices').splitlines()[1:]):
            raise RuntimeError('ADB cannot reach this TV. Another device is using ADB; restart ADB after finishing that session.') from error
        tv.run('kill-server')
        tv.run('start-server')
        tv.connect()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--device', required=True)
    parser.add_argument('--discover', action='store_true', help='Include TV model and installed app shortcuts in status')
    parser.add_argument('--mac', default='')
    parser.add_argument('--broadcast', default='')
    parser.add_argument('command', choices=['status', 'reconnect', 'capabilities', *KEYS, *APPS])
    args = parser.parse_args()
    tv = RemoteTV(args.device)
    if args.command == 'wake':
        if bool(args.mac) != bool(args.broadcast):
            raise ValueError('Set both the Wake MAC and broadcast address, or leave both blank.')
        if args.mac:
            wake_packet(args.mac, args.broadcast)
        last_error = 'TV has not responded yet.'
        for attempt in range(3):
            try:
                tv.connect()
                tv.key('wake')
                print(json.dumps({'message': 'TV responded to wake.'}))
                return
            except (RuntimeError, OSError, TimeoutError, subprocess.TimeoutExpired) as error:
                last_error = str(error)
                if attempt < 2:
                    time.sleep(1)
        raise RuntimeError(('Wake signal sent. ' if args.mac else 'Network wake is not configured. Use the physical remote if the TV is asleep. ') + last_error)
    if args.command == 'reconnect':
        reconnect(tv)
    else:
        tv.connect()
    if args.command == 'capabilities':
        print(json.dumps(tv.capabilities()))
    elif args.command in ('status', 'reconnect'):
        result = tv.status()
        if args.discover:
            result.update(tv.capabilities())
        print(json.dumps(result))
    elif args.command in APPS:
        tv.watch(args.command)
        print(json.dumps({'message': 'Opened ' + args.command.capitalize()}))
    else:
        tv.key(args.command)
        print(json.dumps({'message': 'Sent ' + args.command.replace('-', ' ')}))


if __name__ == '__main__':
    try:
        main()
    except subprocess.TimeoutExpired:
        print('TV connection timed out. Check its network connection and ADB debugging, then Reconnect.', file=sys.stderr)
        sys.exit(1)
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
