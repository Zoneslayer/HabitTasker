import SwiftUI

struct HabitsView: View {
    @EnvironmentObject private var store: HabitStore
    @Environment(\.editMode) private var editMode

    @State private var presentAdd = false
    @State private var editHabit: Habit? = nil
    @State private var habitPendingDeletion: Habit? = nil
    @State private var showDeleteConfirmation = false

    private var isEditing: Bool { editMode?.wrappedValue.isEditing == true }

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.background.ignoresSafeArea()

                List {
                    // Верхняя кнопка "Добавить"
                    Section {
                        Button {
                            presentAdd = true
                        } label: {
                            addHabitRow
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(AppPalette.background)
                    }

                    // Список привычек
                    Section(header: Text("Мои привычки").font(.headline).foregroundStyle(AppPalette.textSecondary)) {
                        ForEach(store.habits) { h in
                            habitRow(h)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(AppPalette.background)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        habitPendingDeletion = h
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                                // На всякий случай — если хочешь альтернативу свайпу:
                                .contextMenu {
                                    Button(role: .destructive) {
                                        habitPendingDeletion = h
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .textCase(nil) // чтобы заголовок секции не капсился
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppPalette.background)
            }
            .navigationTitle("Привычки")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toggleEditMode()
                    } label: {
                        Text(isEditing ? "Готово" : "Правка")
                    }
                }
            }
            .sheet(isPresented: $presentAdd) {
                AddEditHabitView(mode: .add)
                    .environmentObject(store)
            }
            .sheet(item: $editHabit) { h in
                AddEditHabitView(mode: .edit(h))
                    .environmentObject(store)
            }
            .alert("Удалить привычку?", isPresented: $showDeleteConfirmation, presenting: habitPendingDeletion) { habit in
                Button("Удалить", role: .destructive) {
                    store.deleteHabit(habit.id)
                    habitPendingDeletion = nil
                }
                Button("Отмена", role: .cancel) {
                    habitPendingDeletion = nil
                }
            } message: { habit in
                Text("Привычка «\(habit.name)» будет удалена из «Сегодня» и статистики.")
            }
        }
    }

    // MARK: - UI blocks

    private var addHabitRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .frame(width: 28, height: 28)
                .background(Circle().fill(AppPalette.card2))

            Text("Добавить привычку")
                .font(.headline)

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppPalette.card)
        )
    }

    @ViewBuilder
    private func habitRow(_ h: Habit) -> some View {
        HStack(spacing: 12) {
            Text(h.icon)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppPalette.card2)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(h.name)
                    .font(.headline)

                Text("7 дней трекинга • тап по дням")
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
            }

            Spacer()

            Circle()
                .fill(Color(hex: h.colorHex))
                .frame(width: 10, height: 10)
                .opacity(0.95)

            Button {
                editHabit = h
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(AppPalette.card2))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppPalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: h.colorHex).opacity(0.35), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func toggleEditMode() {
        if isEditing {
            editMode?.wrappedValue = .inactive
        } else {
            editMode?.wrappedValue = .active
        }
    }
}
