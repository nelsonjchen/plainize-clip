import Foundation

struct ArgumentParser {
    let options: Set<String>
    let arguments: [String]

    init(arguments rawArguments: [String], recognizedOptions: String) {
        let recognized = Set(recognizedOptions.map { String($0) })
        var parsedOptions = Set<String>()
        var parsedArguments: [String] = []

        for argument in rawArguments.dropFirst() {
            if argument.hasPrefix("-") {
                let key = String(argument.dropFirst())
                if key.count == 1, recognized.contains(key) {
                    parsedOptions.insert(key)
                    continue
                }
            }
            parsedArguments.append(argument)
        }

        options = parsedOptions
        arguments = parsedArguments
    }

    func hasOption(_ option: String) -> Bool {
        options.contains(option)
    }
}
