//
//  AudioCell.swift
//  StopCovid
//
//  Created by Nicolas on 12/06/2020.
//  Copyright © 2020 Lunabee Studio. All rights reserved.
//

import UIKit

final class AudioCell: CVTableViewCell {

    @IBOutlet var button: UIButton!
    
    override func setup(with row: CVRow) {
        super.setup(with: row)
        button.setImage(row.image, for: .normal)
        button.tintColor = Asset.Colors.tint.color
        accessoryType = .none
        selectionStyle = .none
    }
    
    @IBAction func didTouchButton(_ sender: Any) {
        currentAssociatedRow?.selectionAction?()
    }
    
}
