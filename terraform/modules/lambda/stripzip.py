# MIT License
#
# Copyright (c) 2018 Oliver Bristow
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import argparse
import mmap
import os
import sys
from struct import Struct


class NonZipFileError(ValueError):
    """Raised when a given file does not appear to be a zip"""


def _zero_zip_date_time(zip_):
    archive_size = os.fstat(zip_.fileno()).st_size

    signature_struct = Struct("<L")
    local_file_header_struct = Struct("<LHHHHHLLLHH")
    central_directory_header_struct = Struct("<LHHHHHHLLLHHHHHLL")

    offset = 0

    mm = mmap.mmap(zip_.fileno(), 0)
    while offset < archive_size:
        if signature_struct.unpack_from(mm, offset) != (0x04034b50,):
            break
        values = list(local_file_header_struct.unpack_from(mm, offset))
        _, _, _, _, _, _, _, a, _, b, c = values
        values[4] = 0
        values[5] = 0x21
        local_file_header_struct.pack_into(mm, offset, *values)
        offset += local_file_header_struct.size + a + b + c

    while offset < archive_size:
        if signature_struct.unpack_from(mm, offset) != (0x02014b50,):
            break
        values = list(central_directory_header_struct.unpack_from(mm, offset))
        _, _, _, _, _, _, _, _, _, _, a, b, c, _, _, _, _ = values
        values[5] = 0
        values[6] = 0x21
        central_directory_header_struct.pack_into(mm, offset, *values)
        offset += central_directory_header_struct.size + a + b + c

    if offset == 0:
        raise NonZipFileError(zip_.name)


def cli(args=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("zips", metavar="zip", nargs="+", type=argparse.FileType("r+b"))

    options = parser.parse_args(args)
    try:
        for zip_ in options.zips:
            _zero_zip_date_time(zip_)
            zip_.close()
    except NonZipFileError as e:
        sys.stderr.write("Invalid file format: %r\n" % e.args[0])
        sys.exit(1)
