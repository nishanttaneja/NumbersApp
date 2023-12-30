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
    private var values: [(key: String, value: String)] = []
    var isDatePicker: Bool = false {
        didSet {
            configDatePicker()
        }
    }
    
    // MARK: Views
    private let pickerView = UIPickerView()
    private let datePicker = UIDatePicker()
    private let toolbar = UIToolbar()
    private let doneBarButtonItem = UIBarButtonItem(systemItem: .done)
    private let keyboardToggleBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "keyboard"))
    
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
        return values[row].value
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard values.count > row else { return }
        let value = values[row]
        textField.text = value.value
        delegate?.textField(tableViewCell: self, didUpdateValueTo: value.key, usingPickerOptionAt: row)
    }
    
    // MARK: Configurations
    private func configViews() {
        configToolbar()
        values = []
        textField.inputView = nil
        textField.addAction(UIAction(handler: { _ in
            if self.textField.keyboardType == .decimalPad, let text = self.textField.text, let amount = Double(text) {
                self.delegate?.textField(tableViewCell: self, didUpdateValueTo: amount, usingPickerOptionAt: nil)
            } else {
                if self.textField.text?.replacingOccurrences(of: " ", with: "").isEmpty == false,
                   let text = self.textField.text, let value = self.values.first(where: { $0.value == self.textField.text }) {
                    self.delegate?.textField(tableViewCell: self, didUpdateValueTo: value.key, usingPickerOptionAt: self.values.firstIndex(where: { $0.key == value.key } ))
                } else {
                    self.delegate?.textField(tableViewCell: self, didUpdateValueTo: self.textField.text as Any, usingPickerOptionAt: nil)
                }
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
    private func configToolbar() {
        doneBarButtonItem.primaryAction = UIAction(handler: { [weak self] _ in
            self?.endEditing(true)
        })
        toolbar.setItems([.flexibleSpace(), doneBarButtonItem], animated: true)
        toolbar.sizeToFit()
        textField.inputAccessoryView = toolbar
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
        toolbar.setItems([.flexibleSpace(), doneBarButtonItem], animated: true)
    }
    func setPickerValues(_ values: [(key: String, value: String)]) {
        self.values = values
        textField.inputView = pickerView
        keyboardToggleBarButtonItem.primaryAction = UIAction(handler: { [weak self] _ in
            if self?.textField.inputView == nil {
                self?.textField.inputView = self?.pickerView
                self?.keyboardToggleBarButtonItem.image = .init(systemName: "keyboard")
            } else {
                self?.textField.inputView = nil
                self?.keyboardToggleBarButtonItem.image = .init(systemName: "list.bullet.rectangle")
            }
            self?.textField.reloadInputViews()
        })
        toolbar.setItems([keyboardToggleBarButtonItem, .flexibleSpace(), doneBarButtonItem], animated: true)
    }
}

extension NBTextFieldTableViewCell {
    func set(date: Date? = nil, title: String? = nil, valueIndex: Int? = nil, amount: Double? = nil) {
        if let date {
            datePicker.date = date
            textField.text = date.formatted(date: .abbreviated, time: .omitted)
        } else if let amount {
            textField.text = String(amount)
        } else if values.isEmpty {
            textField.text = title
        } else if let valueIndex, values.count > valueIndex {
            pickerView.selectRow(valueIndex, inComponent: .zero, animated: true)
            pickerView.delegate?.pickerView?(pickerView, didSelectRow: valueIndex, inComponent: .zero)
        }
    }
}
