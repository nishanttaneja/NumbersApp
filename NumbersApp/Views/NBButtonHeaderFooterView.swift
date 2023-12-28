//
//  NBButtonHeaderFooterView.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 29/12/23.
//

import UIKit

protocol NBButtonHeaderFooterViewDataSource: NSObjectProtocol {
    func titleForButtonView(_ headerFooterView: NBButtonHeaderFooterView) -> String
}
protocol NBButtonHeaderFooterViewDelegate: NSObjectProtocol {
    func didSelectButtonView(_ headerFooterView: NBButtonHeaderFooterView)
}

final class NBButtonHeaderFooterView: UITableViewHeaderFooterView {
    // MARK: Properties
    private let buttonInsets = UIEdgeInsets(top: 32, left: 16, bottom: 4, right: 16)
    weak var dataSource: NBButtonHeaderFooterViewDataSource? {
        didSet {
            button.setTitle(dataSource?.titleForButtonView(self), for: .normal)
        }
    }
    weak var delegate: NBButtonHeaderFooterViewDelegate?
    
    // MARK: Views
    private let button = UIButton()
    
    // MARK: Configurations
    private func configViews() {
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.addAction(UIAction(handler: { _ in
            self.delegate?.didSelectButtonView(self)
        }), for: .touchUpInside)
        contentView.addSubview(button, with: buttonInsets)
    }
    
    // MARK: Constructors
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configViews()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
