//
//  NBCreditCardBillsViewController.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 31/12/23.
//

import UIKit

final class NBCreditCardBillsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NBCreditCardBillDetailViewControllerDelegate {
    enum NBViewType: String, CaseIterable {
        case allBills = "All"
        case pendingBills = "Pending"
        case totalOutstandings = "Outstandings"
    }
    
    // MARK: Properties
    private var creditCardBills: [NBCreditCardBill] = []
    private var itemsToDisplaySeparatedByMonth: [(dueDate: Date, bills: [NBCreditCardBill])] = []
    private let defaultCellReuseIdentifier = "defaultCell-NBCreditCardBillsViewController"
    private let allowedViewTypes = NBViewType.allCases
    private var currentViewType: NBViewType = .pendingBills
    private let insetsForViewTypeSegmentedControl = UIEdgeInsets(top: 8, left: 16, bottom: 4, right: 16)
    private let insetsForTableView = UIEdgeInsets(top: 4, left: .zero, bottom: 4, right: .zero)
    
    // MARK: Views
    private var creditCardBillDetailViewController: NBCreditCardBillDetailViewController?
    private let documentPickerViewController = UIDocumentPickerViewController.init(forOpeningContentTypes: [.commaSeparatedText])
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let viewTypeSegmentedControl = UISegmentedControl()
    
