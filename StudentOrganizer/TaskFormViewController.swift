import UIKit
import CoreData


class TaskFormViewController: UIViewController {
    
    // MARK: - Data passed in from TasksViewController
    var subject: Subject?
    var taskToEdit: TaskItem?     // nil = adding a new task, not nil = editing
    
    // MARK: - Outlets
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailsTextField: UITextField!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var prioritySegmentedControl: UISegmentedControl!
    @IBOutlet weak var completedSwitch: UISwitch!
    
    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let task = taskToEdit {
            
            title = "Edit Task"
            titleTextField.text = task.title
            detailsTextField.text = task.details
            dueDatePicker.date = task.dueDate ?? Date()
            prioritySegmentedControl.selectedSegmentIndex = Int(task.priority)
            completedSwitch.isOn = task.isDone
            
        } else {
            
            title = "New Task"
            dueDatePicker.date = Date()
        }
        
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        
        view.endEditing(true)
        
        let taskTitle = (titleTextField.text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !taskTitle.isEmpty else {
            
            showAlert(
                title: "Title required",
                message: "Please type a title for your task."
            )
            
            return
        }
        
        let task =
        taskToEdit ??
        TaskItem(context: CoreDataStack.shared.context)
        
        task.title = taskTitle
        task.details = detailsTextField.text
    }
}
