import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.startDate, ascending: true)],
        predicate: NSPredicate(format: "isFinished == NO"),
        animation: .default
    )
    private var books: FetchedResults<Book>

    @State private var showingAddBook = false
    @State private var selectedBook: Book?

    var body: some View {
        NavigationStack {
            List {
                ForEach(books) { book in
                    BookRow(book: book)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedBook = book }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteBook(book)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                finishBook(book)
                            } label: {
                                Label("Finish", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                }
            }
            .navigationTitle("Reading")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CompletedBooksView()) {
                        Label("History", systemImage: "clock")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddBook = true } label: {
                        Label("Add Book", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if books.isEmpty {
                    ContentUnavailableView(
                        "No Books",
                        systemImage: "book",
                        description: Text("Tap + to add a book you're reading.")
                    )
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
            .sheet(item: $selectedBook) { book in
                UpdateProgressView(book: book)
            }
        }
    }

    private func finishBook(_ book: Book) {
        withAnimation {
            book.isFinished = true
            book.actualCompletionDate = Date()
            book.currentPage = book.totalPages

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteBook(_ book: Book) {
        withAnimation {
            viewContext.delete(book)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private struct BookRow: View {
    @ObservedObject var book: Book

    private var cadenceLabel: String {
        let cadence = ReadingCadence(rawValue: book.cadence) ?? .standard
        switch cadence {
        case .standard: return "Daily"
        case .work: return "Mon-Thu"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(book.title ?? "")
                .font(.headline)

            Text("Page \(book.currentPage) of \(book.totalPages)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: Double(book.currentPage), total: Double(book.totalPages))

            HStack {
                Text(cadenceLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let est = book.estimatedCompletionDate {
                    Text("Est. \(est, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
