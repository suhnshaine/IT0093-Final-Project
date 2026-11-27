import UIKit
import CoreData

class NotesViewController: UIViewController,
                           UICollectionViewDataSource,
                           UICollectionViewDelegateFlowLayout {

    var subject: Subject?

    private var notes: [Note] = []
    private let context = CoreDataStack.shared.context

    private let columns: CGFloat = 2
    private let spacing: CGFloat = 12

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Notes"

        collectionView.dataSource = self
        collectionView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNotes()
    }

    private func loadNotes() {

        guard let subject = subject else { return }

        let request: NSFetchRequest<Note> = Note.fetchRequest()

        request.predicate =
            NSPredicate(format: "subject == %@", subject)

        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt",
                             ascending: false)
        ]

        do {
            notes = try context.fetch(request)
        } catch {
            print("Could not fetch notes: \(error)")
            notes = []
        }

        collectionView.reloadData()
    }

    @IBAction func addNoteTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "ShowNoteFormSegue",
                     sender: nil)
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int)
    -> Int {
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
            return UICollectionViewCell()
        }

        cell.configure(with: notes[indexPath.item])

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        performSegue(
            withIdentifier: "ShowNoteDetailSegue",
            sender: notes[indexPath.item]
        )
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath)
    -> CGSize {

        let totalSpacing = spacing * (columns + 1)

        let width = floor(
            (collectionView.bounds.width - totalSpacing)
            / columns
        )

        return CGSize(width: width,
                      height: width + 40)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int)
    -> UIEdgeInsets {

        UIEdgeInsets(top: spacing,
                     left: spacing,
                     bottom: spacing,
                     right: spacing)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int)
    -> CGFloat {
        spacing
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int)
    -> CGFloat {
        spacing
    }
}
