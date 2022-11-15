# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import argparse
import pprint

from cpt.packager import ConanMultiPackager

def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument('-u', '--username', default=None, help='The Conan username to use for the built package.')
    parser.add_argument('-c', '--channel', default=None, help='The Conan channel to use for the built package.')
    parser.add_argument('--dry-run', action='store_true', help='Print the configurations that would be built without actually building them.')
    return parser.parse_args()

def main() -> None:
    args = parse_arguments()

    packager_args = {
        'username': args.username,
        'channel': args.channel,
    }

    builder = ConanMultiPackager(**packager_args)
    builder.add()

    if args.dry_run:
        pprint.pprint(builder.builds, indent=4)
    else:
        builder.run()


if __name__ == '__main__':
    main()
