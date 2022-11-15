# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

from conans import ConanFile

class ThinkboxCMLibraryConan(ConanFile):
    name: str = 'thinkboxcmlibrary'
    version: str = '1.0.0'
    license: str = 'Apache-2.0'
    description: str = 'Shared code for Thinkbox CMake-based builds.'
    no_copy_source: bool = True

    def export_sources(self) -> None:
        self.copy('*.cmake', src='', dst='')

    def package(self) -> None:
        self.copy('*.cmake', src='', dst='')

    def deploy(self) -> None:
        self.copy('*.cmake', src='', dst='')

    def package_id(self) -> None:
        self.info.header_only()
