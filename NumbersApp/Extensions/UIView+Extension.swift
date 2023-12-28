//
//  UIView+Extension.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 28/12/23.
//

import UIKit

extension UIView {
    func addSubview(_ subview: UIView, with insets: UIEdgeInsets) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            subview.leftAnchor.constraint(equalTo: leftAnchor, constant: insets.left),
            subview.rightAnchor.constraint(equalTo: rightAnchor, constant: -insets.right),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }
}