    // MARK: ViewTypes
    private func setViewType(_ newViewType: NBViewType) {
        DispatchQueue.main.async { [weak self] in
            guard let creditCardBills = self?.creditCardBills else { return }
            self?.itemsToDisplaySeparatedByMonth.removeAll()
            switch newViewType {
            case .allBills, .pendingBills:
                for creditCardBill in creditCardBills {
                    if newViewType == .pendingBills && creditCardBill.paymentStatus == .paid { continue }
                    if let dueDateIndex = self?.itemsToDisplaySeparatedByMonth.firstIndex(where: { $0.dueDate == creditCardBill.dueDate }) {
                        self?.itemsToDisplaySeparatedByMonth[dueDateIndex].bills.append(creditCardBill)
                    } else {
                        self?.itemsToDisplaySeparatedByMonth.append((dueDate: creditCardBill.dueDate, bills: [creditCardBill]))
                    }
                }
                if newViewType == .pendingBills {
                    self?.itemsToDisplaySeparatedByMonth.reverse()
                }
            case .totalOutstandings:
                self?.itemsToDisplaySeparatedByMonth = [(.now, [])]
                var latestBills: [NBCreditCardBill] = []
//                let allPaymentMethodTitles: [String] =
                var remainingPaymentMethodTitles: [String] = []
                for creditCardBill in creditCardBills {
                    guard !latestBills.contains(where: { $0.title == creditCardBill.title }) else { continue }
                    if !remainingPaymentMethodTitles.contains(where: { creditCardBill.title == $0 }) {
                        remainingPaymentMethodTitles.append(creditCardBill.title)
                    }
                    NBCDManager.shared.loadAllTransactions(havingPaymentMethod: creditCardBill.title, startDate: creditCardBill.endDate) { result in
                        switch result {
                        case .success(let transactions):
                            guard !latestBills.contains(where: { $0.title == creditCardBill.title }) else { return }
                            let totalOutstandingsAmount: Double = transactions.reduce(creditCardBill.paymentStatus == .due ? creditCardBill.amount : .zero) { partialResult, nextTransaction in
                                partialResult + nextTransaction.amount
                            }
                            let outstandingBill = NBCreditCardBill(startDate: .now, endDate: .now, dueDate: .now, title: creditCardBill.title, amount: totalOutstandingsAmount)
                            latestBills.append(outstandingBill)
                            remainingPaymentMethodTitles.removeAll(where: { outstandingBill.title == $0 })
                            if remainingPaymentMethodTitles.isEmpty {
                                // Stop loading animation
                                self?.itemsToDisplaySeparatedByMonth[.zero].bills = latestBills.sorted(by: { $0.title.lowercased() <= $1.title.lowercased() })
                                DispatchQueue.main.async {
                                    self?.tableView.reloadData()
                                }
                            }
                        case .failure(let failure):
                            debugPrint(#function, creditCardBill.dueDate, creditCardBill.title, failure.localizedDescription)
                        }
                    }
                }
            }
            self?.tableView.reloadData()
            self?.currentViewType = newViewType
        }
        
    }
    private func configViewTypeSegmentedControl() {
        for (index, viewType) in allowedViewTypes.enumerated() {
            self.viewTypeSegmentedControl.insertSegment(action: UIAction(title: viewType.title, handler: { _ in
                self.setViewType(viewType)
            }), at: index, animated: true)
        }
        viewTypeSegmentedControl.selectedSegmentIndex = 1
    }
    
    // MARK: TableView
    private func configTableView() {
        tableView.register(NBTransactionDetailTableViewCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        itemsToDisplaySeparatedByMonth.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard itemsToDisplaySeparatedByMonth.count > section else { return .zero }
        return itemsToDisplaySeparatedByMonth[section].bills.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellReuseIdentifier, for: indexPath)
        guard let detailCell = cell as? NBTransactionDetailTableViewCell,
              itemsToDisplaySeparatedByMonth.count > indexPath.section,
              itemsToDisplaySeparatedByMonth[indexPath.section].bills.count > indexPath.row else { return cell }
        let bill = itemsToDisplaySeparatedByMonth[indexPath.section].bills[indexPath.row]
        detailCell.textLabel?.text = bill.title
        detailCell.detailTextLabel?.text = "\(bill.amount < .zero ? "+ " : "")₹" + String(format: "%.2f", abs(bill.amount))
        detailCell.detailTextLabel?.textColor = bill.paymentStatus == .paid ? .systemGray : .systemRed
        return detailCell
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard itemsToDisplaySeparatedByMonth.count > section else { return nil }
        return itemsToDisplaySeparatedByMonth[section].dueDate.formatted(date: .complete, time: .omitted)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section < itemsToDisplaySeparatedByMonth.count, indexPath.row < itemsToDisplaySeparatedByMonth[indexPath.section].bills.count else { return }
        let transaction = itemsToDisplaySeparatedByMonth[indexPath.section].bills[indexPath.row]
        if creditCardBillDetailViewController == nil {
            creditCardBillDetailViewController = NBCreditCardBillDetailViewController()
            creditCardBillDetailViewController?.delegate = self
        }
        creditCardBillDetailViewController?.loadCreditCardBill(having: transaction.id)
        guard let creditCardBillDetailViewController else { return }
        present(UINavigationController(rootViewController: creditCardBillDetailViewController), animated: true)
    }
    
    // MARK: CreditCardBillDetail Delegate
    func didUpdateCreditCardBill(in detailViewController: NBCreditCardBillDetailViewController) {
        loadCreditCardBills()
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Credit Card Bills"
        tabBarItem = .init(title: title, image: .init(systemName: "creditcard.trianglebadge.exclamationmark"), tag: 1)
        configViews()
        loadCreditCardBills()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configNavigationBar()
    }
    
    // MARK: Configurations
    private func configNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.setRightBarButtonItems([
            UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { _ in
                if self.creditCardBillDetailViewController == nil {
                    self.creditCardBillDetailViewController = NBCreditCardBillDetailViewController()
                    self.creditCardBillDetailViewController?.delegate = self
                } else {
                    self.creditCardBillDetailViewController?.addNewCreditCardBill()
                }
                guard let creditCardBillDetailViewController = self.creditCardBillDetailViewController else { return }
                self.present(UINavigationController(rootViewController: creditCardBillDetailViewController), animated: true)
            })),
            UIBarButtonItem(title: "Import", primaryAction: UIAction(handler: { [weak self] _ in
                guard let documentPickerViewController = self?.documentPickerViewController else { return }
                self?.present(documentPickerViewController, animated: true)
            }))
        ], animated: true)
    }
    private func configViews() {
        view.backgroundColor = tableView.backgroundColor
        configViewTypeSegmentedControl()
        configTableView()
        configConstraints()
        configDocumentPickerViewController()
    }
    private func configConstraints() {
        viewTypeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewTypeSegmentedControl)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            // View Type
            viewTypeSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: insetsForViewTypeSegmentedControl.top),
            viewTypeSegmentedControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: insetsForViewTypeSegmentedControl.left),
            viewTypeSegmentedControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -insetsForViewTypeSegmentedControl.right),
            // Table View
            tableView.topAnchor.constraint(equalTo: viewTypeSegmentedControl.bottomAnchor, constant: insetsForTableView.top+insetsForViewTypeSegmentedControl.bottom),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: insetsForTableView.left),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -insetsForTableView.right),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -insetsForTableView.bottom),
        ])
    }
    private func updateCreditCardBills(to newCreditCardBills: [NBCreditCardBill]) {
        creditCardBills = newCreditCardBills
        setViewType(currentViewType)
    }
    private func loadCreditCardBills() {
        NBCDManager.shared.loadAllCreditCardBills { [weak self] result in
            switch result {
            case .success(let creditCardBills):
                self?.updateCreditCardBills(to: creditCardBills)
            case .failure(let failure):
                let alertController = UIAlertController(title: "Unable to load credit card bills", message: failure.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                self?.present(alertController, animated: true)
            }
        }
    }
}


// MARK: - Import Bills
extension NBCreditCardBillsViewController: UIDocumentPickerDelegate {
    private func configDocumentPickerViewController() {
        documentPickerViewController.delegate = self
    }
    
    // MARK: Delegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileUrl = urls.first else { return }
        let alertController = UIAlertController(title: nil, message: "Importing credit card bills...", preferredStyle: .alert)
        present(alertController, animated: true)
        NBCDManager.shared.importCreditCardBills(from: fileUrl) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    defer {
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.4) {
                            alertController.dismiss(animated: true)
                        }
                    }
                    alertController.message = "Found 0 credit card bills for import."
                    guard success else { return }
                    alertController.message = "Imported all credit card bills successfully."
                    self?.loadCreditCardBills()
                case .failure(let failure):
                    alertController.title = "Unable to import credit card bills"
                    alertController.message = failure.localizedDescription
                    alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
}


// MARK: - ViewTypes
extension NBCreditCardBillsViewController.NBViewType {
    var title: String {
        rawValue.capitalized
    }
}
