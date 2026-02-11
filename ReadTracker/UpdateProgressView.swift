import SwiftUI
import CoreData

struct UpdateProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var book: Book
    @State private var newPageText: String = ""
    @State private var showFinishAlert = false
    @State private var pagesToAdd: Int32 = 10

    private var remainingPages: Int32 {
        book.totalPages - book.currentPage
    }

    private var clampedPagesToAdd: Int32 {
        min(pagesToAdd, remainingPages)
    }

    private var newPage: Int32 {
        Int32(newPageText) ?? book.currentPage
    }

    private var previewEstimatedDate: Date {
        let remaining = book.totalPages - newPage
        guard remaining > 0 else { return Date() }
        let cadence = ReadingCadence(rawValue: book.cadence) ?? .standard
        return CompletionCalculator.estimatedCompletionDate(
            remainingPages: remaining,
            pagesPerDay: book.pagesPerDay,
            cadence: cadence,
            from: Date()
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(book.title ?? "")
                        .font(.headline)
                }

                Section("Progress") {
                    Text("Currently on page \(book.currentPage) of \(book.totalPages)")

                    TextField("New page number", text: $newPageText)
                        .keyboardType(.numberPad)

                    if remainingPages > 0 {
                        Stepper("Add \(clampedPagesToAdd) pages", value: $pagesToAdd, in: 1...remainingPages)

                        Text("That's page \(book.currentPage + clampedPagesToAdd) of \(book.totalPages)")
                            .foregroundStyle(.secondary)

                        Button("Apply") {
                            newPageText = "\(book.currentPage + clampedPagesToAdd)"
                        }
                    }
                }

                Section("Estimated Completion") {
                    if newPage >= book.totalPages {
                        Text("Book complete!")
                            .foregroundStyle(.green)
                    } else {
                        Text(previewEstimatedDate, style: .date)
                    }
                }
            }
            .navigationTitle("Update Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProgress() }
                        .disabled(newPageText.isEmpty || newPage < 0 || newPage > book.totalPages)
                }
            }
            .alert("Mark as Finished?", isPresented: $showFinishAlert) {
                Button("Finish", role: .destructive) { markFinished() }
                Button("Just Update", role: .cancel) { saveAndDismiss() }
            } message: {
                Text("You've reached the last page. Would you like to mark this book as finished?")
            }
            .onAppear {
                newPageText = "\(book.currentPage)"
            }
        }
    }

    private func saveProgress() {
        if newPage >= book.totalPages {
            showFinishAlert = true
        } else {
            saveAndDismiss()
        }
    }

    private func saveAndDismiss() {
        book.currentPage = newPage
        let remaining = book.totalPages - newPage
        let cadence = ReadingCadence(rawValue: book.cadence) ?? .standard
        book.estimatedCompletionDate = CompletionCalculator.estimatedCompletionDate(
            remainingPages: remaining,
            pagesPerDay: book.pagesPerDay,
            cadence: cadence,
            from: Date()
        )

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    private func markFinished() {
        book.currentPage = book.totalPages
        book.isFinished = true
        book.actualCompletionDate = Date()

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
