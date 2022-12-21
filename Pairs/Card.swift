//
//  Card.swift
//  Pairs
//
//  Created by Huy Bui on 2022-12-20.
//

import UIKit

class Card: UIButton {

    var row: Int!, col: Int!
    
    convenience init(row: Int, col: Int) {
        self.init()
        self.row = row
        self.col = col
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
