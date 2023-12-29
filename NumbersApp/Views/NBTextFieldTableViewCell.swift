//
//  NBTextFieldTableViewCell.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 28/12/23.
//

import UIKit

protocol NBTextFieldTableViewCellDelegate: NSObjectProtocol {
    func textField(tableViewCell: NBTextFieldTableViewCell, didUpdateValueTo newValue: Any, usingPickerOptionAt index: Int?)
}

final class NBTextFieldTableViewCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {
    // MARK: Properties
    private let textFieldInsets = UIEdgeInsets(top: .zero, left: 16, bottom: .zero, right: 16)
    private let textField = UITextField()
    weak var delegate: NBTextFieldTableViewCellDelegate?
    private var values: [String] = []
    var isDatePicker: Bool = false {
        didSet {
            configDatePicker()
        }
    }
    
    // MARK: Views
    private let pickerView = UIPickerView()
    private let datePicker = UIDatePicker()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isDatePicker = false
        textField.text = nil
        textField.inputView = nil
        textField.keyboardType = .asciiCapable
        textField.placeholder = nil
        delegate = nil
        values.removeAll()
        datePicker.date = .now
    }
    
    // MARK: PickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        values.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard values.count > row else { return nil }
        return values[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard values.count > row else { return }
        let text = values[row]
        textField.text = text
        delegate?.textField(tableViewCell: self, didUpdateValueTo: text, usingPickerOptionAt: row)
    }
    
    // MARK: Configurations
    private func configViews() {
        values = []
        textField.inputView = nil
        textField.addAction(UIAction(handler: { _ in
            if self.textField.keyboardType == .decimalPad, let text = self.textField.text, let amount = Double(text) {
                self.delegate?.textField(tableViewCell: self, didUpdateValueTo: amount, usingPickerOptionAt: nil)
            } else {
                self.delegate?.textField(tableViewCell: self, didUpdateValueTo: self.textField.text as Any, usingPickerOptionAt: nil)
            }
        }), for: .editingChanged)
        contentView.addSubview(textField, with: textFieldInsets)
        pickerView.dataSource = self
        pickerView.delegate = self
        datePicker.date = .now
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.addAction(UIAction(handler: { _ in
            let date = self.datePicker.date
            self.textField.text = date.formatted(date: .abbreviated, time: .omitted)
            self.delegate?.textField(tableViewCell: self, didUpdateValueTo: date, usingPickerOptionAt: nil)
        }), for: .valueChanged)
    }
    private func configDatePicker() {
        textField.inputView = isDatePicker ? datePicker : nil
    }
    
    // MARK: Constructors
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configViews()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

extension NBTextFieldTableViewCell {
    func setPlaceholder(_ text: String?) {
        textField.placeholder = text
    }
}

extension NBTextFieldTableViewCell {
    func setKeyboardType(_ keyboardType: UIKeyboardType) {
        textField.keyboardType = keyboardType
    }
    func setPickerValues(_ values: [String]) {
        self.values = values
        textField.inputView = pickerView
    }
}
