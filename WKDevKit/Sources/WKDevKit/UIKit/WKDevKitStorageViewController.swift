//
//  WKDevKitStorageViewController.swift
//  WKDevKit
//
//  UIKit storage inspector view controller
//

#if os(iOS)
import UIKit
import WebKit

public class WKDevKitStorageViewController: UIViewController {
    private let webView: WKWebView
    private var debugger: WKDevKitDebugger?
    private var storageItems: [WebStorageItem] = [] {
        didSet {
            DispatchQueue.main.async {
                self.updateTableView()
            }
        }
    }
    private var tableView: UITableView!
    private var loadingView: UIActivityIndicatorView!
    private var searchController: UISearchController!
    private var searchText: String = ""
    
    public init(webView: WKWebView) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
        self.debugger = webView.devKitDebugger
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStorageData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup table view
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StorageItemCell.self, forCellReuseIdentifier: "StorageCell")
        tableView.register(StorageHeaderView.self, forHeaderFooterViewReuseIdentifier: "HeaderView")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup loading view
        loadingView = UIActivityIndicatorView(style: .large)
        loadingView.hidesWhenStopped = true
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Setup search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search storage..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Add refresh button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )
    }
    
    @objc private func refreshTapped() {
        loadStorageData()
    }
    
    private func loadStorageData() {
        guard let debugger = debugger else { return }
        
        loadingView.startAnimating()
        
        Task {
            do {
                let items = try await debugger.fetchWebStorage()
                await MainActor.run {
                    self.storageItems = items
                    self.loadingView.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    self.loadingView.stopAnimating()
                    self.showError(error)
                }
            }
        }
    }
    
    private func updateTableView() {
        tableView.reloadData()
    }
    
    private var filteredItems: [WebStorageItem] {
        guard !searchText.isEmpty else { return storageItems }
        
        return storageItems.filter {
            $0.key.localizedCaseInsensitiveContains(searchText) ||
            $0.value.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var groupedItems: [WebStorageType: [WebStorageItem]] {
        Dictionary(grouping: filteredItems) { $0.type }
    }
    
    private var sortedTypes: [WebStorageType] {
        return WebStorageType.allCases.filter { groupedItems[$0]?.isEmpty == false }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension WKDevKitStorageViewController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sortedTypes.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let type = sortedTypes[section]
        return groupedItems[type]?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StorageCell", for: indexPath) as! StorageItemCell
        let type = sortedTypes[indexPath.section]
        if let items = groupedItems[type] {
            cell.configure(with: items[indexPath.row], searchText: searchText)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderView") as! StorageHeaderView
        let type = sortedTypes[section]
        let count = groupedItems[type]?.count ?? 0
        header.configure(with: type, count: count)
        return header
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension WKDevKitStorageViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        tableView.reloadData()
    }
}

// MARK: - Supporting Views
private class StorageHeaderView: UITableViewHeaderFooterView {
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .label
        
        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = .secondaryLabel
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with type: WebStorageType, count: Int) {
        titleLabel.text = type.rawValue
        countLabel.text = "(\(count))"
    }
}

private class StorageItemCell: UITableViewCell {
    private let keyLabel = UILabel()
    private let valueLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        keyLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        keyLabel.textColor = .label
        keyLabel.numberOfLines = 1
        
        valueLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        valueLabel.numberOfLines = 3
        
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.addArrangedSubview(keyLabel)
        stackView.addArrangedSubview(valueLabel)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with item: WebStorageItem, searchText: String) {
        keyLabel.text = item.key
        valueLabel.text = item.value.count > 100 ? 
            String(item.value.prefix(100)) + "..." : 
            item.value
    }
}
#endif