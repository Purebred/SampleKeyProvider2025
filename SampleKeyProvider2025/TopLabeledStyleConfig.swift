//
//  TopLabeledStyleConfig.swift
//  PurebredRegistration
//
import SwiftUI

/// ``TopLabeledStyleConfig`` was poached from https://mic.st/blog/labeled-textfield-in-swiftui/.
/// Changes include dropping borders, dropping fixed width, changed variable name, and adding a read-only equivalent.
struct TopLabeledStyleConfig: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
                .font(.caption)
            configuration.content
        }
    }
}

/// ``TopLabeledTextField`` was poached from https://mic.st/blog/labeled-textfield-in-swiftui/.
/// Changes include dropping borders, dropping fixed width, changed variable name, and adding a read-only equivalent.
struct TopLabeledTextField: View {
    @Binding var text: String
    var placeholderText: String
    var labelText: String

    var body: some View {
        LabeledContent {
            TextField(placeholderText, text: $text).autocapitalization(.none)
        } label: {
            Text(labelText)
        }
        .labeledContentStyle(TopLabeledStyleConfig())
    }
}

/// ``TopLabeledTextField`` was adapted from https://mic.st/blog/labeled-textfield-in-swiftui/
/// as a read-only equivalent.
struct TopLabeledText: View {
    @Binding var text: String
    var labelText: String

    var body: some View {
        LabeledContent {
            Text(text)
        } label: {
            Text(labelText)
        }
        .labeledContentStyle(TopLabeledStyleConfig())
    }
}
