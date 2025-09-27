# Apple Foundation AI Demo

A Swift Package that showcases how to generate code and images locally on Apple silicon by combining MLX-based large language models with a Stable Diffusion XL pipeline. The executable downloads the requested models on demand, writes the generated Swift snippet to `GeneratedOutputs/generated.swift`, and saves the rendered image to `GeneratedOutputs/generated.png`.

## Requirements

- macOS 14.4 or newer (tested on macOS 15.6.1)
- Apple silicon Mac with at least 16 GB RAM recommended
- Xcode 16 (or newer) with the command-line tools installed
- Hugging Face account not required for public models; ensure outbound HTTPS is allowed for first-run downloads

> **Note** SwiftPM alone cannot build the MLX Metal shaders. Always build the package once in Xcode so the `mlx.metallib` artifacts are produced.

## Getting Started (Xcode)

1. Open `Package.swift` in Xcode (`File ▸ Open…`).
2. When prompted, trust the package and allow it to resolve dependencies.
3. Select the `AppleFoundationAIDemo` scheme with destination `My Mac`.
4. Build once (`⌘B`). The first build compiles the bundled MLX/StableDiffusion libraries and Metal kernels.
5. Run (`⌘R`). The console logs download progress for:
   - Text model `mlx-community/OpenELM-270M-Instruct`
   - Image model `stabilityai/sdxl-turbo`
6. Inspect the outputs in `GeneratedOutputs/` (created in the package directory).

### Customizing prompts or models

- Edit the constants near the top of `Sources/AppleFoundationAIDemo/AppMain.swift`.
- Alternatively, add environment variables in the scheme (`Product ▸ Scheme ▸ Edit Scheme… ▸ Run ▸ Arguments`):
  - `CODE_MODEL_ID`
  - `CODE_PROMPT`
  - `IMAGE_PROMPT`

## Command-Line Usage (after Xcode build)

Once Xcode has produced the Metal library:

```bash
swift run AppleFoundationAIDemo
```

To override prompts or models from the shell:

```bash
CODE_MODEL_ID="mlx-community/Qwen3-4B-4bit" \
CODE_PROMPT="Write a SwiftUI view that shows a timer." \
IMAGE_PROMPT="Minimalist wallpaper of a timer in soft gradients" \
swift run AppleFoundationAIDemo
```

If you prefer not to open Xcode, copy a compatible `mlx.metallib` beside the built binary. One option is to install the matching MLX Python wheel and copy `mlx/lib/mlx.metallib` into `.build/arm64-apple-macosx/debug/` prior to running `swift run`.

## Output Files

- `GeneratedOutputs/generated.swift`: Swift function produced by the language model.
- `GeneratedOutputs/generated.png`: Image rendered from Stable Diffusion XL Turbo.

Both files are overwritten on each run. Commit or rename them if you need to preserve earlier generations.

## Troubleshooting

- **`'main' attribute cannot be used…`**: Ensure `Sources/AppleFoundationAIDemo/AppMain.swift` is the only file with an `@main` entry point, then clean (`Shift-⌘-K`) and rebuild in Xcode.
- **`Failed to load the default metallib`**: Run the project from Xcode at least once to build the Metal shaders, or copy a compatible `mlx.metallib` next to `.build/arm64-apple-macosx/debug/AppleFoundationAIDemo`.
- **Slow first run**: Hugging Face downloads can be several GB. Subsequent runs reuse the cached weights under `~/Library/Application Support/com.apple.ml.compute`.

