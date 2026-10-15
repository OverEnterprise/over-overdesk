import sys
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(repo / "libs" / "portable"))
from generate import generate_md5_table, write_app_metadata, write_package_metadata

bundle = repo / "flutter" / "build" / "windows" / "x64" / "runner" / "Release"
packer = repo / "libs" / "portable"
write_package_metadata(
    generate_md5_table(str(bundle), 5, exclude="rustdesk.exe"),
    str(packer),
    ".\\OverDesk.exe",
)
write_app_metadata(str(packer))
