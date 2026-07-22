/// Tracks whether an import fully completed the pipeline described in the
/// plan: copy -> encrypt -> verify hash -> persist metadata. A row left in
/// [importing] after an unexpected shutdown is not resumed — it is treated
/// as failed and cleaned up by the recovery use case on next launch.
enum ImportStatus { importing, completed }
