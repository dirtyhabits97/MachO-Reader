import Env
import Foundation

// Using Bundle.module with Bazel results in a compilation error.
// It seems like rules_swift_package_manager doesn't create the bundle if the resource is not standard.
// Our resource helloworld is an executable program so that might be the reason why.
// Related: https://github.com/cgrindel/rules_swift_package_manager/issues/491
#if DEBUG && SWIFT_PACKAGE
    func getFixtureURL(_ filename: String) -> URL? {
        Bundle.module.url(forResource: filename, withExtension: nil)
    }
#else
    func getFixtureURL(_ filename: String) -> URL? {
        // From the Bazel documentation: https://bazel.build/reference/test-encyclopedia
        // The initial working directory shall be $TEST_SRCDIR/$TEST_WORKSPACE.
        // Upon further review, it seems like $PWD points to the same directory, so I will inspect that instead
        guard let pwd = env.PWD else {
            print("$PWD is not set")
            return nil
        }

        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(atPath: pwd) else {
            print("No enumerator for workingDirectory: \(pwd)")
            return nil
        }

        while let fileOrDirectory = enumerator.nextObject() as? String {
            guard
                // is inside the Fixtures folder
                fileOrDirectory.contains("Fixtures/"),
                // exact match of the given filename
                fileOrDirectory.hasSuffix(filename)
            else {
                continue
            }

            return URL(fileURLWithPath: "\(pwd)/\(fileOrDirectory)")
        }

        return nil
    }
#endif
