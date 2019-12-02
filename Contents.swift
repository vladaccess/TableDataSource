import UIKit

protocol RowConfigurable {
    func configure(cell: UITableViewCell)
}

protocol Row: RowConfigurable {
    var reuseIdentifier: String { get }
}

protocol ConfigurableCell {
    associatedtype CellData
    static var reuseIdentifier: String { get }
    func configure(with data: CellData)
}

extension ConfigurableCell where Self: UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

struct TableRow<CellType: ConfigurableCell>: Row where CellType: UITableViewCell {
    
    let data: CellType.CellData
    var reuseIdentifier = CellType.reuseIdentifier
    
    init(data: CellType.CellData) {
        self.data = data
    }
    
    func configure(cell: UITableViewCell) {
        (cell as? CellType)?.configure(with: data)
    }
}

struct TableSection {
    
    var rows: [Row]
    
    var footerView: UIView?
    var footerHeight: CGFloat?
    var footerTitle: String?
    
    var headerView: UIView?
    var headerHeight: CGFloat?
    var headerTitle: String?
    
    init(rows: [Row]) {
        self.rows = rows
    }
}

class TableDataSource: NSObject, UITableViewDataSource {
    
    //MARK: - Private Properties
    private var _sections = [TableSection]()
    private let queue = DispatchQueue(label: "TableDataSource_Queue")
    
    //MARK: - Getter
    var sections: [TableSection] {
        queue.sync {
            return _sections
        }
    }
    
    //MARK: - LifeCircle
    init(sections: [TableSection]) {
        super.init()
        append(sections: sections)
    }
    
    //MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        row.configure(cell: cell)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {
        return sections[safe: section]?.headerView
    }
    
    func tableView(_ tableView: UITableView,
                   heightForHeaderInSection section: Int) -> CGFloat {
        return sections[safe: section]?.headerHeight ?? UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView,
                   titleForHeaderInSection section: Int) -> String? {
        return sections[safe: section]?.headerTitle
    }
    
    func tableView(_ tableView: UITableView,
                   viewForFooterInSection section: Int) -> UIView? {
        return sections[safe: section]?.footerView
    }
    
    func tableView(_ tableView: UITableView,
                   heightForFooterInSection section: Int) -> CGFloat {
        return sections[safe: section]?.footerHeight ?? UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView,
                   titleForFooterInSection section: Int) -> String? {
        return sections[safe: section]?.footerTitle
    }
}

//MARK: - Setters
extension TableDataSource {
    func append(sections: [TableSection]) {
        queue.async {
            self._sections.append(contentsOf: sections)
        }
    }
    
    func append(section: TableSection) {
        queue.async {
            self._sections.append(section)
        }
    }
    
    func removeAll(keepingCapacity keepCapacity: Bool = false) {
        queue.async {
            self._sections.removeAll(keepingCapacity: keepCapacity)
        }
    }
    
    func insert(section: TableSection, at index: Int) {
        queue.async {
            self._sections.insert(section, at: index)
        }
    }
    
    func insert(sections: [TableSection], at index: Int) {
        queue.async {
            self._sections.insert(contentsOf: sections, at: index)
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
