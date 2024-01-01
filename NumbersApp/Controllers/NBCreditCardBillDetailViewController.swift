//
//  NBCreditCardBillDetailViewController.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 31/12/23.
//

import UIKit

protocol NBCreditCardBillDetailViewControllerDelegate: NSObjectProtocol {
    func didUpdateCreditCardBill(in detailViewController: NBCreditCardBillDetailViewController)
}

final class NBCreditCardBillDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NBTextFieldTableViewCellDelegate {
    // MARK: Properties
    private let textFieldCellReuseIdentifier = "textFieldCell-NBCreditCardBillDetailViewController"
    private let buttonHeaderFooterViewReuseIdentifier = "buttonView-NBCreditCardBillDetailViewController"
    private let fields = NBCreditCardBill.NBCreditCardBillField.allCases
//    private let categories = NBTransaction.NBTransactionCategory.allCases
//    private let expenseTypes = NBTransaction.NBTransactionExpenseType.allCases
    private var paymentMethods: [NBTransaction.NBTransactionPaymentMethod] = []
    private var tempCreditCardBill: NBCreditCardBill.NBTempCreditCardBill?
    private var creditCardBill: NBCreditCardBill?
    private var allowSave: Bool {
        tempCreditCardBill?.startDate != nil && tempCreditCardBill?.endDate != nil && tempCreditCardBill?.dueDate != nil && tempCreditCardBill?.title?.replacingOccurrences(of: " ", with: "").isEmpty == false && tempCreditCardBill?.amount != nil && hasChanges
    }
    private var hasChanges: Bool {
        guard let creditCardBill else { return true }
        return creditCardBill.startDate.startOfDay != tempCreditCardBill?.startDate?.startOfDay || creditCardBill.endDate.startOfDay != tempCreditCardBill?.endDate?.startOfDay || creditCardBill.dueDate.startOfDay != tempCreditCardBill?.dueDate?.startOfDay || creditCardBill.title != tempCreditCardBill?.title || creditCardBill.amount != tempCreditCardBill?.amount || creditCardBill.paymentStatus != tempCreditCardBill?.paymentStatus
    }
    private let saveButtonInsets = UIEdgeInsets(top: .zero, left: 16, bottom: 8, right: 16)
    private let insetsForCreditCardBillFieldsView = UIEdgeInsets(top: .zero, left: .zero, bottom: 8, right: .zero)
    private let allowedPaymentStatus = NBCreditCardBill.NBCreditCardBillPaymentStatus.allCases
    private var currentPaymentStatus: NBCreditCardBill.NBCreditCardBillPaymentStatus = .due
    private let insetsForPaymentStatusSegmentedControl = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    weak var delegate: NBCreditCardBillDetailViewControllerDelegate?
    
    // MARK: Views
    private let paymentStatusSegmentedControl = UISegmentedControl()
    private let creditCardBillFieldsView = UITableView(frame: .zero, style: .plain)
    private let saveCreditCardBillButton = UIButton()
    private var deleteCreditCardBillBarButtonItem: UIBarButtonItem?
    
