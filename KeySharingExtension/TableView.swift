//  Adapted from https://github.com/peterent/CustomTableView
//
//  TableView.swift
//  CustomTableView
//
//  Created by Peter Ent on 12/4/19.
//  Copyright © 2019 Peter Ent. All rights reserved.
//

import SwiftUI

/// ``TableViewDataSource``defines the interface for retrieving data to display in the table. The basic approach to displaying
/// table contents is adapted from <https://github.com/peterent/CustomTableView>.
protocol TableViewDataSource {
    func count() -> Int
    func titleForRow(row: Int) -> String
    func subtitleForRow(row: Int) -> String?
}

/// ``TableViewDelegate``defines the interface for reporting table-related events. The basic approach to displaying
/// table contents is adapted from <https://github.com/peterent/CustomTableView>.
protocol TableViewDelegate: AnyObject {
    func heightForRow(_ tableView: TableView, at index: Int) -> CGFloat
    func onScroll(_ tableView: TableView, isScrolling: Bool)
    func onAppear(_ tableView: TableView, at index: Int)
    func onTapped(_ tableView: TableView, at index: Int)
}

/// ``TableView`` is used to display key chain contents or attributes associated with a given key. The basic approach to displaying
/// table contents is adapted from <https://github.com/peterent/CustomTableView>.
///
/// When used to display key chain contents, the `clickableRows` variable should be set to true and the `dataSource` variable
/// should be set to an instance of ``KeyChainDataSource``.
///
/// When used to display attributes for a given key, the `clickableRows` variable should be set  to false and the `dataSource`
/// variable should be set to an instance of ``KeyAttributesDataSource``.
struct TableView: UIViewRepresentable {
    var dataSource: TableViewDataSource
    var delegate: TableViewDelegate?
    var clickableRows = true

    let tableView = UITableView()

    func makeCoordinator() -> TableView.Coordinator {
        Coordinator(self, delegate: delegate)
    }

    func makeUIView(context _: Context) -> UITableView {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 60))
        tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "CellIdentifier")
        return tableView
    }

    func updateUIView(_ uiView: UITableView, context: Context) {
        //
        uiView.delegate = context.coordinator
        uiView.dataSource = context.coordinator

        if context.coordinator.updateData(newData: dataSource) {
            uiView.reloadData()
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITableViewDelegate, UITableViewDataSource {
        var parent: TableView

        var mydata: TableViewDataSource?
        var delegate: TableViewDelegate?

        var previousCount = 0

        init(_ parent: TableView, delegate: TableViewDelegate?) {
            self.delegate = delegate
            self.parent = parent
        }

        // This function determines if the table should refresh. It keeps track of the count of items and
        // returns true if the new data has a different count. Ideally, you'd compare the count but also
        // compare the items. This is crucial to avoid redrawing the screen whenever it scrolls.
        func updateData(newData: TableViewDataSource) -> Bool {
            if newData.count() != previousCount {
                mydata = newData
                previousCount = newData.count()
                return true
            }
            return false
        }

        func numberOfSections(in _: UITableView) -> Int {
            1
        }

        func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
            mydata?.count() ?? 0
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            // swiftlint:disable:next force_cast
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath) as! TableViewCell

            if let dataSource = mydata {
                cell.heading.text = dataSource.titleForRow(row: indexPath.row)
                cell.subheading.text = dataSource.subtitleForRow(row: indexPath.row)
                if parent.clickableRows {
                    cell.accessoryType = .disclosureIndicator
                }
                delegate?.onAppear(parent, at: indexPath.row)
            }
            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            delegate?.onTapped(parent, at: indexPath.row)
        }

        func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            delegate?.heightForRow(parent, at: indexPath.row) ?? 56.0
        }

        func scrollViewWillBeginDragging(_: UIScrollView) {
            delegate?.onScroll(parent, isScrolling: true)
        }

        func scrollViewWillEndDragging(_: UIScrollView, withVelocity _: CGPoint, targetContentOffset _: UnsafeMutablePointer<CGPoint>) {
            delegate?.onScroll(parent, isScrolling: false)
        }
    }
}
