import UIKit
import CoreData


class TaskFormViewController: UIViewController {
    
    // MARK: - Data passed in from TasksViewController

    // Identifies which subject the task belongs to so new tasks
    // are correctly linked and later appear under the proper subject.
    var subject: Subject?

    // A nil value indicates task creation mode, while a non-nil value
    // allows the same screen to be reused for editing an existing task.
    var taskToEdit: TaskItem?     // nil = adding a new task, not nil = editing
    
    // MARK: - Outlets

    // Collects the most important piece of information used to identify
    // the task throughout the application.
    @IBOutlet weak var titleTextField: UITextField!

    // Allows users to store additional context without cluttering
    // the main task list interface.
    @IBOutlet weak var detailsTextField: UITextField!

    // Encourages deadline tracking so tasks can be prioritized
    // and sorted by upcoming due dates.
    @IBOutlet weak var dueDatePicker: UIDatePicker!

    // Uses predefined priority levels to keep priority values
    // consistent across all tasks and avoid free-text variations.
    @IBOutlet weak var prioritySegmentedControl: UISegmentedControl!

    // Gives users a quick way to record task completion status
    // without returning to the task list.
    @IBOutlet weak var completedSwitch: UISwitch!
    
    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let task = taskToEdit {
            
            // Preloading existing values allows users to update only
            // the fields they want to change instead of re-entering everything.
            title = "Edit Task"
            titleTextField.text = task.title
            detailsTextField.text = task.details
            dueDatePicker.date = task.dueDate ?? Date()
            prioritySegmentedControl.selectedSegmentIndex = Int(task.priority)
            completedSwitch.isOn = task.isDone
            
        } else {
            
            // Using the current date as the default reduces the amount
            // of input required when creating a new task.
            title = "New Task"
            dueDatePicker.date = Date()
        }
        
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        
        // Allows users to dismiss the keyboard by tapping outside a field
        // without preventing normal interaction with other controls.
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        // Ensures text field edits are finalized before users interact
        // with other elements on the form.
        view.endEditing(true)
    }
    
    // MARK: - Actions
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        
        // Useful during development to verify that the save action
        // is being triggered correctly.
        print("SAVE WORKING")
        
        // Closes the keyboard before validation and saving so the user
        // can immediately see any feedback or navigation changes.
        view.endEditing(true)
        
        let taskTitle = (titleTextField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Prevents blank or whitespace-only task titles from being saved,
        // ensuring every task remains identifiable in the task list.
        guard !taskTitle.isEmpty else {
            
            showAlert(
                title: "Title required",
                message: "Please type a title for your task."
            )
            
            return
        }
        
        // Reuses the existing object during edits and creates a new one
        // only when the user is adding a task.
        let task =
        taskToEdit ??
        TaskItem(context: CoreDataStack.shared.context)
        
        // Updates the task with the latest values entered by the user.
        task.title = taskTitle
        task.details = detailsTextField.text
        
        // Stores the selected deadline so tasks can be organized
        // and displayed according to due dates.
        task.dueDate =
        dueDatePicker.date
        
        // Saves the selected priority as a numeric value that can be
        // efficiently stored and processed by Core Data.
        task.priority =
        Int16(
            prioritySegmentedControl
                .selectedSegmentIndex
        )
        
        // Preserves the user's completion status choice.
        task.isDone =
        completedSwitch.isOn
        
        // Maintains the relationship between the task and its parent subject,
        // allowing subject-specific task filtering throughout the app.
        task.subject = subject
        
        // Persists all changes so they remain available after the app closes.
        CoreDataStack.shared.save()
        
        // Returns to the task list immediately after saving, matching
        // the user's expectation that the task has been successfully stored.
        navigationController?
            .popViewController(animated: true)
    }
}
