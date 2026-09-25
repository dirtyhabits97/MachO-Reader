import Foundation

func getFixtureURL(_ filename: String) -> URL? {
    Bundle.module.url(forResource: filename, withExtension: nil)
}
