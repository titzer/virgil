# Process for Stable Release

1. Make sure all tests are green on all CI platforms.
   Rarely, and only judiciously, disable failing tests by renaming them to .v3.fail, putting them in test/fail, or adding them to test/suite/failures.$target

2. Bump the minor version number (i.e. III-11.7000 to III-11.7001) and set all feature flags for newly stable language features to {true} and merge to master in one commit.
   This will be the last unstable commit and will be functionally identical to the stable compiler, except that it *also* supports unstable targets.
   Verify CI is green for all CI platforms.
   Commit these changes. (C1: minor version bump)

3. Start a new branch that will become the stable version PR.
   This branch and PR will have multiple commits that should not be squashed when being merged back into the main/master branch.

4. Bump the major version number (i.e. III-11.7001 to III-12.7001) without changing the minor version number and set Debug.UNSTABLE = false;
   This fixes the source code changes and version number that will be stable.
   Verify CI is green for all CI platforms.
   Since this new stable compiler does not support *unstable* platforms, any CI for those should not be run.
   Commit these changes. (C2: major version bump and Debug.UNSTABLE = false)

5. Bootstrap the compiler for all supported stable targets, including newly-stable targets, i.e. (aeneas bootstrap <stable-host> <stable-target*>).
   This produces new binaries in bin/current/target/ for each target.
   There is nothing yet to commit, as these binaries are ignored by git.

6. Run "bin/dev/aeneas release" which copies current to stable.
   This overwrites existing stable binaries with new binaries.
   Verify CI is green for all CI platforms.
   Since this new stable compiler does not support *unstable* platforms, any CI for those should not be run.
   Do not yet commit these changes.

7. Enable any newly-stable targets in CI.
   Verify CI is green for all CI platforms, including newly stable ones.
   Commit these changes. (C3: stable binaries overwritten with new versions and CI for new stable platforms enabled)

8. Bump the major *and* minor version numbers (i.e. III-12.7001 to III-13.7002) and set Debug.UNSTABLE = true.
   This brings the source tree back into "development" mode, supporting unstable features.
   Verify CI is green for all CI platforms.
   Commit these changes. (C4: compiler versions updated and back to development mode)
   
9. Create a PR that includes C1, C2, C3, and C4.
10. After the PR passes CI, rebase and merge. DO NOT SQUASH THE COMMITS.

11. Continue development as if compiler is unstable.

After step 10, the git history is left with C1, C2, C3, and C4 as a chain of commits that allows checking out a.) the compiler just before stable, b.) the stable compiler source, c.) the stable compiler release, and d.) the new development version of the compiler.
This allows "perpetual green" checkouts while still being able to inspect and reproduce the intermediate steps later if necessary.
Also, compiler binaries are appropriately versions so that the compiler prior to stable, the stable compiler, and the compiler after stable are identifiable.
