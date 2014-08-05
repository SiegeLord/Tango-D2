This is a list of D compiler bugs that affect Tango, and a list of workarounds for them. When a workabout is not available, you generally can downgrade to a compiler that doesn't have the bug.

[9259](http://d.puremagic.com/issues/show_bug.cgi?id=9259) - Affects the JSON package as of 2.061. Workabout: **None.**

[9356](http://d.puremagic.com/issues/show_bug.cgi?id=9356) - Affects the Zip package as of 2.061. Workabout: Compile Tango without -inline.

[8561](https://d.puremagic.com/issues/show_bug.cgi?id=8561) - Breaks Variant in some usages (mostly using Variant as a key in a hashmap) in 2.065. In 2.066 this may no longer be an issue, but requires investigation. See [Issue #77](https://github.com/SiegeLord/Tango-D2/issues/77)Workabout: **None.**
