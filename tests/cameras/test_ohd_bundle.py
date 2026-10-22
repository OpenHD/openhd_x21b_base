"""Exercise production and incremental packaging without a board or SDK."""
from pathlib import Path
import os, subprocess, tempfile, unittest
HOOK=Path(__file__).resolve().parents[2]/'device/rockchip/common/post-hooks/10-move-openhd.sh'
class BundleTest(unittest.TestCase):
    def test_fresh_and_incremental_bundle_excludes_debug_state(self):
        with tempfile.TemporaryDirectory() as tmp:
            sdk=Path(tmp);target=sdk/'buildroot/output/test/target'
            for name in ['openhd','openhd_sys_utils']:
                p=target/'usr/bin'/name;p.parent.mkdir(parents=True,exist_ok=True)
                p.write_text('#!/bin/sh\n');p.chmod(0o755)
            libs=target/'usr/lib';libs.mkdir(parents=True)
            for name in ['PocoFoundation','PocoNet','PocoEncodings','pcap','sodium','usb-1.0','rtlsdr','rockchip_mpp']:
                (libs/f'lib{name}.so.123').write_bytes(b'library')
                (libs/f'lib{name}.so').symlink_to(f'lib{name}.so.123')
            overlay=sdk/'ohd-misc';overlay.mkdir()
            (overlay/'start-ohd.sh').write_text('#!/bin/sh\n');(overlay/'start-ohd.sh').chmod(0o755)
            old=sdk/'output/ohd-bundle/x21-diagnostics';old.mkdir(parents=True)
            (old/'debug-key').write_text('must not ship')
            env=dict(os.environ,RK_SDK_DIR=str(sdk))
            for _ in range(2):
                subprocess.run(['bash',str(HOOK),str(target)],env=env,check=True)
                store=sdk/'output/ohd-bundle'
                self.assertFalse((store/'x21-diagnostics').exists())
                self.assertTrue((store/'usr/lib/libsodium.so').is_file())
                self.assertTrue((store/'usr/bin/openhd').is_file())
                self.assertTrue((sdk/'output/extra-parts/ohd/start-ohd.sh').exists())
                self.assertFalse((target/'usr/bin/openhd').exists())
                self.assertTrue((libs/'librockchip_mpp.so').exists())
if __name__=='__main__':unittest.main()
