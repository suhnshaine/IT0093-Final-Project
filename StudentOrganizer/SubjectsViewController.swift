import UIKit
import CoreData

class SubjectsViewController: UITableViewController {

    // MARK: - Properties

    // Maintains the in-memory list currently displayed in the table view,
    // avoiding repeated database lookups while rendering cells.
    private var subjects: [Subject] = []
    // Uses the shared Core Data context so all screens read and write
    // data through the same persistence layer.
    private let context = CoreDataStack.shared.context

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Sets a clear screen title so users always know which section
        // of the organizer they are currently viewing.
        title = "My Subjects"

        // Places subject creation in the navigation bar for quick access
        // because adding subjects is a primary action on this screen.
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
    }
    
    @objc private func addButtonTapped() {
        // Redirects navigation-bar taps to the existing IBAction so
        // subject creation logic is maintained in one place.
        addSubjectTapped(UIBarButtonItem())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Reloads data whenever the screen becomes visible because
        // subjects or tasks may have changed on another screen.
        loadSubjects()
    }

    // MARK: - Core Data
    private func loadSubjects() {

        let request: NSFetchRequest<Subject> = Subject.fetchRequest()

        // Sorting alphabetically makes subjects easier to locate
        // and ensures a consistent order across app launches.
        request.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]

        do {
            subjects = try context.fetch(request)
        } catch {
            // Falling back to an empty array prevents the app from displaying
            // stale or invalid data if the fetch operation fails.
            print("Could not fetch subjects: \(error)")
            subjects = []
        }

        // Shows a friendly empty-state message so users understand
        // the list is empty rather than believing the screen failed to load.
        tableView.backgroundView = subjects.isEmpty
            ? emptyStateLabel("No subjects yet.\nTap + to add one.")
            : nil

        // Refreshes the table to reflect the latest database contents.
        tableView.reloadData()
    }

    // MARK: - Actions
    @IBAction func addSubjectTapped(_ sender: UIBarButtonItem) {

        // Collects subject information without requiring a separate screen,
        // keeping the creation process fast and simple.
        let alert = UIAlertController(
            title: "New Subject",
            message: "Enter the name of the subject.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            // Helps guide users toward the expected input format and
            // automatically capitalizes subject names for consistency.
            textField.placeholder = "e.g., Mobile Application Development 2"
            textField.autocapitalizationType = .words
        }

        alert.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel
            )
        )

        let saveAction = UIAlertAction(
            title: "Save",
            style: .default
        ) { [weak self, weak alert] _ in

            // Prevents empty or whitespace-only subject names from being
            // stored, which would make the subject list harder to understand.
            guard let self = self,
                  let name = alert?.textFields?.first?.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else {
                return
            }

            // Creates the Core Data object only after validation succeeds
            // to avoid storing incomplete subject records.
            let subject = Subject(context: self.context)
            subject.name = name

            // Records when the subject was created, which can be useful
            // for future sorting, filtering, or analytics features.
            subject.createdAt = Date()

            // Persists the new subject so it remains available after
            // the application is closed and reopened.
            CoreDataStack.shared.save()

            // Reloads the list immediately so the user sees the result
            // of the action without leaving the screen.
            self.loadSubjects()
        }

        alert.addAction(saveAction)
        present(alert, animated: true)
    }

    // MARK: - Table View Data Source
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {

        // Keeps the table synchronized with the subjects currently
        // loaded from Core Data.
        return subjects.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SubjectCell",
            for: indexPath
        )

        let subject = subjects[indexPath.row]

        // Converts the relationship into a Swift collection so task
        // statistics can be calculated easily for display.
        let allTasks = subject.tasks as? Set<TaskItem> ?? []

        // Displaying pending work gives users a quick overview of
        // progress without needing to open each subject.
        let pendingCount = allTasks.filter { !$0.isDone }.count

        var content = cell.defaultContentConfiguration()

        // Provides a fallback title to prevent empty-looking rows
        // if a subject record somehow lacks a name.
        content.text = subject.name ?? "Untitled subject"
        content.secondaryText = "\(pendingCount) pending task(s)"

        cell.contentConfiguration = content

        // Indicates that tapping a subject opens another screen
        // containing additional details.
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    // MARK: - Delete Subject
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {

        guard editingStyle == .delete else {
            return
        }

        // Removing the subject from Core Data ensures it no longer
        // appears anywhere in the application.
        context.delete(subjects[indexPath.row])

        // Commits the deletion so it persists between app launches.
        CoreDataStack.shared.save()

        // Updates the local data source to match the database state.
        subjects.remove(at: indexPath.row)

        // Removes the row with animation to provide visual confirmation
        // that the deletion was successful.
        tableView.deleteRows(
            at: [indexPath],
            with: .automatic
        )

        // Restores the empty-state message when the last subject
        // has been removed from the list.
        tableView.backgroundView = subjects.isEmpty
            ? emptyStateLabel("No subjects yet.\nTap + to add one.")
            : nil
    }
    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {

        // Removes the selection highlight so the interface behaves
        // consistently when users return to this screen.
        tableView.deselectRow(at: indexPath,
                              animated: true)

        // Passes the selected subject to the next screen so it can
        // display only the tasks belonging to that subject.
        performSegue(
            withIdentifier: "ShowTasksSegue",
            sender: subjects[indexPath.row]
        )
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {

        guard segue.identifier == "ShowTasksSegue",
              let destination =
                segue.destination as? TasksViewController,
              let subject = sender as? Subject
        else { return }

        // Provides the destination screen with the selected subject,
        // allowing it to load and manage the correct task records.
        destination.subject = subject
    }
}
