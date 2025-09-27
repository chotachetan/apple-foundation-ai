import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import StableDiffusion

@main
struct AppleFoundationAIDemo {
    private enum DemoError: Error {
        case latentNotProduced
        case failedToCreateGenerator
    }

    static func main() async {
        do {
            let codeModelID = ProcessInfo.processInfo.environment["CODE_MODEL_ID"]
                ?? "mlx-community/OpenELM-270M-Instruct"
            let imagePreset = StableDiffusionConfiguration.Preset.sdxlTurbo

            let codePrompt = ProcessInfo.processInfo.environment["CODE_PROMPT"]
                ?? """
                Write a concise Swift function called `fibonacci` that returns the first `n` Fibonacci numbers as an array.
                Include a doc comment describing the algorithm and avoid any explanation outside of the code block.
                """
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let imagePrompt = ProcessInfo.processInfo.environment["IMAGE_PROMPT"]
                ?? "An isometric illustration of a cheerful robot pair-programming with a human at a wooden desk, cinematic lighting"

            print("📦 Loading text model: \(codeModelID)")
            let generatedCode = try await generateCode(prompt: codePrompt, modelID: codeModelID)

            let outputsURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("GeneratedOutputs", isDirectory: true)
            try FileManager.default.createDirectory(at: outputsURL, withIntermediateDirectories: true)

            let codeFileURL = outputsURL.appendingPathComponent("generated.swift")
            try generatedCode.data(using: .utf8)?.write(to: codeFileURL)

            print("\n🧠 Generated Swift code saved to \(codeFileURL.path)")
            print("\n----- BEGIN GENERATED CODE -----\n\(generatedCode)\n----- END GENERATED CODE -----\n")

            print("🎨 Preparing Stable Diffusion preset: \(imagePreset.rawValue)")
            let imageURL = outputsURL.appendingPathComponent("generated.png")
            try await generateImage(
                prompt: imagePrompt,
                preset: imagePreset,
                outputURL: imageURL)

            print("🖼️ Image generation complete: \(imageURL.path)")
        } catch {
            fputs("Error: \(error)\n", stderr)
            exit(1)
        }
    }

    private static func generateCode(prompt: String, modelID: String) async throws -> String {
        let model = try await loadModel(id: modelID) { progress in
            if progress.fractionCompleted < 1 {
                let percentage = Int(progress.fractionCompleted * 100)
                print("  downloading weights: \(percentage)%", terminator: "\r")
                fflush(stdout)
            }
        }

        print("\n  loaded model, generating code…")

        let instructions = "You are an expert Swift developer. Reply with a single Swift code block and no prose."
        let session = ChatSession(model, instructions: instructions)
        let response = try await session.respond(to: prompt)

        if let codeBlock = extractFirstCodeBlock(from: response) {
            return codeBlock
        } else {
            return response.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func extractFirstCodeBlock(from response: String) -> String? {
        guard let codeRange = response.range(of: "```swift") else {
            return nil
        }
        let afterOpening = response[codeRange.upperBound...]
        guard let closingRange = afterOpening.range(of: "```") else {
            return nil
        }
        return String(afterOpening[..<closingRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func generateImage(
        prompt: String,
        preset: StableDiffusionConfiguration.Preset,
        outputURL: URL
    ) async throws {
        let configuration = preset.configuration
        print("  ensuring weights are available for \(configuration.id)")
        try await configuration.download { progress in
            if progress.fractionCompleted < 1 {
                let percentage = Int(progress.fractionCompleted * 100)
                print("  downloading diffusion assets: \(percentage)%", terminator: "\r")
                fflush(stdout)
            }
        }
        print("\n  loading diffusion pipeline…")

        let loadConfiguration = LoadConfiguration(float16: true, quantize: false)
        guard let generator = try configuration.textToImageGenerator(configuration: loadConfiguration)
        else {
            throw DemoError.failedToCreateGenerator
        }

        generator.ensureLoaded()

        var parameters = configuration.defaultParameters()
        parameters.prompt = prompt
        parameters.imageCount = 1
        parameters.decodingBatchSize = 1

        let latents = generator.generateLatents(parameters: parameters)
        var lastXt: MLXArray?
        for xt in latents {
            eval(xt)
            lastXt = xt
        }

        guard let finalXt = lastXt else {
            throw DemoError.latentNotProduced
        }

        let decoder = generator.detachedDecoder()
        let decodedBatch = decoder(finalXt)
        eval(decodedBatch)

        let grid = makeGrid(images: [decodedBatch], rows: 1)
        eval(grid)
        try Image(grid).save(url: outputURL)
    }

    private static func makeGrid(images: [MLXArray], rows: Int) -> MLXArray {
        var x = concatenated(images, axis: 0)
        x = padded(x, widths: [[0, 0], [8, 8], [8, 8], [0, 0]])
        let (batch, height, width, channels) = x.shape4
        x = x.reshaped(rows, batch / rows, height, width, channels).transposed(0, 2, 1, 3, 4)
        x = x.reshaped(rows * height, batch / rows * width, channels)
        return (x * 255).asType(.uint8)
    }
}
