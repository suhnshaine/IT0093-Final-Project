import UIKit
  
extension UIViewController {
    /// Provides a reusable way for any screen to display validation,
    /// error, or informational messages so the app presents feedback
    /// consistently instead of each view controller creating its own alert logic.
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: .alert)
        // Acknowledgement-only alerts prevent users from accidentally
        // making destructive choices when the goal is simply to inform them.
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        // Presents the alert immediately on the current screen so important
        // feedback is visible before the user continues interacting with the UI.
        present(alert, animated: true)
    }
}
  
extension UIImage {
    /// Returns a smaller copy whose longest side is at most maxDimension pixels.
    /// Photos from the iPhone camera are huge; shrinking them keeps the database small.
    func resized(maxDimension: CGFloat) -> UIImage {
        // Uses the longest dimension so portrait and landscape images
        // are resized proportionally without distorting their aspect ratio.
        let longestSide = max(size.width, size.height)
        // Skips image processing when the image is already small enough,
        // preserving quality and avoiding unnecessary work.
        guard longestSide > maxDimension else { return self }
  
        // Calculates a proportional scaling factor so the image fits within
        // the target size while maintaining its original shape.
        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
  
        let format = UIGraphicsImageRendererFormat.default()
        // Using a scale of 1 ensures the generated image matches the intended
        // pixel dimensions, helping control storage size more predictably.
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            // Draws the original image into a smaller canvas to create
            // a compressed version suitable for storage in Core Data.
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
  
/// Creates a standardized empty-state message used throughout the app
/// so screens without data provide clear feedback instead of appearing broken.
func emptyStateLabel(_ message: String) -> UILabel {
    let label = UILabel()
    // Allows each screen to provide context-specific guidance about
    // why no content is currently available.
    label.text = message
    // Supports longer messages that may need multiple lines on smaller devices.
    label.numberOfLines = 0
    // Centers the message to make empty states visually distinct from normal content.
    label.textAlignment = .center
    // Uses a secondary color so the message is visible without competing
    // with primary content when data eventually exists.
    label.textColor = .secondaryLabel
    // Uses Dynamic Type to improve readability and accessibility across devices.
    label.font = .preferredFont(forTextStyle: .body)
    return label
} 
