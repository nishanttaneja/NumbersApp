//
//  NBCreditCardBillsViewController.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 31/12/23.
//

import UIKit

final class NBCreditCardBillsViewController: UITableViewController, NBCreditCardBillDetailViewControllerDelegate {
    // MARK: Properties
    private var creditCardBills: [NBCreditCardBill] = []
    private var creditCardBillsSepartedByMonth: [(dueDate: Date, bills: [NBCreditCardBill])] = []
    private let defaultCellReuseIdentifier = "defaultCell-NBCreditCardBillsViewController"
    
    // MARK: Views
    private var creditCardBillDetailViewController: NBCreditCardBillDetailViewController?
    private let documentPickerViewController = UIDocumentPickerViewController.init(forOpeningContentTypes: [.commaSeparatedText])
    
    // MARK: TableView
    override func numberOfSections(in tableView: UITableView) -> Int {
        creditCardBillsSepartedByMonth.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard creditCardBillsSepartedByMonth.count > section else { return .zero }
        return creditCardBillsSepartedByMonth[section].bills.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellReuseIdentifier, for: indexPath)
        guard let detailCell = cell as? NBTransactionDetailTableViewCell,
              creditCardBillsSepartedByMonth.count > indexPath.section,
              creditCardBillsSepartedByMonth[indexPath.section].bills.count > indexPath.row else { return cell }
        let bill = creditCardBillsSepartedByMonth[indexPath.section].bills[indexPath.row]
        detailCell.textLabel?.text = bill.title
        detailCell.detailTextLabel?.text = "\(bill.amount < .zero ? "+ " : "")₹" + String(format: "%.2f", abs(bill.amount))
        detailCell.detailTextLabel?.textColor = bill.paymentStatus == .paid ? .systemGray : .systemRed
        return detailCell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard creditCardBillsSepartedByMonth.count > section else { return nil }
        return creditCardBillsSepartedByMonth[section].dueDate.formatted(date: .complete, time: .omitted)
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section < creditCardBillsSepartedByMonth.count, indexPath.row < creditCardBillsSepartedByMonth[indexPath.section].bills.count else { return }
        let transaction = creditCardBillsSepartedByMonth[indexPath.section].bills[indexPath.row]
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
        tableView.register(NBTransactionDetailTableViewCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
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
        loadCreditCardBills()
        configDocumentPickerViewController()
    }
    
    // MARK: Configurations
    private func updateCreditCardBills(to newCreditCardBills: [NBCreditCardBill]) {
        DispatchQueue.main.async { [weak self] in
            self?.creditCardBillsSepartedByMonth.removeAll()
            self?.creditCardBills = newCreditCardBills
            for creditCardBill in newCreditCardBills {
                if let dueDateIndex = self?.creditCardBillsSepartedByMonth.firstIndex(where: { $0.dueDate == creditCardBill.dueDate }) {
                    self?.creditCardBillsSepartedByMonth[dueDateIndex].bills.append(creditCardBill)
                } else {
                    self?.creditCardBillsSepartedByMonth.append((dueDate: creditCardBill.dueDate, bills: [creditCardBill]))
                }
            }
            self?.tableView.reloadData()
        }
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
