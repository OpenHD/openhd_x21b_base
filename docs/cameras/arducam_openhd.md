# arducam_openhd on X21B

The production profile is `rv1126b:openhd_x21b_arducam_openhd_defconfig`.
It uses the matching camera DTB and kernel configuration fragment, native MPP
encoding, a read-only SquashFS root and the normal 100 MiB OHD partition.

Product image builds supply qualified camera provisioning data through the
private X21B pipeline. No camera firmware payload or bench state is distributed
as source in this repository. Use the complete product image or A/B base update
when installing camera driver changes; an OHD-only application update does not
replace the kernel.
