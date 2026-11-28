import UIKit
import CoreData

class TasksViewController: UITableViewController {

    // MARK: - Properties

    // Stores the currently selected subject so only tasks that belong
    // to that subject are displayed and managed on this screen.
    var subject: Subject?

    // Maintains the task list currently shown in the table view,
    // avoiding repeated database queries while rendering cells.
    private var tasks: [TaskItem] = []

    // Uses the shared Core Data context so task changes remain
    // synchronized with the rest of the application.
    private let context = CoreDataStack.shared.context

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Displays the subject name in the navigation bar to remind users
        // which subject's tasks they are currently viewing.
        title = subject?.name
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Reloads tasks whenever the screen becomes active because
        // tasks may have been added or edited on another screen.
        loadTasks()
    }

    // MARK: - Core Data
    private func loadTasks() {

        // Tasks should only be shown when a subject has been selected.
        guard let subject = subject else { return }

        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()

        // Filters results so users only see tasks associated with
        // the currently selected subject.
        request.predicate = NSPredicate(format: "subject == %@", subject)

        // Pending tasks appear before completed ones, while due dates
        // keep active work organized by urgency.
        request.sortDescriptors = [
            NSSortDescriptor(key: "isDone", ascending: true),
            NSSortDescriptor(key: "dueDate", ascending: true)
        ]

        do {
            tasks = try context.fetch(request)
        } catch {
            // Falling back to an empty list prevents outdated data
            // from remaining visible if the fetch operation fails.
            print("Could not fetch tasks: \(error)")
            tasks = []
        }

        // Provides guidance when no tasks exist so the screen feels
        // intentional rather than appearing broken or incomplete.
        tableView.backgroundView = tasks.isEmpty
            ? emptyStateLabel("No tasks yet.\nTap + to add one.")
            : nil

        // Refreshes the table view to match the latest database state.
        tableView.reloadData()
    }

    // MARK: - Actions
    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        // Navigates to the task form where users can create a new task
        // for the currently selected subject.
        performSegue(withIdentifier: "ShowTaskFormSegue", sender: nil)
    }

    @IBAction func notesTapped(_ sender: UIBarButtonItem) {
        // Opens subject notes from the task screen so users can quickly
        // access related study materials and reminders.
        performSegue(withIdentifier: "ShowNotesSegue", sender: nil)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        // Keeps the table synchronized with the tasks loaded from Core Data.
        return tasks.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell",
                                                 for: indexPath)

        let task = tasks[indexPath.row]

        // Converts the stored due date into a readable format so users
        // can quickly understand deadlines without interpreting raw dates.
        let dueText = task.dueDate?.formatted(
            date: .abbreviated,
            time: .shortened
        ) ?? "no due date"

        var content = cell.defaultContentConfiguration()

        // Uses a fallback title so incomplete records do not create
        // confusing blank entries in the task list.
        content.text = task.title ?? "Untitled task"

        // Combines deadline and priority information into a single summary,
        // helping users assess task urgency at a glance.
        content.secondaryText = "Due \(dueText) - \(priorityName(for: task.priority))"

        // Visually distinguishes completed tasks without removing them,
        // allowing users to see their progress.
        content.textProperties.color = task.isDone ? .secondaryLabel : .label

        cell.contentConfiguration = content

        // A checkmark provides immediate visual feedback about completion status.
        cell.accessoryType = task.isDone ? .checkmark : .none

        return cell
    }

    private func priorityName(for value: Int16) -> String {

        // Translates stored numeric values into user-friendly labels,
        // keeping the database efficient while making priorities readable.
        switch value {
        case 0:
            return "Low"
        case 2:
            return "High"
        default:
            return "Medium"
        }
    }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {

        // Removes the selection highlight after navigation so returning
        // to the screen feels clean and consistent.
        tableView.deselectRow(at: indexPath, animated: true)

        // Passes the selected task to the form screen so users can edit
        // existing task details instead of creating a duplicate record.
        performSegue(
            withIdentifier: "ShowTaskFormSegue",
            sender: tasks[indexPath.row]
        )
    }

    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let task = tasks[indexPath.row]

        // Reuses the same action for both completion and reopening,
        // reducing interface clutter while supporting both workflows.
        let title = task.isDone ? "Undo" : "Done"

        let action = UIContextualAction(style: .normal, title: title) {
            [weak self] _, _, completion in

            // Allows users to quickly track progress without opening
            // the task's edit screen.
            task.isDone.toggle()

            // Saves the status change immediately so completion records
            // are not lost if the app closes unexpectedly.
            CoreDataStack.shared.save()
            self?.loadTasks()

            completion(true)
        }

        // Green is commonly associated with successful completion,
        // making the action's purpose easier to understand.
        action.backgroundColor = .systemGreen

        return UISwipeActionsConfiguration(actions: [action])
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        let action = UIContextualAction(style: .destructive, title: "Delete") {
            [weak self] _, _, completion in

            guard let self = self else {
                completion(false)
                return
            }

            // Permanently removes the task from the database so it no longer
            // contributes to progress tracking or pending task counts.
            self.context.delete(self.tasks[indexPath.row])

            // Saves the deletion immediately to keep the database
            // consistent with what is shown on screen.
            CoreDataStack.shared.save()
            self.loadTasks()

            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [action])
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {

        switch segue.identifier {
            
        case "ShowTaskFormSegue":
            guard let destination =
                segue.destination as? TaskFormViewController
            else { return }

            // Supplies the selected subject so new tasks can be linked
            // to the correct parent record.
            destination.subject = subject

            // When present, this task allows the form to switch into
            // edit mode instead of creating a new task.
            destination.taskToEdit = sender as? TaskItem

        case "ShowNotesSegue":
            guard let destination =
                segue.destination as? NotesViewController
            else { return }

            // Passes along the current subject so only notes related
            // to that subject are displayed.
            destination.subject = subject

        default:
            break
        }
    }
}