    private func toggleSaveCreditCardBillButtonIfNeeded() {
        saveCreditCardBillButton.isEnabled = allowSave
        saveCreditCardBillButton.backgroundColor = allowSave ? .systemBlue : .systemGray
    }
    @objc private func handleTouchUpInsideEvent(forSaveTransaction button: UIButton) {
        guard let creditCardBill = tempCreditCardBill?.getCreditCardBill() else {
            let alertController = UIAlertController(title: "Unable to save", message: "Please provide more information to save.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
            present(alertController, animated: true)
            return
        }
        NBCDManager.shared.saveCreditCardBill(creditCardBill) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    guard success else { return }
                    if let self {
                        self.delegate?.didUpdateCreditCardBill(in: self)
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
    private func configPaymentStatusSegmentedControl() {
        allowedPaymentStatus.reversed().forEach { paymentStatus in
            paymentStatusSegmentedControl.insertSegment(action: UIAction(title: paymentStatus.title, handler: { _ in
                guard paymentStatus != self.currentPaymentStatus else { return }
                self.currentPaymentStatus = paymentStatus
                self.tempCreditCardBill?.paymentStatus = paymentStatus
                self.toggleSaveCreditCardBillButtonIfNeeded()
                self.creditCardBillFieldsView.reloadSections(.init(integer: .zero), with: .automatic)
            }), at: .zero, animated: true)
        }
        paymentStatusSegmentedControl.selectedSegmentIndex = 1
        tempCreditCardBill?.paymentStatus = .due
        
    }
    private func configTableView() {
        creditCardBillFieldsView.dataSource = self
        creditCardBillFieldsView.delegate = self
        creditCardBillFieldsView.register(NBTextFieldTableViewCell.self, forCellReuseIdentifier: textFieldCellReuseIdentifier)
        creditCardBillFieldsView.rowHeight = 44
        creditCardBillFieldsView.keyboardDismissMode = .onDrag
    }
    private func configSaveTransactionButton() {
        saveCreditCardBillButton.setTitle("Save Bill", for: .normal)
        toggleSaveCreditCardBillButtonIfNeeded()
        saveCreditCardBillButton.layer.cornerRadius = 8
        saveCreditCardBillButton.addTarget(self, action: #selector(handleTouchUpInsideEvent(forSaveTransaction:)), for: .touchUpInside)
    }
    private func configViews() {
        view.backgroundColor = creditCardBillFieldsView.backgroundColor
        configPaymentStatusSegmentedControl()
        configTableView()
        configSaveTransactionButton()
        paymentStatusSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paymentStatusSegmentedControl)
        creditCardBillFieldsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(creditCardBillFieldsView)
        saveCreditCardBillButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveCreditCardBillButton)
        NSLayoutConstraint.activate([
            // Transaction Type
            paymentStatusSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: insetsForPaymentStatusSegmentedControl.top),
            paymentStatusSegmentedControl.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: insetsForPaymentStatusSegmentedControl.left),
            paymentStatusSegmentedControl.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -insetsForPaymentStatusSegmentedControl.right),
            // Transaction Fields View
            creditCardBillFieldsView.topAnchor.constraint(equalTo: paymentStatusSegmentedControl.bottomAnchor, constant: insetsForPaymentStatusSegmentedControl.bottom),
            creditCardBillFieldsView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: insetsForCreditCardBillFieldsView.left),
            creditCardBillFieldsView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -insetsForCreditCardBillFieldsView.right),
            // Save Transaction Button
            saveCreditCardBillButton.topAnchor.constraint(equalTo: creditCardBillFieldsView.bottomAnchor, constant: insetsForCreditCardBillFieldsView.bottom),
            saveCreditCardBillButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -saveButtonInsets.bottom),
            saveCreditCardBillButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: saveButtonInsets.left),
            saveCreditCardBillButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -saveButtonInsets.right),
            saveCreditCardBillButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Transaction Detail"
        addNewCreditCardBill()
        configViews()
        configNavigationItem()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        creditCardBillFieldsView.reloadSections(.init(integer: .zero), with: .automatic)
        loadPaymentMethods()
    }
    private func configNavigationItem() {
        deleteCreditCardBillBarButtonItem = UIBarButtonItem(systemItem: .trash, primaryAction: UIAction(handler: { [weak self] _ in
            guard let billId = self?.creditCardBill?.id else { return }
            NBCDManager.shared.deleteCreditCardBill(having: billId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let success):
                        guard success else { return }
                        let alertController = UIAlertController(title: "Credit Card Bill Deleted Successfully.", message: nil, preferredStyle: .alert)
                        self?.present(alertController, animated: true, completion: {
                            DispatchQueue.main.asyncAfter(deadline: .now()+0.4) {
                                if let self {
                                    self.delegate?.didUpdateCreditCardBill(in: self)
                                }
                                alertController.dismiss(animated: true) {
                                    self?.dismiss(animated: true)
                                }
                            }
                        })
                    case .failure(let failure):
                        let alertController = UIAlertController(title: "Unable to delete credit card bill", message: failure.localizedDescription, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                        self?.present(alertController, animated: true)
                    }
                }
            }
        }))
        deleteCreditCardBillBarButtonItem?.tintColor = .systemRed
    }
    
    // MARK: TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fields.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: textFieldCellReuseIdentifier, for: indexPath)
        guard let textFieldCell = cell as? NBTextFieldTableViewCell, fields.count > indexPath.row else { return cell }
        let creditCardBillField = fields[indexPath.row]
        textFieldCell.setPlaceholder(creditCardBillField.rawValue.capitalized)
        textFieldCell.delegate = self
        switch creditCardBillField {
        case .startDate:
            textFieldCell.isDatePicker = true
            textFieldCell.set(date: tempCreditCardBill?.startDate)
        case .endDate:
            textFieldCell.isDatePicker = true
            textFieldCell.set(date: tempCreditCardBill?.endDate)
        case .dueDate:
            textFieldCell.isDatePicker = true
            textFieldCell.set(date: tempCreditCardBill?.dueDate)
        case .title:
            textFieldCell.setPickerValues(paymentMethods.compactMap({ (key: $0.id.uuidString, value: $0.title) }))
            if let paymentMethod = tempCreditCardBill?.title {
                textFieldCell.set(valueIndex: paymentMethods.firstIndex(where: { $0.title == paymentMethod }))
            }
        case .amount:
            textFieldCell.setKeyboardType(.decimalPad)
            textFieldCell.set(amount: tempCreditCardBill?.amount)
        }
        return textFieldCell
    }
    
    // MARK: CellDelegate
    func textField(tableViewCell: NBTextFieldTableViewCell, didUpdateValueTo newValue: Any, usingPickerOptionAt index: Int?) {
        guard let row = creditCardBillFieldsView.indexPath(for: tableViewCell)?.row, row < fields.count else { return }
        let field = fields[row]
        switch field {
        case .startDate:
            tempCreditCardBill?.startDate = newValue as? Date
        case .endDate:
            tempCreditCardBill?.endDate = newValue as? Date
        case .dueDate:
            tempCreditCardBill?.dueDate = newValue as? Date
        case .title:
            guard let newValue = newValue as? String else { return }
            let paymentMethod = paymentMethods.first(where: { $0.id.uuidString == newValue }) ?? NBTransaction.NBTransactionPaymentMethod(title: newValue)
            tempCreditCardBill?.title = paymentMethod.title
            
        case .amount:
            tempCreditCardBill?.amount = newValue as? Double
        }
        toggleSaveCreditCardBillButtonIfNeeded()
    }
}

