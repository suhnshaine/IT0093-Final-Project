import UIKit

class NoteCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var noteLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Rounded corners create a card-like appearance that helps
        // visually separate individual notes in the collection view.
        layer.cornerRadius = 12
        clipsToBounds = true

        // Uses a system background color so the note card automatically
        // adapts to both light and dark mode appearances.
        backgroundColor = .secondarySystemBackground

        // Ensures images stay within the card boundaries and do not
        // overflow past the rounded corners.
        photoImageView.clipsToBounds = true
    }

    func configure(with note: Note) {

        // Displays the note content directly on the card so users can
        // quickly identify a note before opening it.
        noteLabel.text = note.text

        if let data = note.photoData,
           let image = UIImage(data: data) {

            // Notes with photos show the attached image to provide
            // a visual preview of the note's content.
            photoImageView.image = image

            // Fills the image area while preserving the image's proportions,
            // creating a more attractive thumbnail preview.
            photoImageView.contentMode = .scaleAspectFill

        } else {

            // A placeholder icon communicates that the note contains
            // text only, preventing the image area from appearing broken or empty.
            photoImageView.image =
                UIImage(systemName: "text.alignleft")

            // Centers the placeholder icon so it remains visually balanced
            // within the available image space.
            photoImageView.contentMode = .center

            // Uses a subtle color so the placeholder provides context
            // without distracting from the note content.
            photoImageView.tintColor = .systemGray3
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        // Collection view cells are recycled for performance. Clearing the
        // old image prevents a previously displayed note image from briefly
        // appearing in the wrong cell during scrolling.
        photoImageView.image = nil
    }
}
