// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  CVTableViewController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/04/2020 - for the TousAntiCovid project.
//

import UIKit

class CVTableViewController: UITableViewController {

    var rows: [CVRow] = []
    private var cellHeights: [IndexPath: CGFloat] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = Appearance.Controller.backgroundColor
    }
    
    func createRows() -> [CVRow] { [] }
    
    func reloadUI(animated: Bool = false, completion: (() -> ())? = nil) {
        rows = createRows()
        registerXibs()
        if #available(iOS 13.0, *) {
            if animated {
                UIView.transition(with: tableView, duration: 0.2, options: [.transitionCrossDissolve], animations: {
                    self.tableView.reloadData()
                }) { _ in
                    completion?()
                }
            } else {
                tableView.reloadData()
                completion?()
            }
        } else {
            tableView.reloadData()
            completion?()
        }
    }
    
    func rowObject(at indexPath: IndexPath) -> CVRow {
        rows[indexPath.row]
    }
    
    private func registerXibs() {
        var xibNames: Set<String> = Set<String>()
        rows.forEach { xibNames.insert($0.xibName.rawValue) }
        xibNames.forEach{ tableView.register(UINib(nibName: $0, bundle: nil), forCellReuseIdentifier: $0) }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row: CVRow = rowObject(at: indexPath)
        let identifier: String = row.xibName.rawValue
        let cell: CVTableViewCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! CVTableViewCell
        cell.setup(with: row)
        cell.layoutSubviews()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
        guard let cell = cell as? CVTableViewCell else { return }
        let row: CVRow = rowObject(at: indexPath)
        row.willDisplay?(cell)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row: CVRow = rowObject(at: indexPath)
        row.selectionAction?()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        cellHeights[indexPath] ?? UITableView.automaticDimension
    }
    
}
