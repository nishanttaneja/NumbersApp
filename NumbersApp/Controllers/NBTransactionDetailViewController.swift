//
//  NBTransactionDetailViewController.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 28/12/23.
//

import UIKit

protocol NBTransactionDetailViewControllerDelegate: NSObjectProtocol {
    func didUpdateTransaction(in detailViewController: NBTransactionDetailViewController)
}

final class NBTransactionDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NBTextFieldTableViewCellDelegate {
    // MARK: Properties
    private let textFieldCellReuseIdentifier = "textFieldCell-NBTransactionDetailViewController"
    private let buttonHeaderFooterViewReuseIdentifier = "buttonView-NBTransactionDetailViewController"
    private let fields = NBTransaction.NBTransactionField.allCases
    private let categories = NBTransaction.NBTransactionCategory.allCases
    private let expenseTypes = NBTransaction.NBTransactionExpenseType.allCases
    private var paymentMethods: [NBTransaction.NBTransactionPaymentMethod] = []
    private var tempTransaction: NBTransaction.NBTempTransaction?
    private var transaction: NBTransaction?
    private var allowSave: Bool {
        (tempTransaction?.date ?? tempTransaction?.defaultDate) != nil && tempTransaction?.title?.replacingOccurrences(of: " ", with: "").isEmpty == false && tempTransaction?.category != nil && tempTransaction?.expenseType != nil && tempTransaction?.paymentMethod != nil && tempTransaction?.amount != nil && tempTransaction?.transactionType != nil && hasChanges
    }
    private var hasChanges: Bool {
        guard let transaction else { return true }
        return transaction.date.startOfDay != tempTransaction?.date?.startOfDay ?? tempTransaction?.defaultDate.startOfDay || transaction.title != tempTransaction?.title || transaction.category != tempTransaction?.category || transaction.expenseType != tempTransaction?.expenseType || transaction.paymentMethod != tempTransaction?.paymentMethod || transaction.amount != tempTransaction?.amount || transaction.transactionType != tempTransaction?.transactionType
    }
    private let saveButtonInsets = UIEdgeInsets(top: .zero, left: 16, bottom: 8, right: 16)
    private let insetsForTransactionFieldsView = UIEdgeInsets(top: .zero, left: .zero, bottom: 8, right: .zero)
    private let allowedTransactionTypes = NBTransaction.NBTransactionType.allCases
    private var currentTransactionType: NBTransaction.NBTransactionType = .debit
    private let insetsForTransactionTypeSegmentedControl = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    weak var delegate: NBTransactionDetailViewControllerDelegate?
    
    // MARK: Views
    private let transactionTypeSegmentedControl = UISegmentedControl()
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
                    if let self {
                        self.delegate?.didUpdateTransaction(in: self)
                    }
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
    private func configTransactionTypeSegmentedControl() {
        allowedTransactionTypes.reversed().forEach { transactionType in
            transactionTypeSegmentedControl.insertSegment(action: UIAction(title: transactionType.title, handler: { _ in
                guard transactionType != self.currentTransactionType else { return }
                switch transactionType {
                case .debit:
                    self.currentTransactionType = .debit
                    self.tempTransaction?.transactionType = .debit
                case .credit:
                    self.currentTransactionType = .credit
                    self.tempTransaction?.transactionType = .credit
                }
                self.toggleSaveTransactionButtonIfNeeded()
                self.transactionFieldsView.reloadSections(.init(integer: .zero), with: .automatic)
            }), at: .zero, animated: true)
        }
        transactionTypeSegmentedControl.selectedSegmentIndex = 1
        tempTransaction?.transactionType = .debit
        
    }
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
        configTransactionTypeSegmentedControl()
        configTableView()
        configSaveTransactionButton()
        transactionTypeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transactionTypeSegmentedControl)
        transactionFieldsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transactionFieldsView)
        saveTransactionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveTransactionButton)
        NSLayoutConstraint.activate([
            // Transaction Type
            transactionTypeSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: insetsForTransactionTypeSegmentedControl.top),
            transactionTypeSegmentedControl.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: insetsForTransactionTypeSegmentedControl.left),
            transactionTypeSegmentedControl.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -insetsForTransactionTypeSegmentedControl.right),
            // Transaction Fields View
            transactionFieldsView.topAnchor.constraint(equalTo: transactionTypeSegmentedControl.bottomAnchor, constant: insetsForTransactionTypeSegmentedControl.bottom),
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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        transactionFieldsView.reloadSections(.init(integer: .zero), with: .automatic)
        loadPaymentMethods()
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
                                if let self {
                                    self.delegate?.didUpdateTransaction(in: self)
                                }
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
        textFieldCell.setPlaceholder(transactionField.getTitle(for: currentTransactionType))
        textFieldCell.delegate = self
        switch transactionField {
        case .date:
            textFieldCell.isDatePicker = true
            textFieldCell.set(date: tempTransaction?.date)
        case .title:
            textFieldCell.setKeyboardType(.default)
            textFieldCell.set(title: tempTransaction?.title)
        case .category:
            textFieldCell.setPickerValues(categories.compactMap({ (key: $0.rawValue, value: $0.title) }))
            if let category = tempTransaction?.category {
                textFieldCell.set(valueIndex: categories.firstIndex(of: category))
            }
        case .expenseType:
            textFieldCell.setPickerValues(expenseTypes.compactMap({ (key: $0.rawValue, value: $0.title) }))
            if let expenseType = tempTransaction?.expenseType {
                textFieldCell.set(valueIndex: expenseTypes.firstIndex(of: expenseType))
            }
        case .paymentMethod:
            textFieldCell.setPickerValues(paymentMethods.compactMap({ (key: $0.id.uuidString, value: $0.title) }))
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
            guard let newValue = newValue as? String else { return }
            let paymentMethod = paymentMethods.first(where: { $0.id.uuidString == newValue }) ?? NBTransaction.NBTransactionPaymentMethod(title: newValue)
            tempTransaction?.paymentMethod = paymentMethod
        case .amount:
            tempTransaction?.amount = newValue as? Double
        }
        toggleSaveTransactionButtonIfNeeded()
    }
}

extension NBTransactionDetailViewController {
    func addNewTransaction() {
        let newTransaction = NBTransaction.NBTempTransaction()
        tempTransaction = newTransaction
        navigationItem.setLeftBarButton(nil, animated: true)
        transactionTypeSegmentedControl.selectedSegmentIndex = allowedTransactionTypes.firstIndex(of: newTransaction.transactionType) ?? 1
        currentTransactionType = newTransaction.transactionType
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
                    self?.currentTransactionType = transaction.transactionType
                    self?.transactionTypeSegmentedControl.selectedSegmentIndex = self?.allowedTransactionTypes.firstIndex(of: transaction.transactionType) ?? 1
                    self?.toggleSaveTransactionButtonIfNeeded()
                    self?.transactionFieldsView.reloadData()
                case .failure(let failure):
                    let alertController = UIAlertController(title: "Unable to load transaction", message: failure.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
    private func loadPaymentMethods() {
        NBCDManager.shared.loadAllPaymentMethods { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedPaymentMethods):
                    self?.paymentMethods = savedPaymentMethods
                    guard let index = self?.fields.firstIndex(of: .paymentMethod) else { return }
                    self?.transactionFieldsView.reloadRows(at: [IndexPath(row: index, section: .zero)], with: .automatic)
                case .failure(let failure):
                    let alertController = UIAlertController(title: "Unable to load payment methods", message: failure.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
}
