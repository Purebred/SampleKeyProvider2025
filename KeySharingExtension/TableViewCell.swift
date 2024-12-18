//
//  TableViewCell.swift
//  CustomTableView
//
//  Created by Peter Ent on 12/5/19.
//  Copyright © 2019 Peter Ent. All rights reserved.
//

import UIKit

/// ``TableViewCell`` defines cell contents for rows displayed via ``TableView``. The basic approach to displaying
/// table contents is adapted from <https://github.com/peterent/CustomTableView>.
class TableViewCell: UITableViewCell {
    @IBOutlet var heading: UILabel!
    @IBOutlet var subheading: UILabel!
}
