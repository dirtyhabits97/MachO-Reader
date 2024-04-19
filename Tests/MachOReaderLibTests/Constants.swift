import Foundation
import XCTest

/// Gets the URL of a resource in the test bundle.
///
/// Triggers XCTFail if not found.
func url(for resource: String) -> URL? {
    if let url = getFixtureURL(resource) {
        return url
    }
    XCTFail("Failed to get URL for \(resource).")
    return nil
}
