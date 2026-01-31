import Foundation

/// Shared configuration for formatting output
struct FormattingConfig {

    // MARK: - Column Widths

    let commandTypeWidth: Int
    let labelWidth: Int
    let valueWidth: Int
    let segmentNameWidth: Int
    let sectionNameWidth: Int

    // MARK: - Indentation & Spacing

    let indent: String
    let fieldSeparator: String

    // MARK: - Presets

    static let `default` = FormattingConfig(
        commandTypeWidth: 24,
        labelWidth: 20,
        valueWidth: 10,
        segmentNameWidth: 16,
        sectionNameWidth: 25,
        indent: "    ",
        fieldSeparator: "   "
    )

    static let compact = FormattingConfig(
        commandTypeWidth: 20,
        labelWidth: 16,
        valueWidth: 8,
        segmentNameWidth: 12,
        sectionNameWidth: 20,
        indent: "  ",
        fieldSeparator: " "
    )
}
