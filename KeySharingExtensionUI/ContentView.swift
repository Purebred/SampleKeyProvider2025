//
//  ContentView.swift
//  KeySharingExtensionUI
//

import SwiftUI

import Foundation
import UniformTypeIdentifiers

class DetailsModel: ObservableObject {
    @Published var zipViewer = false
}

/// Displays the UI, which consists of two buttons and a table view. Implements the ``TableViewDelegate`` protocol in support of two
/// different instantiations of ``TableView``. The first instantiation displays key chain contents and the second displays attributes associated
/// with a key selected in the first instantiation.
struct ContentView: View {
    /// Nested class to serve as a delegate for the ``TableView`` instances used to display key chain contents or attributes of a selected key.
    class Delegate: TableViewDelegate, ObservableObject {
        /// When true the ``TableView`` shows attributes of the key selected by the user. When false, key chain contents are shown.
        @Published var keyAttrsViewActive = false

        /// Zero-based index of the selected key in the ``TableView`` displaying key chain contents. Set in ``onTapped`` when ``keyAttrsViewActive`` is false.
        @Published var selectedKeyRow = 0

        // MARK: - TableViewDelegate Functions

        func onScroll(_: TableView, isScrolling _: Bool) {
            // nothing to do
        }

        func onAppear(_: TableView, at _: Int) {
            // nothing to do
        }

        func onTapped(_: TableView, at index: Int) {
            if !self.keyAttrsViewActive {
                self.selectedKeyRow = index
                self.keyAttrsViewActive.toggle()
                self.keyAttrsViewActive = true
            }
        }

        func heightForRow(_: TableView, at _: Int) -> CGFloat {
            64.0
        }
    }

    /// Instance of nested ``Delegate`` class
    @StateObject var delegate: Delegate = .init()

    /// KeyAttributesDataSource populated with attributes in the prepare method of DocumentActionViewController
    @ObservedObject var kads = KeyAttributesDataSource(itemAttrs: [:], mode: KeyChainDataSourceMode.ksmIdentities)
    @ObservedObject var zfds = KeyZipFileDataSource()
    @ObservedObject var mod = DetailsModel()

    /// Body consisting of two buttons and a ``TableView``. Rows in the ``TableView`` can be clicked to display a different ``TableView`` instance
    /// showing detail inforrmation about the selected key.
    var body: some View {
        NavigationStack {
            // Create an instance of TableView that lists key chain contents. Each row is clickable and when
            // clicked displays a TableView instance that shows the attributes associated with the corresponding key.
            if mod.zipViewer {
                TableView(dataSource: self.zfds, delegate: self.delegate, clickableRows: false)
            } else {
                TableView(dataSource: self.kads, delegate: self.delegate, clickableRows: false)
            }
        }.scrollContentBackground(.hidden).onAppear {}
    }
}

#Preview {
    ContentView()
}
