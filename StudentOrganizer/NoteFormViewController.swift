import UIKit
import PhotosUI
import CoreData


class NoteFormViewController: UIViewController, PHPickerViewControllerDelegate {
    
    // MARK: - Data passed in from NotesViewController

    // Identifies which subject the new note belongs to so notes
    // remain organized and can be filtered correctly later.
    var subject: Subject?
    
    // Stores the selected image temporarily until the user saves.
    // Keeping it in memory avoids creating incomplete database records
    // before the note is actually saved.
    private var selectedImage: UIImage?
    
    // MARK: - Outlets
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var photoImageView: UIImageView!
    
    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Note"
        
        // A visible border helps distinguish the text area from the rest
        // of the interface, making it clearer where note content belongs.
        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = UIColor.systemGray4.cgColor
        noteTextView.layer.cornerRadius = 8
        
        // A placeholder image communicates that a photo can be attached,
        // preventing the image area from appearing broken or empty.
        photoImageView.image = UIImage(systemName: "photo")
        photoImageView.tintColor = .systemGray3
        photoImageView.contentMode = .center
        
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        
        // Allows users to dismiss the keyboard without interfering
        // with taps on buttons and other controls.
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {

        // Forces any active text entry to finish so the interface
        // remains clean and easier to interact with.
        view.endEditing(true)
    }
    
    // MARK: - Actions
    
    @IBAction func choosePhotoTapped(_ sender: UIButton) {
        
        var configuration = PHPickerConfiguration()

        // Restricts selection to images because notes only support
        // photo attachments and not other media types.
        configuration.filter = .images

        // Limiting selection to one image keeps note cards simple
        // and reduces storage requirements.
        configuration.selectionLimit = 1
        
        let picker =
        PHPickerViewController(
            configuration: configuration
        )
        
        // Uses the current controller to receive the selected image
        // and update the interface accordingly.
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        
        // Closes the keyboard before validation so any feedback
        // messages remain fully visible.
        view.endEditing(true)
        
        let text = (noteTextView.text ?? "")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        
        // Prevents empty notes from being stored, ensuring every
        // saved note contains meaningful information.
        guard !text.isEmpty else {
            
            showAlert(
                title: "Note is empty",
                message: "Please write something before saving."
            )
            
            return
        }
        
        // Creates a new note record only after validation succeeds,
        // preventing incomplete data from entering Core Data.
        let note =
        Note(
            context: CoreDataStack.shared.context
        )
        
        note.text = text

        // Records when the note was created so notes can be sorted
        // chronologically and recent notes can be prioritized.
        note.createdAt = Date()
        
        // Compresses the image before storage to reduce database size
        // while maintaining acceptable visual quality.
        note.photoData =
        selectedImage?
            .jpegData(
                compressionQuality: 0.8
            )
        
        // Maintains the relationship between the note and its subject,
        // allowing subject-specific note retrieval throughout the app.
        note.subject = subject
        
        // Persists the note so it remains available after the app closes.
        CoreDataStack.shared.save()
        
        // Returns to the notes screen immediately after saving,
        // matching the user's expectation that the note was stored successfully.
        navigationController?
            .popViewController(animated: true)
    }
    
    // MARK: - PHPickerViewControllerDelegate
    
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        
        // Dismisses the picker immediately to return focus to the form
        // regardless of whether an image was selected.
        picker.dismiss(animated: true)
        
        guard let provider =
                results.first?.itemProvider,
              provider.canLoadObject(
                ofClass: UIImage.self
              )
        else { return }
        
        provider.loadObject(
            ofClass: UIImage.self
        ) { [weak self] object, error in
            
            guard let image =
                    object as? UIImage
            else { return }
            
            // Large camera photos consume significant storage space.
            // Resizing before saving helps keep Core Data efficient
            // and improves application performance.
            let smallImage =
            image.resized(
                maxDimension: 1024
            )
            
            DispatchQueue.main.async {
                
                // Stores the processed image so it can be attached
                // when the note is eventually saved.
                self?.selectedImage =
                smallImage
                
                // Provides immediate visual confirmation that the
                // selected image was successfully loaded.
                self?.photoImageView.image =
                smallImage
                
                // Displays the entire image preview without cropping,
                // allowing users to verify they selected the correct photo.
                self?.photoImageView.contentMode =
                    .scaleAspectFit
            }
        }
    }
}
