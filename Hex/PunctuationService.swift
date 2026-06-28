import Foundation

/// Вызывает локальный llama-server для очистки текста.
final class PunctuationService {
    static let shared = PunctuationService()
    private let baseURL: String

    init(baseURL: String = "http://localhost:8080/v1/chat/completions") {
        self.baseURL = baseURL
    }

    func process(_ rawText: String) async -> String {
        guard !rawText.isEmpty, rawText.count > 8 else { return rawText }

        let prompt = """
        Расставь знаки препинания. Убери слова-паразиты (э, мм, ну, типа, как бы, короче).
        Сохрани смысл и стиль. Ответ: только исправленный текст.

        Текст: \(rawText)
        Исправленный текст:
        """

        let messages: [[String: String]] = [
            ["role": "user", "content": prompt]
        ]
        let body: [String: Any] = [
            "messages": messages,
            "temperature": 0.1,
            "max_tokens": 500,
        ]

        guard let url = URL(string: baseURL),
              let httpBody = try? JSONSerialization.data(withJSONObject: body)
        else { return rawText }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        request.timeoutInterval = 15

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String
            else { return rawText }
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return rawText
        }
    }
}
