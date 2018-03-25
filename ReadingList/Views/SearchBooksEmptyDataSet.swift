import Foundation
import UIKit

class SearchBooksEmptyDataset: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var poweredByGoogle: UIImageView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    enum EmptySetReason {
        case noSearch
        case noResults
        case error
    }
    
    func initialise(fromTheme theme: Theme) {
        backgroundColor = theme.tableBackgroundColor
        titleLabel.textColor = theme.titleTextColor
        descriptionLabel.textColor = theme.subtitleTextColor
        poweredByGoogle.image = theme == .normal ? #imageLiteral(resourceName: "PoweredByGoogle_White") : #imageLiteral(resourceName: "PoweredByGoogle_Black")
    }
    
    func setEmptyDatasetReason(_ reason: EmptySetReason) {
        self.reason = reason
        titleLabel.text = title
        descriptionLabel.text = descriptionString
    }
    
    func setTopDistance(_ distance: CGFloat) {
        topConstraint.constant = distance
        self.layoutIfNeeded()
    }
    
    private var reason = EmptySetReason.noSearch
    
    private var title: String {
        get {
            switch reason {
            case .noSearch:
                return "🔍 Search Books"
            case .noResults:
                return "😞 No Results"
            case .error:
                return "⚠️ Error!"
            }
        }
    }
    
    private var descriptionString: String {
        get {
            switch reason {
            case .noSearch:
                return "Search books by title, author, ISBN - or a mixture!"
            case .noResults:
                return "There were no Google Books search results. Try changing your search text."
            case .error:
                return "Something went wrong! It might be your Internet connection..."
            }
        }
    }
}
