import SwiftUI

struct AddEditHabitView: View {

    enum Mode {
        case add
        case edit(Habit)
    }

    @EnvironmentObject private var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    private let mode: Mode

    @State private var name: String = ""
    @State private var icon: String = "⭐️"
    @State private var colorHex: String = "FFD60A" // жёлтый по умолчанию

    // Палитра (можешь расширять)
    private let palette: [String] = [
        "0A84FF", "34C759", "FFD60A", "FF375F", "AF52DE", "FF9F0A", "00C7BE",
        "FF453A", "BF5AF2", "30D158", "64D2FF", "FFB340", "8E8E93", "FFFFFF"
    ]

    init(mode: Mode) {
        self.mode = mode
    }

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    header

                    previewCard

                    mainSection

                    colorSection

                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
        }
        .onAppear { hydrate() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button("Закрыть") { dismiss() }
                .font(.headline)
                .foregroundStyle(.blue)

            Spacer()

            Text("Редактирование")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button("Сохранить") { save() }
                .font(.headline)
                .foregroundStyle(canSave ? .blue : .gray)
                .disabled(!canSave)
        }
        .padding(.top, 8)
    }

    // MARK: - Preview

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Предпросмотр")
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary)

            HStack(spacing: 12) {
                Text(iconDisplay)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppPalette.card2)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(nameTrimmed.isEmpty ? "Название привычки" : nameTrimmed)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Стрик: 0 • Рекорд: 0")
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                Spacer()

                Image(systemName: "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding()
        .background(cardBackground(colorHex: colorHex))
    }

    // MARK: - Sections

    private var mainSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Основное")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            VStack(spacing: 10) {

                // Иконка/эмодзи
                HStack {
                    Text("Иконка")
                        .foregroundStyle(AppPalette.textSecondary)

                    Spacer()

                    TextField("🙂", text: $icon)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .onChange(of: icon) { _, newValue in
                            icon = sanitizeEmojiInput(newValue)
                        }
                        .frame(width: 90)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppPalette.card))

                // Название
                HStack {
                    Text("Название")
                        .foregroundStyle(AppPalette.textSecondary)

                    Spacer()

                    TextField("Например: Вода 2 литра", text: $name)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(true)
                        .frame(maxWidth: 220)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppPalette.card))
            }
        }
        .padding(.top, 8)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Цвет")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Выбранный цвет подсвечивает карточку привычки.")
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                ForEach(palette, id: \.self) { hex in
                    Button {
                        colorHex = hex
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)

                            if hex == colorHex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(hex == "FFFFFF" ? .black : .white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(AppPalette.card))
        }
        .padding(.top, 8)
    }

    // MARK: - Save / Hydrate

    private func hydrate() {
        switch mode {
        case .add:
            name = ""
            icon = "⭐️"
            colorHex = "FFD60A"
        case .edit(let habit):
            name = habit.name
            icon = habit.icon
            colorHex = habit.colorHex
        }
    }

    private func save() {
        let fixedName = nameTrimmed
        let fixedIcon = iconDisplay
        let fixedColor = colorHex

        switch mode {
        case .add:
            let newHabit = Habit(id: UUID(), name: fixedName, icon: fixedIcon, colorHex: fixedColor)
            store.habits.append(newHabit)

        case .edit(let habit):
            let updated = Habit(id: habit.id, name: fixedName, icon: fixedIcon, colorHex: fixedColor)
            if let idx = store.habits.firstIndex(where: { $0.id == habit.id }) {
                store.habits[idx] = updated
            }
        }

        dismiss()
    }

    private var canSave: Bool {
        !nameTrimmed.isEmpty
    }

    // MARK: - Helpers UI

    private var nameTrimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var iconDisplay: String {
        let cleaned = sanitizeEmojiInput(icon)
        return cleaned.isEmpty ? "⭐️" : cleaned
    }

    private func sanitizeEmojiInput(_ s: String) -> String {
        // Очень мягкий санитайз: оставляем максимум 2 "скаляра"
        // (чтобы одно эмодзи/составное не разорвало UI)
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }

        // Берём первые 2 Character (чтобы emoji вроде "👨‍👩‍👧‍👦" не разнесло поле)
        var out = ""
        var count = 0
        for ch in trimmed {
            out.append(ch)
            count += 1
            if count >= 2 { break }
        }
        return out
    }

    private func cardBackground(colorHex: String) -> some View {
        let c = Color(hex: colorHex)
        return RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(AppPalette.card)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(c.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(c.opacity(0.55), lineWidth: 1)
            )
    }
}

