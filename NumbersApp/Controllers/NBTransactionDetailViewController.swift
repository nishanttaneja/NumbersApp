//
//  NBTransactionDetailViewController.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 28/12/23.
//

import UIKit

final class NBTransactionDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NBTextFieldTableViewCellDelegate {
    // MARK: Properties
    private let textFieldCellReuseIdentifier = "textFieldCell-NBTransactionDetailViewController"
    private let buttonHeaderFooterViewReuseIdentifier = "buttonView-NBTransactionDetailViewController"
    private let fields = NBTransaction.NBTransactionField.allCases
    private let categories = NBTransaction.NBTransactionCategory.allCases
    private let expenseTypes = NBTransaction.NBTransactionExpenseType.allCases
    private let paymentMethods = NBTransaction.NBTransactionPaymentMethod.allCases
    private var tempTransaction: NBTransaction.NBTempTransaction?
    private var transaction: NBTransaction?
    private var allowSave: Bool {
        tempTransaction?.date != nil && tempTransaction?.title?.replacingOccurrences(of: " ", with: "").isEmpty == false && tempTransaction?.category != nil && tempTransaction?.expenseType != nil && tempTransaction?.paymentMethod != nil && tempTransaction?.amount != nil && hasChanges
    }
    private var hasChanges: Bool {
        guard let transaction else { return true }
        return transaction.date.startOfDay != tempTransaction?.date?.startOfDay || transaction.title != tempTransaction?.title || transaction.category != tempTransaction?.category || transaction.expenseType != tempTransaction?.expenseType || transaction.paymentMethod != tempTransaction?.paymentMethod || transaction.amount != tempTransaction?.amount
    }
    private let saveButtonInsets = UIEdgeInsets(top: .zero, left: 16, bottom: 8, right: 16)
    private let insetsForTransactionFieldsView = UIEdgeInsets(top: .zero, left: .zero, bottom: 8, right: .zero)
    
    // MARK: Views
    private let transactionFieldsView = UITableView(frame: .zero, style: .plain)
    private let saveTransactionButton = UIButton()
    private var deleteTransactionBarButtonItem: UIBarButtonItem?
    
