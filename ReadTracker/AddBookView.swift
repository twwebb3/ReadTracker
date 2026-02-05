import SwiftUI
import CoreData

struct AddBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var totalPagesText = ""
    @State private var pagesPerDayText = "10"
    @State private var cadence: ReadingCadence = .standard

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
        && (Int32(totalPagesText) ?? 0) > 0
        && (Int16(pagesPerDayText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)

                    TextField("Total Pages", text: $totalPagesText)
                        .keyboardType(.numberPad)

                    TextField("Pages Per Day", text: $pagesPerDayText)
                        .keyboardType(.numberPad)
                }

                Section {
                    Picker("Reading Cadence", selection: $cadence) {
                        Text("Daily").tag(ReadingCadence.standard)
                        Text("Work (Mon-Thu)").tag(ReadingCadence.work)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveBook() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func saveBook() {
        let totalPages = Int32(totalPagesText) ?? 0
        let pagesPerDay = Int16(pagesPerDayText) ?? 10
        let today = Date()

        let estimatedDate = CompletionCalculator.estimatedCompletionDate(
            remainingPages: totalPages,
            pagesPerDay: pagesPerDay,
            cadence: cadence,
            from: today
        )

        let book = Book(context: viewContext)
        book.id = UUID()
        book.title = title.trimmingCharacters(in: .whitespaces)
        book.totalPages = totalPages
        book.currentPage = 0
        book.pagesPerDay = pagesPerDay
        book.cadence = cadence.rawValue
        book.startDate = today
        book.originalEstimatedCompletionDate = estimatedDate
        book.estimatedCompletionDate = estimatedDate
        book.isFinished = false

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

#Preview {
    AddBookView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
