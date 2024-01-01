//
//  NBTransactionsViewController.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 28/12/23.
//

import UIKit

final class NBTransactionsViewController: UITableViewController, NBTransactionDetailViewControllerDelegate {
    // MARK: Properties
    private let defaultCellReuseIdentifier = "transactionDetail-NBTransactionsViewController"
    private var transactions: [NBTransaction] = []
    private var transactionsSeparatedByDate: [(dateString: String, transactions: [NBTransaction])] = []
    
    // MARK: Views
    private var transactionDetailViewController: NBTransactionDetailViewController?
    private let documentPickerViewController = UIDocumentPickerViewController.init(forOpeningContentTypes: [.commaSeparatedText])
    
    private func updateTransactions(to newTransactions: [NBTransaction]) {
        DispatchQueue.main.async { [weak self] in
            self?.transactions = newTransactions
            self?.transactionsSeparatedByDate.removeAll()
            for transaction in newTransactions {
                if let indexOfDateForExistingTransactions = self?.transactionsSeparatedByDate.firstIndex(where: { $0.dateString == transaction.date.formatted(date: .abbreviated, time: .omitted) }) {
                    self?.transactionsSeparatedByDate[indexOfDateForExistingTransactions].transactions.append(transaction)
                } else {
                    self?.transactionsSeparatedByDate.append((dateString: transaction.date.formatted(date: .abbreviated, time: .omitted), transactions: [transaction]))
                }
            }
            self?.tableView.reloadData()
        }
    }
    private func loadTransactions() {
        NBCDManager.shared.loadAllTransactions { [weak self] result in
            switch result {
            case .success(let transactions):
                self?.updateTransactions(to: transactions)
            case .failure(let failure):
                let alertController = UIAlertController(title: "Unable to load transactions", message: failure.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                self?.present(alertController, animated: true)
            }
        }
    }
    
    // MARK: TableView
    override func numberOfSections(in tableView: UITableView) -> Int {
        transactionsSeparatedByDate.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard transactionsSeparatedByDate.count > section else { return .zero }
        return transactionsSeparatedByDate[section].transactions.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: defaultCellReuseIdentifier, for: indexPath)
        guard indexPath.section < transactionsSeparatedByDate.count, indexPath.row < transactionsSeparatedByDate[indexPath.section].transactions.count else { return cell }
        let transaction = transactionsSeparatedByDate[indexPath.section].transactions[indexPath.row]
        cell.textLabel?.text = transaction.title
        cell.textLabel?.numberOfLines = .zero
        cell.detailTextLabel?.text = "\(transaction.transactionType == .credit ? "+ " : "")₹" + String(format: "%.2f", transaction.amount)
        cell.detailTextLabel?.textColor = transaction.transactionType == .credit ? .systemGreen : .systemGray
        return cell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard transactionsSeparatedByDate.count > section else { return nil }
        return transactionsSeparatedByDate[section].dateString
    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            guard indexPath.section < transactionsSeparatedByDate.count, indexPath.row < transactionsSeparatedByDate[indexPath.section].transactions.count else { return }
            let transaction = transactionsSeparatedByDate[indexPath.section].transactions[indexPath.row]
            NBCDManager.shared.deleteTransaction(having: transaction.id) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let success):
                        guard success else { return }
                        self?.loadTransactions()
                    case .failure(let failure):
                        let alertController = UIAlertController(title: "Unable to delete transaction", message: failure.localizedDescription, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                        self?.present(alertController, animated: true)
                    }
                }
            }
        default: break
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section < transactionsSeparatedByDate.count, indexPath.row < transactionsSeparatedByDate[indexPath.section].transactions.count else { return }
        let transaction = transactionsSeparatedByDate[indexPath.section].transactions[indexPath.row]
        if transactionDetailViewController == nil {
            transactionDetailViewController = NBTransactionDetailViewController()
            transactionDetailViewController?.delegate = self
        }
        transactionDetailViewController?.loadTransaction(having: transaction.id)
        guard let transactionDetailViewController else { return }
        present(UINavigationController(rootViewController: transactionDetailViewController), animated: true)
    }
    
    // MARK: TransactionDetail Delegate
    func didUpdateTransaction(in detailViewController: NBTransactionDetailViewController) {
        loadTransactions()
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Transactions"
        tableView.register(NBTransactionDetailTableViewCell.self, forCellReuseIdentifier: defaultCellReuseIdentifier)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.setRightBarButtonItems([
            UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { _ in
                if self.transactionDetailViewController == nil {
                    self.transactionDetailViewController = NBTransactionDetailViewController()
                    self.transactionDetailViewController?.delegate = self
                } else {
                    self.transactionDetailViewController?.addNewTransaction()
                }
                guard let addTransactionViewController = self.transactionDetailViewController else { return }
                self.present(UINavigationController(rootViewController: addTransactionViewController), animated: true)
            })),
            UIBarButtonItem(title: "Import", primaryAction: UIAction(handler: { [weak self] _ in
                guard let documentPickerViewController = self?.documentPickerViewController else { return }
                self?.present(documentPickerViewController, animated: true)
            }))
        ], animated: true)
        loadTransactions()
        configDocumentPickerViewController()
    }
    
    // MARK: AddTransactionDelegate
    func addTransaction(viewController: NBTransactionDetailViewController, didAddTransaction newTransaction: NBTransaction) {
        transactions.insert(newTransaction, at: .zero)
        tableView.insertRows(at: [IndexPath(row: .zero, section: .zero)], with: .automatic)
    }
}


// MARK: - ImportTransactions
extension NBTransactionsViewController: UIDocumentPickerDelegate {
    private func configDocumentPickerViewController() {
        documentPickerViewController.delegate = self
    }
    
    // MARK: Delegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileUrl = urls.first else { return }
        let alertController = UIAlertController(title: nil, message: "Importing transactions...", preferredStyle: .alert)
        present(alertController, animated: true)
        NBCDManager.shared.importTransactions(from: fileUrl) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    defer {
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.4) {
                            alertController.dismiss(animated: true)
                        }
                    }
                    alertController.message = "Found 0 transactions for import."
                    guard success else { return }
                    alertController.message = "Imported all transactions successfully."
                    self?.loadTransactions()
                case .failure(let failure):
                    alertController.title = "Unable to import transactions"
                    alertController.message = failure.localizedDescription
                    alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
}
