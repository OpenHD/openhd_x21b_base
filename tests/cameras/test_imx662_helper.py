#!/usr/bin/env python3
"""Check sensor/ISP command mapping with mock media tools; no hardware involved."""
import json
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    helper = Path(__file__).resolve().parents[2] / "device/rockchip/common/overlays/x21-misc/usr/bin/x21-imx662-mode"
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory)
        devices = [path / "media0", path / "media1"]
        for device in devices:
            device.touch()
        stub = '''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['COMMAND_LOG'], 'a') as log:
    log.write(json.dumps([os.path.basename(sys.argv[0])] + sys.argv[1:]) + '\\n')
if '-p' in sys.argv:
    if sys.argv[2].endswith('media0'):
        print('- entity 7: m00_f_imx662 5-001a (1 pad, 1 link)')
    else:
        print('- entity 4: rkisp_mainpath (1 pad, 1 link)')
        print('- entity 1: rkisp-isp-subdev (4 pads, 6 links)')
elif '-e' in sys.argv:
    print('/dev/video42' if sys.argv[-1] == 'rkisp_mainpath' else '/dev/v4l-subdev7')
'''
        for name in ["media-ctl", "v4l2-ctl"]:
            tool = path / name
            tool.write_text(stub)
            tool.chmod(0o755)
        log = path / "commands.jsonl"
        env = dict(os.environ, PATH=f"{path}:{os.environ['PATH']}",
                   COMMAND_LOG=str(log), IMX662_MEDIA_DEVICES=" ".join(map(str, devices)))
        for resolution, depth, width, sensor_width, sensor_height, height, left, top, hmax, vmax, hdr in [
            ("1080p", "raw10", 1920, 1920, 1080, 1080, 0, 0, 660, 1150, 0),
            ("720p", "raw10", 1280, 1280, 752, 720, 0, 16, 660, 822, 0),
            ("720p", "raw12", 1280, 1280, 752, 720, 0, 16, 990, 822, 0),
            ("full90", "raw10", 1920, 1936, 1100, 1080, 8, 8, 660, 1250, 0),
            ("hdr45", "raw10", 1920, 1936, 1100, 1080, 8, 8, 660, 2500, 1),
        ]:
            log.write_text("")
            subprocess.run(["sh", str(helper), resolution, "max", depth],
                           env=env, check=True, capture_output=True)
            commands = [json.loads(line) for line in log.read_text().splitlines()]
            formats = [c[-1] for c in commands if "--set-v4l2" in c]
            code = "SRGGB10_1X10" if depth == "raw10" else "SRGGB12_1X12"
            assert formats == [
                f"'m00_f_imx662 5-001a':0[fmt:{code}/{sensor_width}x{sensor_height}@{hmax*vmax}/74250000]",
                f"'rkisp-isp-subdev':0[fmt:{code}/{sensor_width}x{sensor_height} crop:({left},{top})/{width}x{height}]",
                f"'rkisp-isp-subdev':2[fmt:YUYV8_2X8/{width}x{height} crop:(0,0)/{width}x{height}]",
            ], formats
            assert ["v4l2-ctl", "-d", "/dev/v4l-subdev7", f"--set-ctrl=hdr_sensor_mode={hdr}"] in commands
            assert ["v4l2-ctl", "-d", "/dev/video42",
                    f"--set-fmt-video=width={width},height={height},pixelformat=NV12"] in commands
        for args in [("720p", "0"), ("720p", "bad"), ("720p", "max", "raw8"), ("hdr45", "max", "raw12")]:
            log.write_text("")
            result = subprocess.run(["sh", str(helper), *args], env=env, capture_output=True)
            assert result.returncode == 2
            assert not log.read_text(), "Invalid input must fail before configuring hardware"
    print("IMX662 helper command mapping passed (mock media tools)")


if __name__ == "__main__":
    main()
