import UIKit
import CoreData

class NotesViewController: UIViewController,
                           UICollectionViewDataSource,
                           UICollectionViewDelegateFlowLayout {

    // Identifies the subject whose notes should be displayed,
    // ensuring notes remain organized by subject throughout the app.
    var subject: Subject?

    // Stores the notes currently shown in the collection view,
    // allowing the interface to render data fetched from Core Data.
    private var notes: [Note] = []

    // Uses the shared Core Data context so note changes remain
    // consistent across all screens in the application.    
    private let context = CoreDataStack.shared.context

    // Defines a two-column layout that makes better use of screen space
    // than a single-column list while still keeping notes readable.
    private let columns: CGFloat = 2

    // Centralized spacing keeps the note grid visually balanced
    // and makes layout adjustments easier to maintain.
    private let spacing: CGFloat = 12

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Gives users clear context about the type of content
        // being viewed on this screen.
        title = "Notes"

        // Assigning these delegates allows this controller to manage
        // both the note data and the grid layout behavior.
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Reloads notes whenever the screen becomes visible because
        // notes may have been created, edited, or deleted elsewhere.
        loadNotes()
    }

    private func loadNotes() {

        // Notes should only be loaded when a subject has been selected.
        guard let subject = subject else { return }

        let request: NSFetchRequest<Note> = Note.fetchRequest()

        // Restricts results to notes belonging to the current subject,
        // preventing unrelated notes from appearing together.
        request.predicate =
            NSPredicate(format: "subject == %@", subject)

        // Showing newest notes first makes recently added content
        // easier to find and continue working on.
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt",
                             ascending: false)
        ]

        do {
            notes = try context.fetch(request)
        } catch {
            // Falling back to an empty collection prevents outdated
            // data from remaining visible after a fetch failure.
            print("Could not fetch notes: \(error)")
            notes = []
        }

        // Refreshes the grid so the interface always reflects
        // the current state of the database.
        collectionView.reloadData()
    }

    @IBAction func addNoteTapped(_ sender: UIBarButtonItem) {

        // Opens the note creation screen while keeping the current
        // subject context intact.
        performSegue(withIdentifier: "ShowNoteFormSegue",
                     sender: nil)
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int)
    -> Int {
        // Ensures the collection view displays one cell for each
        // note currently loaded from Core Data.
        notes.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {

        guard let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: "NoteCell",
                    for: indexPath
                ) as? NoteCell
        else {

            // Returns a default cell instead of crashing if the
            // expected custom cell cannot be created.
            return UICollectionViewCell()
        }

        // Delegates note presentation to the custom cell so formatting
        // logic remains reusable and separate from the controller.
        cell.configure(with: notes[indexPath.item])

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        // Passes the selected note to the next screen so users can
        // view or work with the correct note.
        performSegue(
            withIdentifier: "ShowNoteDetailSegue",
            sender: notes[indexPath.item]
        )
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath)
    -> CGSize {

        // Accounts for outer margins and spacing between columns
        // so cells fit evenly across the available width.
        let totalSpacing = spacing * (columns + 1)

        let width = floor(
            (collectionView.bounds.width - totalSpacing)
            / columns
        )

        // Uses square-like cards with additional height for text,
        // creating a consistent and visually organized note grid.
        return CGSize(width: width,
                      height: width + 40)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int)
    -> UIEdgeInsets {

        // Adds padding around the grid so cells do not touch
        // the edges of the screen.
        UIEdgeInsets(top: spacing,
                     left: spacing,
                     bottom: spacing,
                     right: spacing)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int)
    -> CGFloat {
        // Reuses the standard spacing value to maintain a consistent
        // appearance throughout the grid.
        spacing
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int)
    -> CGFloat {
        // Keeps horizontal spacing consistent so note cards appear
        // evenly distributed across the screen.
        spacing
    }
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {

        switch segue.identifier {

        case "ShowNoteFormSegue":

            guard let destination =
                    segue.destination as?
                    NoteFormViewController
            else { return }

            // Passes the active subject so newly created notes are
            // automatically linked to the correct subject.
            destination.subject = subject

        default:
            break
        }
    }
}
