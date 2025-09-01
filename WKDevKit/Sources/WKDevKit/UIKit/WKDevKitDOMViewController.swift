//
//  WKDevKitDOMViewController.swift
//  WKDevKit
//
//  UIKit DOM inspector view controller
//

#if os(iOS)
import UIKit
import WebKit
@available(iOS 15.0, *)
public class WKDevKitDOMViewController: UIViewController {
    private let webView: WKWebView
    private var debugger: WKDevKitDebugger?
    private var domTree: DOMNode?
    private var tableView: UITableView!
    private var loadingView: UIActivityIndicatorView!
    private var searchController: UISearchController!
    private var searchText: String = ""
    private var expandedNodes = Set<UUID>()
    private var flattenedNodes: [DOMNodeItem] = []
    
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
        loadDOMTree()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup table view
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DOMNodeCell.self, forCellReuseIdentifier: "DOMCell")
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
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
        searchController.searchBar.placeholder = "Search DOM..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Add refresh button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )
    }
    
    private func setupDebuggerSubscription() {
        // DOM data is fetched on demand, not subscribed
    }
    
    @objc private func refreshTapped() {
        loadDOMTree()
    }
    
    private func loadDOMTree() {
        guard let debugger = debugger else { return }
        
        loadingView.startAnimating()
        
        Task {
            do {
                let tree = try await debugger.fetchDOMTree()
                await MainActor.run {
                    self.domTree = tree
                    self.updateFlattenedNodes()
                    self.tableView.reloadData()
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
    
    private func updateFlattenedNodes() {
        flattenedNodes.removeAll()
        if let domTree = domTree {
            flattenNode(domTree, level: 0)
        }
    }
    
    private func flattenNode(_ node: DOMNode, level: Int) {
        // Check if node matches search or should be shown
        let shouldShow = searchText.isEmpty || nodeMatchesSearch(node) || nodeHasMatchingDescendant(node)
        
        if shouldShow {
            flattenedNodes.append(DOMNodeItem(node: node, level: level))
        }
        
        // Add children if expanded or searching
        if (expandedNodes.contains(node.id) || !searchText.isEmpty) && shouldShow {
            for child in node.children {
                flattenNode(child, level: level + 1)
            }
        }
    }
    
    private func nodeMatchesSearch(_ node: DOMNode) -> Bool {
        guard !searchText.isEmpty else { return true }
        
        return node.tag.localizedCaseInsensitiveContains(searchText) ||
               node.idAttr.localizedCaseInsensitiveContains(searchText) ||
               node.className.localizedCaseInsensitiveContains(searchText) ||
               (node.innerText?.localizedCaseInsensitiveContains(searchText) ?? false)
    }
    
    private func nodeHasMatchingDescendant(_ node: DOMNode) -> Bool {
        return node.children.contains { child in
            nodeMatchesSearch(child) || nodeHasMatchingDescendant(child)
        }
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
extension WKDevKitDOMViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flattenedNodes.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DOMCell", for: indexPath) as! DOMNodeCell
        let item = flattenedNodes[indexPath.row]
        let isExpanded = expandedNodes.contains(item.node.id)
        cell.configure(with: item, isExpanded: isExpanded, searchText: searchText)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = flattenedNodes[indexPath.row]
        if !item.node.children.isEmpty {
            if expandedNodes.contains(item.node.id) {
                expandedNodes.remove(item.node.id)
            } else {
                expandedNodes.insert(item.node.id)
            }
            updateFlattenedNodes()
            tableView.reloadData()
        }
    }
}

// MARK: - UISearchResultsUpdating
extension WKDevKitDOMViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        updateFlattenedNodes()
        tableView.reloadData()
    }
}

// MARK: - Supporting Types
private struct DOMNodeItem {
    let node: DOMNode
    let level: Int
}

private class DOMNodeCell: UITableViewCell {
    private let indentView = UIView()
    private let expandButton = UIButton(type: .system)
    private let tagLabel = UILabel()
    private let attributesLabel = UILabel()
    private let innerTextLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Indent view
        indentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Expand button
        expandButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Tag label
        tagLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        tagLabel.textColor = .systemBlue
        
        // Attributes label
        attributesLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        attributesLabel.textColor = .secondaryLabel
        
        // Text label
        innerTextLabel.font = UIFont.systemFont(ofSize: 11)
        innerTextLabel.textColor = .tertiaryLabel
        innerTextLabel.numberOfLines = 1
        
        // Stack view
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.addArrangedSubview(tagLabel)
        stackView.addArrangedSubview(attributesLabel)
        stackView.addArrangedSubview(innerTextLabel)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(indentView)
        contentView.addSubview(expandButton)
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            indentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            indentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            indentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            expandButton.leadingAnchor.constraint(equalTo: indentView.trailingAnchor),
            expandButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            expandButton.widthAnchor.constraint(equalToConstant: 30),
            expandButton.heightAnchor.constraint(equalToConstant: 30),
            
            stackView.leadingAnchor.constraint(equalTo: expandButton.trailingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with item: DOMNodeItem, isExpanded: Bool, searchText: String) {
        let node = item.node
        
        // Set indentation
        indentView.widthAnchor.constraint(equalToConstant: CGFloat(item.level * 16)).isActive = true
        
        // Configure expand button
        if !node.children.isEmpty {
            expandButton.isHidden = false
            expandButton.setImage(
                UIImage(systemName: isExpanded ? "chevron.down" : "chevron.right"),
                for: .normal
            )
        } else {
            expandButton.isHidden = true
        }
        
        // Configure labels
        tagLabel.text = "<\(node.tag.lowercased())>"
        
        var attributes: [String] = []
        if !node.idAttr.isEmpty {
            attributes.append("id=\"\(node.idAttr)\"")
        }
        if !node.className.isEmpty {
            attributes.append("class=\"\(node.className)\"")
        }
        attributesLabel.text = attributes.joined(separator: " ")
        attributesLabel.isHidden = attributes.isEmpty
        
        if let innerText = node.innerText, !innerText.isEmpty, node.children.isEmpty {
            innerTextLabel.text = innerText.trimmingCharacters(in: .whitespacesAndNewlines)
            innerTextLabel.isHidden = false
        } else {
            innerTextLabel.isHidden = true
        }
    }
}
#endif