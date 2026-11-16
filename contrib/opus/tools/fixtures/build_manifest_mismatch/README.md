# Fixture: a build manifest that disagrees with its sheet (issue 550)

Read by contrib/opus/tools/build_manifest_tests.js, which must refuse it for exactly these seven planted faults (and no
others). The rules are in docs/ship_pipeline/build_sheets/manifest_schema.md.

| Fault | Where | Expected refusal |
|---|---|---|
| K1 is kit on the sheet, hand-built in the manifest | parts | ROUTE |
| Hull slab is hand-built on the sheet (no Route column in Major masses), kit in the manifest | masses | ROUTE |
| G1 is generated and names no library entry | parts | LIBRARY |
| G2 names test_lib/unreviewed_claw, whose review fields are empty | parts | LIBRARY |
| G4 names test_lib/missing_part, which the library does not hold | parts | LIBRARY |
| midships piece 1 (B-1 to B-2) has full_interior false | break_pieces | INTERIOR |
| stern piece (aft of B-2) is missing | break_pieces | INTERIOR |

G3 names the reviewed entry test_lib/reviewed_dish and must pass. The test library under part_libraries/test_lib/ is for
this fixture only. To see the refusal by hand:

    node contrib/opus/tools/build_manifest_tests.js contrib/opus/tools/fixtures/build_manifest_mismatch/build_sheets/fixture_X1 contrib/opus/tools/fixtures/build_manifest_mismatch/part_libraries
