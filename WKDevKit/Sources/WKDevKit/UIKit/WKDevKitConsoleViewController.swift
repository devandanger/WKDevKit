//
//  WKDevKitConsoleViewController.swift
//  WKDevKit
//
//  UIKit console view controller for displaying console messages
//

#if os(iOS)
import UIKit
import Combine
@available(iOS 15.0, *)
public class WKDevKitConsoleViewController: UIViewController {
    public var debugger: WKDevKitDebugger? {
        didSet {
            setupDebuggerSubscription()
        }
    }
    
    private var messages: [ConsoleMessage] = [] {
        didSet {
            DispatchQueue.main.async {
                self.updateTableView()
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var tableView: UITableView!
    private var searchController: UISearchController!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDebuggerSubscription()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup table view
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ConsoleMessageCell.self, forCellReuseIdentifier: "ConsoleCell")
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup search controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search console logs..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Add clear button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearLogs)
        )
    }
    
    private func setupDebuggerSubscription() {
        cancellables.removeAll()
        
        guard let debugger = debugger else { return }
        
        debugger.$consoleLogs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logs in
                self?.messages = logs
            }
            .store(in: &cancellables)
    }
    
    @objc private func clearLogs() {
        debugger?.clearConsole()
        messages.removeAll()
    }
    
    private func updateTableView() {
        tableView.reloadData()
        
        // Scroll to bottom
        if !messages.isEmpty {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private var filteredMessages: [ConsoleMessage] {
        guard let searchText = searchController.searchBar.text,
              !searchText.isEmpty else {
            return messages
        }
        
        return messages.filter {
            $0.args.localizedCaseInsensitiveContains(searchText) ||
            $0.method.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - UITableViewDataSource
extension WKDevKitConsoleViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMessages.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConsoleCell", for: indexPath) as! ConsoleMessageCell
        cell.configure(with: filteredMessages[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension WKDevKitConsoleViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension WKDevKitConsoleViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        tableView.reloadData()
    }
}

// MARK: - ConsoleMessageCell
private class ConsoleMessageCell: UITableViewCell {
    private let methodIconView = UIImageView()
    private let messageLabel = UILabel()
    private let timestampLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Method icon
        methodIconView.contentMode = .scaleAspectFit
        methodIconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Message label
        messageLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Timestamp label
        timestampLabel.font = UIFont.systemFont(ofSize: 11)
        timestampLabel.textColor = .secondaryLabel
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack view
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(methodIconView)
        
        let textStackView = UIStackView(arrangedSubviews: [messageLabel, timestampLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4
        stackView.addArrangedSubview(textStackView)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            methodIconView.widthAnchor.constraint(equalToConstant: 20),
            methodIconView.heightAnchor.constraint(equalToConstant: 20),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with message: ConsoleMessage) {
        messageLabel.text = message.args
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        timestampLabel.text = formatter.string(from: message.timestamp)
        
        // Set icon and color based on method
        switch message.method {
        case "error":
            methodIconView.image = UIImage(systemName: "xmark.circle.fill")
            methodIconView.tintColor = .systemRed
            messageLabel.textColor = .systemRed
        case "warn":
            methodIconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            methodIconView.tintColor = .systemOrange
            messageLabel.textColor = .systemOrange
        case "info":
            methodIconView.image = UIImage(systemName: "info.circle.fill")
            methodIconView.tintColor = .systemBlue
            messageLabel.textColor = .label
        case "debug":
            methodIconView.image = UIImage(systemName: "ant.fill")
            methodIconView.tintColor = .systemPurple
            messageLabel.textColor = .secondaryLabel
        default:
            methodIconView.image = UIImage(systemName: "text.bubble.fill")
            methodIconView.tintColor = .label
            messageLabel.textColor = .label
        }
    }
}
#endif