extension NBCreditCardBillDetailViewController {
    func addNewCreditCardBill() {
        let newCreditCardBill = NBCreditCardBill.NBTempCreditCardBill()
        tempCreditCardBill = newCreditCardBill
        navigationItem.setLeftBarButton(nil, animated: true)
        paymentStatusSegmentedControl.selectedSegmentIndex = allowedPaymentStatus.firstIndex(of: newCreditCardBill.paymentStatus) ?? 1
        currentPaymentStatus = newCreditCardBill.paymentStatus
        creditCardBillFieldsView.reloadData()
    }
    func loadCreditCardBill(having id: UUID) {
        NBCDManager.shared.loadCreditCardBill(having: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let creditCardBill):
                    self?.creditCardBill = creditCardBill
                    self?.tempCreditCardBill = .init(creditCardBill: creditCardBill)
                    self?.navigationItem.setLeftBarButton(self?.deleteCreditCardBillBarButtonItem, animated: true)
                    self?.currentPaymentStatus = creditCardBill.paymentStatus
                    self?.paymentStatusSegmentedControl.selectedSegmentIndex = self?.allowedPaymentStatus.firstIndex(of: creditCardBill.paymentStatus) ?? 1
                    self?.toggleSaveCreditCardBillButtonIfNeeded()
                    self?.creditCardBillFieldsView.reloadData()
                case .failure(let failure):
                    let alertController = UIAlertController(title: "Unable to load credit card bills", message: failure.localizedDescription, preferredStyle: .alert)
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
                    guard let index = self?.fields.firstIndex(of: .title) else { return }
                    self?.creditCardBillFieldsView.reloadRows(at: [IndexPath(row: index, section: .zero)], with: .automatic)
                case .failure(let failure):
                    let alertController = UIAlertController(title: "Unable to load payment methods", message: failure.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
}
