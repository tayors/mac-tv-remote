#!/usr/bin/env python3
"""Copy the self-contained starter into a new directory without local state."""
import argparse
from pathlib import Path
import shutil


def create(destination):
    source = Path(__file__).resolve().parent.parent / 'assets' / 'starter'
    destination = Path(destination).expanduser().resolve()
    # A destination inside the source could recursively copy itself.
    if destination == source or source in destination.parents:
        raise ValueError('Choose a destination outside the starter assets.')
    if destination.exists():
        raise FileExistsError('Destination already exists; choose a new project directory.')
    shutil.copytree(source, destination, ignore=shutil.ignore_patterns('__pycache__', '*.pyc', '*.app', '.DS_Store'))
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination')
    args = parser.parse_args()
    try:
        print(create(args.destination))
    except (OSError, ValueError) as error:
        parser.exit(1, str(error) + '\n')


if __name__ == '__main__':
    main()