    private func toggleSaveTransactionButtonIfNeeded() {
        saveTransactionButton.isEnabled = allowSave
        saveTransactionButton.backgroundColor = allowSave ? .systemBlue : .systemGray
    }
    @objc private func handleTouchUpInsideEvent(forSaveTransaction button: UIButton) {
        guard let transaction = tempTransaction?.getTransaction() else {
            let alertController = UIAlertController(title: "Unable to save", message: "Please provide more information to save.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
            present(alertController, animated: true)
            return
        }
        NBCDManager.shared.saveTransaction(transaction) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    guard success else { return }
                    NBNCManager.shared.postNotification(name: .NBCDManagerDidUpdateTransaction)
                    self?.dismiss(animated: true)
                case .failure(let failure):
                    let alertController = UIAlertController(title: "Unable to save", message: failure.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
    
    // MARK: Configurations
    private func configTableView() {
        transactionFieldsView.dataSource = self
        transactionFieldsView.delegate = self
        transactionFieldsView.register(NBTextFieldTableViewCell.self, forCellReuseIdentifier: textFieldCellReuseIdentifier)
        transactionFieldsView.rowHeight = 44
        transactionFieldsView.keyboardDismissMode = .onDrag
    }
    private func configSaveTransactionButton() {
        saveTransactionButton.setTitle("Save Transaction", for: .normal)
        toggleSaveTransactionButtonIfNeeded()
        saveTransactionButton.layer.cornerRadius = 8
        saveTransactionButton.addTarget(self, action: #selector(handleTouchUpInsideEvent(forSaveTransaction:)), for: .touchUpInside)
    }
    private func configViews() {
        view.backgroundColor = transactionFieldsView.backgroundColor
        configTableView()
        configSaveTransactionButton()
        transactionFieldsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transactionFieldsView)
        saveTransactionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveTransactionButton)
        NSLayoutConstraint.activate([
            // Table View
            transactionFieldsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: insetsForTransactionFieldsView.top),
            transactionFieldsView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: insetsForTransactionFieldsView.left),
            transactionFieldsView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -insetsForTransactionFieldsView.right),
            // Save Transaction Button
            saveTransactionButton.topAnchor.constraint(equalTo: transactionFieldsView.bottomAnchor, constant: insetsForTransactionFieldsView.bottom),
            saveTransactionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -saveButtonInsets.bottom),
            saveTransactionButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: saveButtonInsets.left),
            saveTransactionButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -saveButtonInsets.right),
            saveTransactionButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Transaction Detail"
        addNewTransaction()
        configViews()
        configNavigationItem()
    }
    private func configNavigationItem() {
        deleteTransactionBarButtonItem = UIBarButtonItem(systemItem: .trash, primaryAction: UIAction(handler: { [weak self] _ in
            guard let transactionID = self?.transaction?.id else { return }
            NBCDManager.shared.deleteTransaction(having: transactionID) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let success):
                        guard success else { return }
                        let alertController = UIAlertController(title: "Transaction Deleted Successfully.", message: nil, preferredStyle: .alert)
                        self?.present(alertController, animated: true, completion: {
                            DispatchQueue.main.asyncAfter(deadline: .now()+0.4) {
                                NBNCManager.shared.postNotification(name: .NBCDManagerDidUpdateTransaction)
                                alertController.dismiss(animated: true) {
                                    self?.dismiss(animated: true)
                                }
                            }
                        })
                    case .failure(let failure):
                        let alertController = UIAlertController(title: "Unable to delete transaction", message: failure.localizedDescription, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                        self?.present(alertController, animated: true)
                    }
                }
            }
        }))
        deleteTransactionBarButtonItem?.tintColor = .systemRed
    }
    
    // MARK: TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fields.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textFieldCellReuseIdentifier, for: indexPath)
        guard let textFieldCell = cell as? NBTextFieldTableViewCell, fields.count > indexPath.row else { return cell }
        let transactionField = fields[indexPath.row]
        textFieldCell.setPlaceholder(transactionField.title)
        textFieldCell.delegate = self
        switch transactionField {
        case .date:
            textFieldCell.isDatePicker = true
            textFieldCell.set(date: tempTransaction?.date)
        case .title:
            textFieldCell.setKeyboardType(.asciiCapable)
            textFieldCell.set(title: tempTransaction?.title)
        case .category:
            textFieldCell.setPickerValues(categories.compactMap({ $0.title }))
            if let category = tempTransaction?.category {
                textFieldCell.set(valueIndex: categories.firstIndex(of: category))
            }
        case .expenseType:
            textFieldCell.setPickerValues(expenseTypes.compactMap({ $0.title }))
            if let expenseType = tempTransaction?.expenseType {
                textFieldCell.set(valueIndex: expenseTypes.firstIndex(of: expenseType))
            }
        case .paymentMethod:
            textFieldCell.setPickerValues(paymentMethods.compactMap({ $0.title }))
            if let paymentMethod = tempTransaction?.paymentMethod {
                textFieldCell.set(valueIndex: paymentMethods.firstIndex(of: paymentMethod))
            }
        case .amount:
            textFieldCell.setKeyboardType(.decimalPad)
            textFieldCell.set(amount: tempTransaction?.amount)
        }
        return textFieldCell
    }
    
    // MARK: CellDelegate
    func textField(tableViewCell: NBTextFieldTableViewCell, didUpdateValueTo newValue: Any, usingPickerOptionAt index: Int?) {
        guard let row = transactionFieldsView.indexPath(for: tableViewCell)?.row, row < fields.count else { return }
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
        toggleSaveTransactionButtonIfNeeded()
    }
}

extension NBTransactionDetailViewController {
    func addNewTransaction() {
        tempTransaction = NBTransaction.NBTempTransaction()
        navigationItem.setLeftBarButton(nil, animated: true)
        transactionFieldsView.reloadData()
    }
    func loadTransaction(having id: UUID) {
        NBCDManager.shared.loadTransaction(having: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transaction):
                    self?.transaction = transaction
                    self?.tempTransaction = .init(transaction: transaction)
                    self?.navigationItem.setLeftBarButton(self?.deleteTransactionBarButtonItem, animated: true)
                    self?.transactionFieldsView.reloadData()
                case .failure(let failure):
                    let alertController = UIAlertController(title: "Unable to load transaction", message: failure.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                    self?.present(alertController, animated: true)
                }
            }
        }
    }

}
