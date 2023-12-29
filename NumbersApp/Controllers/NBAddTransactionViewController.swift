//
//  NBAddTransactionViewController.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 28/12/23.
//

import UIKit

final class NBAddTransactionViewController: UITableViewController, NBTextFieldTableViewCellDelegate, NBButtonHeaderFooterViewDataSource, NBButtonHeaderFooterViewDelegate {
    // MARK: Properties
    private let textFieldCellReuseIdentifier = "textFieldCell-NBAddTransactionViewController"
    private let buttonHeaderFooterViewReuseIdentifier = "buttonView-NBAddTransactionViewController"
    private let fields = NBTransaction.NBTransactionField.allCases
    private let categories = NBTransaction.NBTransactionCategory.allCases
    private let expenseTypes = NBTransaction.NBTransactionExpenseType.allCases
    private let paymentMethods = NBTransaction.NBTransactionPaymentMethod.allCases
    private var tempTransaction: NBTransaction.NBTempTransaction?
    
    func addNewTransaction() {
        tempTransaction = NBTransaction.NBTempTransaction()
        tableView.reloadData()
    }
    func addNewTransactionIfNeeded() {
        guard tempTransaction == nil else { return }
        tempTransaction = NBTransaction.NBTempTransaction()
    }
    
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(NBTextFieldTableViewCell.self, forCellReuseIdentifier: textFieldCellReuseIdentifier)
        tableView.register(NBButtonHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: buttonHeaderFooterViewReuseIdentifier)
        tableView.rowHeight = 44
        tableView.sectionFooterHeight = 80
        tableView.keyboardDismissMode = .onDrag
        addNewTransactionIfNeeded()
    }
    
    // MARK: TableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fields.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textFieldCellReuseIdentifier, for: indexPath)
        guard let textFieldCell = cell as? NBTextFieldTableViewCell, fields.count > indexPath.row else { return cell }
        let transactionField = fields[indexPath.row]
        switch transactionField {
        case .date:
            textFieldCell.isDatePicker = true
        case .title:
            textFieldCell.setKeyboardType(.asciiCapable)
        case .category:
            textFieldCell.setPickerValues(categories.compactMap({ $0.title }))
        case .expenseType:
            textFieldCell.setPickerValues(expenseTypes.compactMap({ $0.title }))
        case .paymentMethod:
            textFieldCell.setPickerValues(paymentMethods.compactMap({ $0.title }))
        case .amount:
            textFieldCell.setKeyboardType(.decimalPad)
        }
        textFieldCell.setPlaceholder(transactionField.title)
        textFieldCell.delegate = self
        return textFieldCell
    }
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: buttonHeaderFooterViewReuseIdentifier)
        guard let buttonView = footerView as? NBButtonHeaderFooterView else { return footerView }
        buttonView.dataSource = self
        buttonView.delegate = self
        return buttonView
    }
    
    
    // MARK: CellDelegate
    func textField(tableViewCell: UITableViewCell, didUpdateValueTo newValue: Any, usingPickerOptionAt index: Int?) {
        guard let row = tableView.indexPath(for: tableViewCell)?.row, row < fields.count else { return }
        let field = fields[row]
        switch field {
        case .date:
            tempTransaction?.date = newValue as? Date
        case .title:
            tempTransaction?.title = newValue as? String
        case .category:
            guard let index, index < categories.count else { return }
            let category = categories[index]
            tempTransaction?.category = category
        case .expenseType:
            guard let index, index < expenseTypes.count else { return }
            let expenseType = expenseTypes[index]
            tempTransaction?.expenseType = expenseType
        case .paymentMethod:
            guard let index, index < paymentMethods.count else { return }
            let paymentMethod = paymentMethods[index]
            tempTransaction?.paymentMethod = paymentMethod
        case .amount:
            tempTransaction?.amount = newValue as? Double
        }
    }
    
    // MARK: FooterDataSource
    func titleForButtonView(_ headerFooterView: NBButtonHeaderFooterView) -> String {
        "Add Transaction"
    }
    // MARK: FooterDelegate
    func didSelectButtonView(_ headerFooterView: NBButtonHeaderFooterView) {
        guard let transaction = tempTransaction?.getTransaction() else {
            let alertController = UIAlertController(title: "Unable to save", message: "Please provide more information to save.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
            present(alertController, animated: true)
            return
        }
        NBCDManager.shared.saveTransaction(transaction) { [weak self] result in
            switch result {
            case .success(let success):
                guard success else { return }
                NBNCManager.shared.postNotification(name: .NBCDManagerDidSaveNewTransaction)
            case .failure(let failure):
                let alertController = UIAlertController(title: "Unable to save", message: failure.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                self?.present(alertController, animated: true)
            }
        }
        dismiss(animated: true)
    }
    
    deinit {
        debugPrint(#function, self)
    }
}
