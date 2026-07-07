import SwiftUI

struct MarkdownText: View {
    let text: String

    var body: some View {
        Text(attributed)
            .textSelection(.enabled)
    }

    private var attributed: AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
}
